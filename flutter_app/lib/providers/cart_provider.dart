import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product.dart';
import '../data/products.dart';

class CartProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;
  String _currentUser = 'guest';

  CartProvider() {
    _loadState();
  }

  void loadUserCart(String username) {
    _currentUser = username;
    _cartItems.clear();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Auto-detect logged in user on boot
    if (_currentUser == 'guest') {
      final storedCurrentUser = prefs.getString('fruitshop_current_user');
      if (storedCurrentUser != null) {
        try {
          final userMap = json.decode(storedCurrentUser);
          if (userMap['username'] != null) {
            _currentUser = userMap['username'];
          }
        } catch (_) {}
      }
    }

    final savedCart = prefs.getString('fruitCart_$_currentUser');
    if (savedCart != null) {
      List<dynamic> jsonList = json.decode(savedCart);
      _cartItems = jsonList.map((item) {
        // Find product by id from mockProducts
        final product = mockProducts.firstWhere((p) => p.id == item['productId']);
        return CartItem(
          product: product,
          quantity: item['quantity'],
        );
      }).toList();
      notifyListeners();
    }
    
    // If authenticated, perform async pull from backend
    if (_currentUser != 'guest') {
      try {
        final docSn = await _firestore.collection('users').doc(_currentUser).get();
        if (docSn.exists && docSn.data()!.containsKey('cart')) {
          List<dynamic> fbList = docSn.get('cart');
          _cartItems = fbList.map((item) {
            final product = mockProducts.firstWhere((p) => p.id == item['productId']);
            return CartItem(product: product, quantity: item['quantity']);
          }).toList();
          
          // Sync down backend fetch to local memory
          final jsonList = _cartItems.map((item) => {
            'productId': item.product.id,
            'quantity': item.quantity,
          }).toList();
          await prefs.setString('fruitCart_$_currentUser', json.encode(jsonList));
          notifyListeners();
        }
      } catch (e) {
        if (kDebugMode) print('Firebase Load Cart Error: $e');
      }
    }
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _cartItems.map((item) => {
      'productId': item.product.id,
      'quantity': item.quantity,
    }).toList();
    await prefs.setString('fruitCart_$_currentUser', json.encode(jsonList));
    
    if (_currentUser != 'guest') {
      try {
         await _firestore.collection('users').doc(_currentUser).update({
            'cart': jsonList
         });
      } catch (e) {
         if (kDebugMode) print('Firebase Save Cart Error: $e');
      }
    }
  }

  void addToCart(Product product, [int quantity = 1]) {
    final index = _cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      _cartItems[index].quantity += quantity;
    } else {
      _cartItems.add(CartItem(product: product, quantity: quantity));
    }
    _saveState();
    notifyListeners();
  }

  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id == productId);
    _saveState();
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    final index = _cartItems.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _cartItems[index].quantity = quantity;
      _saveState();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _saveState();
    notifyListeners();
  }

  double getCartTotal() {
    return _cartItems.fold(0, (total, item) => total + (item.product.price * item.quantity));
  }

  int getCartItemsCount() {
    return _cartItems.fold(0, (count, item) => count + item.quantity);
  }
}
