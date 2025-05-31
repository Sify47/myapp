import 'package:cloud_firestore/cloud_firestore.dart';

class CartItem {
  final String productId;
  final String productName; // Store name for easier display
  final String? productImageUrl; // Store main image URL
  final int quantity;
  final double price; // Price at the time of adding to cart
  final double? discountPrice; // Discount price at the time of adding
  final Map<String, dynamic>? selectedAttributes; // e.g., {'color': 'Red', 'size': 'M'}
  final String? variantSku; // SKU of the selected variant, if applicable

  CartItem({
    required this.productId,
    required this.productName,
    this.productImageUrl,
    required this.quantity,
    required this.price,
    this.discountPrice,
    this.selectedAttributes,
    this.variantSku,
  });

  // Factory constructor from Firestore map
  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
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

  // Method to convert to Firestore map
  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'productImageUrl': productImageUrl,
      'quantity': quantity,
      'price': price,
      'discountPrice': discountPrice,
      'selectedAttributes': selectedAttributes,
      'variantSku': variantSku,
    };
  }

  // Calculate the total price for this item
  double get totalPrice {
    final effectivePrice = discountPrice ?? price;
    return effectivePrice * quantity;
  }
}

// Note: The Cart itself might not need a separate model file.
// It's often represented as a subcollection ('cartItems') under the user's document.
// Or, if needed, a Cart model could hold metadata like userId, lastUpdated.

class Cart {
  final String userId;
  final List<CartItem> items;
  final Timestamp lastUpdated;

  Cart({required this.userId, required this.items, required this.lastUpdated});

  // Method to calculate total cart value
  double get totalCartValue {
    return items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Cart is typically managed directly via Firestore queries on the subcollection,
  // so fromFirestore/toFirestore might be less common for the Cart object itself.
}

