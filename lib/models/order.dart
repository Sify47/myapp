import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart'; // Re-use CartItem structure for order items

class OrderItem extends CartItem {
  // OrderItem might have additional fields specific to an order context,
  // like final price paid, status within the order, etc.
  // For now, it inherits directly from CartItem.

  OrderItem({
    required super.productId,
    required super.productName,
    super.productImageUrl,
    required super.quantity,
    required super.price, // Price at the time of order
    super.discountPrice,
    super.selectedAttributes,
    super.variantSku,
  });

  // Factory constructor from Firestore map (adjust if OrderItem has different fields)
  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      productImageUrl: data['productImageUrl'],
      quantity: data['quantity'] ?? 0,
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      selectedAttributes: data['selectedAttributes'] != null ? Map<String, dynamic>.from(data['selectedAttributes']) : null,
      variantSku: data['variantSku'],
    );
  }

  // Method to convert to Firestore map (adjust if OrderItem has different fields)
  @override
  Map<String, dynamic> toMap() {
    // Add any OrderItem-specific fields here if needed
    return super.toMap();
  }
}

class Order {
  final String id; // Firestore document ID
  final String userId;
  final List<OrderItem> items;
  final double totalAmount; // Sum of item prices * quantity (before discount)
  final double shippingCost;
  final String? appliedCouponCode; // New field
  final double discountAmount; // New field (amount discounted by coupon)
  final double grandTotal; // totalAmount + shippingCost - discountAmount
  final String orderStatus; // e.g., 'pending', 'processing', 'shipped', 'delivered', 'cancelled'
  final String paymentMethod; // e.g., 'cod', 'stripe', 'paypal'
  final String paymentStatus; // e.g., 'pending', 'paid', 'failed'
  final Map<String, dynamic> shippingAddress; // Structure for address details
  final String? trackingNumber;
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Order({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalAmount,
    required this.shippingCost,
    this.appliedCouponCode,
    required this.discountAmount,
    required this.grandTotal,
    required this.orderStatus,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.shippingAddress,
    this.trackingNumber,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor from Firestore document
  factory Order.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Order(
      id: doc.id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((itemData) => OrderItem.fromMap(itemData as Map<String, dynamic>))
          .toList(),
      totalAmount: (data['totalAmount'] ?? 0.0).toDouble(),
      shippingCost: (data['shippingCost'] ?? 0.0).toDouble(),
      appliedCouponCode: data['appliedCouponCode'], // New field
      discountAmount: (data['discountAmount'] ?? 0.0).toDouble(), // New field
      grandTotal: (data['grandTotal'] ?? 0.0).toDouble(),
      orderStatus: data['orderStatus'] ?? 'pending',
      paymentMethod: data['paymentMethod'] ?? '',
      paymentStatus: data['paymentStatus'] ?? 'pending',
      shippingAddress: Map<String, dynamic>.from(data['shippingAddress'] ?? {}),
      trackingNumber: data['trackingNumber'],
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'shippingCost': shippingCost,
      'appliedCouponCode': appliedCouponCode, // New field
      'discountAmount': discountAmount, // New field
      'grandTotal': grandTotal,
      'orderStatus': orderStatus,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'shippingAddress': shippingAddress,
      'trackingNumber': trackingNumber,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}

