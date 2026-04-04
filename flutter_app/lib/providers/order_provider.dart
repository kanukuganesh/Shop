import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/order.dart';

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Create an order
  Future<void> createOrder(OrderModel order) async {
    try {
      await _firestore.collection('orders').doc(order.id).set(order.toJson());
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print("Error creating order: $e");
      }
      rethrow;
    }
  }

  // Update order status (For Admins & Users)
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating status: $e");
      }
      rethrow;
    }
  }

  // Update payment status (For Manual Verification Flow)
  Future<void> updatePaymentDetails(String orderId, String method, String status, String? transactionId) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'paymentMethod': method,
        'paymentStatus': status,
        'transactionId': transactionId,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating payment: $e");
      }
      rethrow;
    }
  }

  // Update order delivery address (For Users in 'processing' state)
  Future<void> updateOrderAddress(String orderId, Map<String, dynamic> newAddressJson) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'deliveryAddress': newAddressJson,
        'lastModified': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error updating address: $e");
      }
      rethrow;
    }
  }

  // Stream for Admin Dashboard (All orders ordered by date descending)
  Stream<List<OrderModel>> adminOrdersStream() {
    return _firestore
        .collection('orders')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromJson(doc.data())).toList();
    });
  }

  // Stream for User Profile (Current User Orders)
  Stream<List<OrderModel>> userOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => OrderModel.fromJson(doc.data())).toList();
    });
  }
}
