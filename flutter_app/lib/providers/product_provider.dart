import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';
import '../data/products.dart';

class ProductProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;
  StreamSubscription? _firestoreSubscription;

  List<Product> get products => _products;
  bool get isLoading => _isLoading;

  bool get _isFirebaseActive => Firebase.apps.isNotEmpty;

  ProductProvider() {
    _initProducts();
  }

  @override
  void dispose() {
    _firestoreSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initProducts() async {
    if (_isFirebaseActive) {
      debugPrint('Firebase Active: Listening to Firestore products collection');
      _firestoreSubscription = FirebaseFirestore.instance
          .collection('products')
          .snapshots()
          .listen((snapshot) {
        _products = snapshot.docs.map((doc) {
          final data = doc.data();
          data['id'] = doc.id; // Map document ID into model ID
          return Product.fromJson(data);
        }).toList();

        // If firestore is completely empty (first run), migrate mock data to it
        if (_products.isEmpty && snapshot.docs.isEmpty) {
          _seedFirebaseWithMockData();
        } else {
          _isLoading = false;
          notifyListeners();
        }
      }, onError: (error) {
        debugPrint('Firestore listen error: $error. Falling back to SharedPreferences.');
        _initLocalProducts();
      });
    } else {
      debugPrint('Firebase Inactive: Initializing SharedPreferences products');
      await _initLocalProducts();
    }
  }

  Future<void> _seedFirebaseWithMockData() async {
    final batch = FirebaseFirestore.instance.batch();
    for (var prod in mockProducts) {
      final docRef = FirebaseFirestore.instance.collection('products').doc();
      final prodData = prod.copyWith(id: docRef.id, quantity: 100).toJson();
      batch.set(docRef, prodData);
    }
    await batch.commit();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _initLocalProducts() async {
    final prefs = await SharedPreferences.getInstance();
    final String? productsJson = prefs.getString('inventory_products');

    if (productsJson != null) {
      final List<dynamic> decoded = json.decode(productsJson);
      _products = decoded.map((p) => Product.fromJson(p)).toList();
    } else {
      _products = List.from(mockProducts);
      _products = _products.map((p) => p.copyWith(quantity: 100)).toList();
      await _saveLocalProducts();
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _saveLocalProducts() async {
    if (_isFirebaseActive) return; // Never save to local if Firebase is active
    final prefs = await SharedPreferences.getInstance();
    final String encoded = json.encode(_products.map((p) => p.toJson()).toList());
    await prefs.setString('inventory_products', encoded);
  }

  Future<void> addProduct(Product newProduct) async {
    if (_isFirebaseActive) {
      final jsonProduct = newProduct.toJson();
      jsonProduct.remove('id'); // Firestore gives id implicitly via document ID
      await FirebaseFirestore.instance.collection('products').add(jsonProduct);
      // Let stream listener update local _products state
    } else {
      _products.add(newProduct);
      await _saveLocalProducts();
      notifyListeners();
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    if (_isFirebaseActive) {
      final jsonProduct = updatedProduct.toJson();
      jsonProduct.remove('id');
      await FirebaseFirestore.instance.collection('products').doc(updatedProduct.id).update(jsonProduct);
    } else {
      final index = _products.indexWhere((p) => p.id == updatedProduct.id);
      if (index != -1) {
        _products[index] = updatedProduct;
        await _saveLocalProducts();
        notifyListeners();
      }
    }
  }

  Future<void> toggleProductStock(String productId) async {
    if (_isFirebaseActive) {
      final product = _products.firstWhere((p) => p.id == productId);
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'inStock': !product.inStock,
      });
    } else {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final oldProduct = _products[index];
        _products[index] = oldProduct.copyWith(inStock: !oldProduct.inStock);
        await _saveLocalProducts();
        notifyListeners();
      }
    }
  }

  Future<void> updateProductPrice(String productId, double newPrice) async {
    if (_isFirebaseActive) {
      await FirebaseFirestore.instance.collection('products').doc(productId).update({
        'price': newPrice,
      });
    } else {
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        _products[index] = _products[index].copyWith(price: newPrice);
        await _saveLocalProducts();
        notifyListeners();
      }
    }
  }

  Future<void> deleteProduct(String productId) async {
    if (_isFirebaseActive) {
      await FirebaseFirestore.instance.collection('products').doc(productId).delete();
    } else {
      _products.removeWhere((p) => p.id == productId);
      await _saveLocalProducts();
      notifyListeners();
    }
  }
}
