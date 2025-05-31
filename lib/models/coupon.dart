import 'package:cloud_firestore/cloud_firestore.dart';

class Coupon {
  final String id; // Firestore document ID (usually the coupon code itself)
  final String code; // The coupon code string
  final String description;
  final String discountType; // 'percentage', 'fixed_amount'
  final double discountValue;
  final double? minimumSpend; // Optional minimum order value to apply coupon
  final Timestamp expiryDate;
  final int? usageLimit; // Optional total usage limit for the coupon
  final int currentUsage; // How many times the coupon has been used
  final bool isActive;
  final Timestamp createdAt;

  Coupon({
    required this.id,
    required this.code,
    required this.description,
    required this.discountType,
    required this.discountValue,
    this.minimumSpend,
    required this.expiryDate,
    this.usageLimit,
    required this.currentUsage,
    required this.isActive,
    required this.createdAt,
  });

  // Factory constructor from Firestore document
  factory Coupon.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Coupon(
      id: doc.id,
      code: data['code'] ?? '',
      description: data['description'] ?? '',
      discountType: data['discountType'] ?? 'fixed_amount',
      discountValue: (data['discountValue'] ?? 0.0).toDouble(),
      minimumSpend: (data['minimumSpend'] as num?)?.toDouble(),
      expiryDate: data['expiryDate'] ?? Timestamp.now(),
      usageLimit: data['usageLimit'],
      currentUsage: data['currentUsage'] ?? 0,
      isActive: data['isActive'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'code': code,
      'description': description,
      'discountType': discountType,
      'discountValue': discountValue,
      'minimumSpend': minimumSpend,
      'expiryDate': expiryDate,
      'usageLimit': usageLimit,
      'currentUsage': currentUsage,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }

  // Helper method to check if coupon is valid (active, not expired, usage limit not reached)
  bool get isValid {
    final now = Timestamp.now();
    bool notExpired = expiryDate.compareTo(now) > 0;
    bool usageOk = usageLimit == null || currentUsage < usageLimit!;
    return isActive && notExpired && usageOk;
  }

  // Helper method to calculate discount amount for a given total
  double calculateDiscount(double orderTotal) {
    if (!isValid) return 0.0;
    if (minimumSpend != null && orderTotal < minimumSpend!) return 0.0;

    if (discountType == 'percentage') {
      return (orderTotal * discountValue / 100.0);
    } else if (discountType == 'fixed_amount') {
      // Ensure fixed amount doesn't exceed order total
      return (discountValue > orderTotal) ? orderTotal : discountValue;
    }
    return 0.0;
  }
}

