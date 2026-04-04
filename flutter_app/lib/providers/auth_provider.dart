import 'dart:convert';
import 'dart:async';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/user.dart';
import '../models/address.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? _currentUser;

  User? get currentUser => _currentUser;
  bool get isAdmin => _currentUser?.isAdmin ?? false;

  String _hashPassword(String password) {
    return sha256.convert(utf8.encode(password)).toString();
  }

  AuthProvider() {
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    final storedCurrentUser = prefs.getString('fruitshop_current_user');
    
    // Read local registry
    final String? localUsersStr = prefs.getString('fruitshop_users_registry');
    Map<String, dynamic> localUsers = {};
    if (localUsersStr != null) {
      localUsers = json.decode(localUsersStr);
    }
    
    // Always enforce Admin credentials on boot (preserves addresses)
    final existingAddresses = localUsers['ganesh']?['addresses'] ?? [];
    localUsers['ganesh'] = {
      'username': 'Ganesh',
      'password': _hashPassword('Ganesh@143'),
      'passwordHint': 'Ganesh and ur email password',
      'usernameHint': 'Shop owner name',
      'isAdmin': true,
      'addresses': existingAddresses,
    };
    await prefs.setString('fruitshop_users_registry', json.encode(localUsers));

    // Seed Admin to Firebase (Fire & Forget, might fail if rules blocked)
    try {
       final adminCheck = await _firestore.collection('users').doc('ganesh').get();
       if (!adminCheck.exists) {
         // Create safe Firebase-friendly map handling Timestamp carefully
         final firebaseMap = Map<String, dynamic>.from(localUsers['ganesh']);
         firebaseMap['createdAt'] = FieldValue.serverTimestamp();
         await _firestore.collection('users').doc('ganesh').set(firebaseMap);
       }
    } catch (_) {}

    if (storedCurrentUser != null) {
      try {
        _currentUser = User.fromJson(json.decode(storedCurrentUser));
        notifyListeners();
      } catch (e) {
        if (kDebugMode) print('Failed to load local user: $e');
      }
    }
  }

  Future<bool> login(String username, String password) async {
    final usernameLower = username.toLowerCase();
    final hashedPassword = _hashPassword(password);
    
    // First try Firebase
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameLower)
          .where('password', isEqualTo: hashedPassword)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        final userData = querySnapshot.docs.first.data();
        await _applyLogin(userData, password);
        return true;
      }
    } catch (e) {
      if (kDebugMode) print('Firebase Login Error, resorting to local fallback: $e');
    }

    // Fallback: Check local registry
    final prefs = await SharedPreferences.getInstance();
    final String? localUsersStr = prefs.getString('fruitshop_users_registry');
    if (localUsersStr != null) {
      final Map<String, dynamic> localUsers = json.decode(localUsersStr);
      if (localUsers.containsKey(usernameLower)) {
        final userData = localUsers[usernameLower];
        if (userData['password'] == hashedPassword) {
           await _applyLogin(userData, password);
           return true;
        }
      }
    }
    return false;
  }

  Future<void> _applyLogin(Map<String, dynamic> userData, [String? password]) async {
    _currentUser = User(
      username: userData['username'],
      fullName: userData['fullName'],
      email: userData['email'],
      phoneNumber: userData['phoneNumber'],
      profilePictureUrl: userData['profilePictureUrl'],
      password: password ?? userData['password_plain'], // Use provided or fallback
      passwordHint: userData['passwordHint'] ?? '',
      usernameHint: userData['usernameHint'] ?? '',
      isAdmin: userData['isAdmin'] ?? false,
      memberSince: userData['memberSince'] != null 
          ? (userData['memberSince'] is Timestamp 
              ? (userData['memberSince'] as Timestamp).toDate() 
              : DateTime.parse(userData['memberSince'])) 
          : null,
      addresses: userData['addresses'] != null
          ? List<Address>.from((userData['addresses'] as List).map((x) => Address.fromJson(x)))
          : [],
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('fruitshop_current_user', json.encode(_currentUser!.toJson()));
    notifyListeners();
  }

  Future<bool> signup(String username, String password, String usernameHint, String passwordHint) async {
    final usernameLower = username.toLowerCase();
    
    // Read local registry to check existence quickly
    final prefs = await SharedPreferences.getInstance();
    final String? localUsersStr = prefs.getString('fruitshop_users_registry');
    Map<String, dynamic> localUsers = {};
    if (localUsersStr != null) {
      localUsers = json.decode(localUsersStr);
    }
    
    if (localUsers.containsKey(usernameLower)) return false; // Exists locally
    
    // Try Firebase exists check
    try {
      final checkUser = await _firestore
          .collection('users')
          .where('username', isEqualTo: usernameLower)
          .get()
          .timeout(const Duration(seconds: 10));

      if (checkUser.docs.isNotEmpty) {
        return false; // Exists on Firebase
      }
    } catch (e) {
      if (kDebugMode) print('Firebase Signup Check Error/Timeout: $e');
    }

    final hashedPassword = _hashPassword(password);
    final now = DateTime.now();

    final newUserMap = {
      'username': usernameLower,
      'fullName': username, // Default to username
      'password': hashedPassword,
      'usernameHint': usernameHint,
      'passwordHint': passwordHint,
      'isAdmin': false,
      'memberSince': now.toIso8601String(),
      'addresses': [],
    };

    // Save locally
    localUsers[usernameLower] = newUserMap;
    await prefs.setString('fruitshop_users_registry', json.encode(localUsers));

    // Fire and forget to Firebase with timeout
    try {
       final firebaseMap = Map<String, dynamic>.from(newUserMap);
       firebaseMap['memberSince'] = FieldValue.serverTimestamp();
       firebaseMap['createdAt'] = FieldValue.serverTimestamp();
       await _firestore
           .collection('users')
           .doc(usernameLower)
           .set(firebaseMap)
           .timeout(const Duration(seconds: 10));
    } catch (e) {
       if (kDebugMode) print('Firebase Cloud Sync Error/Timeout: $e');
    }

    await _applyLogin(newUserMap, password);
    return true;
  }

  Future<void> logout() async {
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('fruitshop_current_user');
    notifyListeners();
  }

  Future<void> addAddress(Address address) async {
    if (_currentUser == null) return;
    
    final isFirst = _currentUser!.addresses.isEmpty;
    final newAddress = address.copyWith(isDefault: address.isDefault || isFirst);

    List<Address> updatedAddresses = List.from(_currentUser!.addresses);
    
    if (newAddress.isDefault) {
      updatedAddresses = updatedAddresses.map((a) => a.copyWith(isDefault: false)).toList();
    }
    updatedAddresses.add(newAddress);
    
    _currentUser = User(
      username: _currentUser!.username,
      passwordHint: _currentUser!.passwordHint,
      usernameHint: _currentUser!.usernameHint,
      isAdmin: _currentUser!.isAdmin,
      addresses: updatedAddresses,
    );

    await _syncUserToStorage();
  }

  Future<void> setDefaultAddress(String addressId) async {
    if (_currentUser == null) return;

    List<Address> updatedAddresses = _currentUser!.addresses.map((a) {
      return a.copyWith(isDefault: a.id == addressId);
    }).toList();

    _currentUser = User(
      username: _currentUser!.username,
      passwordHint: _currentUser!.passwordHint,
      usernameHint: _currentUser!.usernameHint,
      isAdmin: _currentUser!.isAdmin,
      addresses: updatedAddresses,
    );

    await _syncUserToStorage();
  }

  Future<void> _syncUserToStorage() async {
    if (_currentUser == null) return;

    try {
      // Sync local session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('fruitshop_current_user', json.encode(_currentUser!.toJson()));
      
      // Sync local registry
      final String? localUsersStr = prefs.getString('fruitshop_users_registry');
      if (localUsersStr != null) {
         final Map<String, dynamic> localUsers = json.decode(localUsersStr);
         if (localUsers.containsKey(_currentUser!.username)) {
            localUsers[_currentUser!.username]['addresses'] = _currentUser!.addresses.map((a) => a.toJson()).toList();
            await prefs.setString('fruitshop_users_registry', json.encode(localUsers));
         }
      }

      // Push to Firebase Native Database
      await _firestore
          .collection('users')
          .doc(_currentUser!.username)
          .update({
             'addresses': _currentUser!.addresses.map((a) => a.toJson()).toList()
          });
          
      notifyListeners();
    } catch (e) {
      if (kDebugMode) print('Firebase Sync Error: $e');
    }
  }

  Future<String?> getUserHint(String username) async {
    final usernameLower = username.toLowerCase();
    
    // Local first
    final prefs = await SharedPreferences.getInstance();
    final String? localUsersStr = prefs.getString('fruitshop_users_registry');
    if (localUsersStr != null) {
       final Map<String, dynamic> localUsers = json.decode(localUsersStr);
       if (localUsers.containsKey(usernameLower)) {
          final data = localUsers[usernameLower];
          return 'Username Hint: ${data['usernameHint']}\nPassword Hint: ${data['passwordHint']}';
       }
    }

    try {
      final docInfo = await _firestore.collection('users').doc(usernameLower).get();
      if (docInfo.exists) {
        final data = docInfo.data()!;
        return 'Username Hint: ${data['usernameHint']}\nPassword Hint: ${data['passwordHint']}';
      }
    } catch (e) {
      if (kDebugMode) print('Error looking up hints: $e');
    }
    return null;
  }

  Future<bool> changePassword(String newPassword) async {
    if (_currentUser == null) return false;

    try {
      final hashedPassword = _hashPassword(newPassword);
      final username = _currentUser!.username.toLowerCase();

      // Update Local Registry
      final prefs = await SharedPreferences.getInstance();
      final String? localUsersStr = prefs.getString('fruitshop_users_registry');
      if (localUsersStr != null) {
        final Map<String, dynamic> localUsers = json.decode(localUsersStr);
        if (localUsers.containsKey(username)) {
          localUsers[username]['password'] = hashedPassword;
          await prefs.setString('fruitshop_users_registry', json.encode(localUsers));
        }
      }

      // Update Firebase
      await _firestore.collection('users').doc(username).update({
        'password': hashedPassword,
      });

      // Update Current Session
      _currentUser = User(
        username: _currentUser!.username,
        password: newPassword, // Store the new plain text for display
        passwordHint: _currentUser!.passwordHint,
        usernameHint: _currentUser!.usernameHint,
        isAdmin: _currentUser!.isAdmin,
        addresses: _currentUser!.addresses,
      );
      
      await prefs.setString('fruitshop_current_user', json.encode(_currentUser!.toJson()));
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Update Password Error: $e');
      return false;
    }
  }

  Future<bool> deleteAllUsersExceptAdmin() async {
    try {
      // 1. Firebase Cleanup
      final snapshot = await _firestore.collection('users').get();
      final batch = _firestore.batch();
      
      for (var doc in snapshot.docs) {
        if (doc.id.toLowerCase() != 'ganesh') {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();

      // 2. Local Registry Cleanup
      final prefs = await SharedPreferences.getInstance();
      final String? localUsersStr = prefs.getString('fruitshop_users_registry');
      if (localUsersStr != null) {
        final Map<String, dynamic> localUsers = json.decode(localUsersStr);
        final adminData = localUsers['ganesh'];
        
        // Reset the registry to only contain the admin
        final Map<String, dynamic> newRegistry = {};
        if (adminData != null) {
          newRegistry['ganesh'] = adminData;
        }
        await prefs.setString('fruitshop_users_registry', json.encode(newRegistry));
      }

      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) print('Delete All Users Error: $e');
      return false;
    }
  }
}
