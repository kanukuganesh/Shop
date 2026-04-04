import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsProvider with ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  String _appName = 'Nagaraju Fruits Shop';
  String? _appIconUrl;
  bool _isLoading = true;

  String get appName => _appName;
  String? get appIconUrl => _appIconUrl;
  bool get isLoading => _isLoading;

  SettingsProvider() {
    _initBrandingListener();
  }

  void _initBrandingListener() {
    _firestore.collection('settings').doc('branding').snapshots().listen((doc) {
      if (doc.exists) {
        final data = doc.data()!;
        _appName = data['appName'] ?? 'Nagaraju Fruits Shop';
        _appIconUrl = data['appIconUrl'];
      }
      _isLoading = false;
      notifyListeners();
    });
  }

  Future<void> updateBranding({required String name, String? iconUrl}) async {
    try {
      await _firestore.collection('settings').doc('branding').set({
        'appName': name,
        'appIconUrl': iconUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error updating branding: $e');
      rethrow;
    }
  }
}
