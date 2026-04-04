import 'package:cloud_firestore/cloud_firestore.dart';
import 'address.dart';

class OrderItem {
  final String productId;
  final String name;
  final double price;
  final int quantity;
  final String unit;

  const OrderItem({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
    required this.unit,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'],
      name: json['name'],
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'unit': unit,
    };
  }
}

class OrderModel {
  final String id;
  final String userId; // Usually the customerMobile/username from AuthProvider
  final String customerName;
  final String customerMobile;
  final DateTime date;
  final String status; // 'processing', 'delivered', 'cancelled'
  final double totalAmount;
  final List<OrderItem> items;
  final Address deliveryAddress;
  final String paymentMethod;
  final String paymentStatus; // 'Pending', 'Awaiting Verification', 'Paid', 'Failed'
  final String? transactionId;
  final DateTime lastModified;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.customerMobile,
    required this.date,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.deliveryAddress,
    required this.paymentMethod,
    this.paymentStatus = 'Pending',
    this.transactionId,
    required this.lastModified,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['id'],
      userId: json['userId'] ?? json['customerMobile'],
      customerName: json['customerName'],
      customerMobile: json['customerMobile'],
      date: (json['date'] as Timestamp).toDate(),
      status: json['status'],
      totalAmount: (json['totalAmount'] as num).toDouble(),
      items: (json['items'] as List).map((i) => OrderItem.fromJson(i)).toList(),
      deliveryAddress: Address.fromJson(json['deliveryAddress']),
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'] ?? 'Pending',
      transactionId: json['transactionId'],
      lastModified: (json['lastModified'] as Timestamp?)?.toDate() ?? (json['date'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'date': Timestamp.fromDate(date),
      'status': status,
      'totalAmount': totalAmount,
      'items': items.map((i) => i.toJson()).toList(),
      'deliveryAddress': deliveryAddress.toJson(),
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'transactionId': transactionId,
      'lastModified': Timestamp.fromDate(lastModified),
    };
  }

  OrderModel copyWith({
    String? id,
    String? userId,
    String? customerName,
    String? customerMobile,
    DateTime? date,
    String? status,
    double? totalAmount,
    List<OrderItem>? items,
    Address? deliveryAddress,
    String? paymentMethod,
    String? paymentStatus,
    String? transactionId,
    DateTime? lastModified,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      customerName: customerName ?? this.customerName,
      customerMobile: customerMobile ?? this.customerMobile,
      date: date ?? this.date,
      status: status ?? this.status,
      totalAmount: totalAmount ?? this.totalAmount,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      transactionId: transactionId ?? this.transactionId,
      lastModified: lastModified ?? this.lastModified,
    );
  }
}
