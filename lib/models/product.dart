import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final double price;
  final double? discountPrice; // Optional discount price
  final List<String> categories;
  final Map<String, dynamic> attributes; // e.g., {'color': 'Red', 'size': 'M'}
  final List<Map<String, dynamic>> variants; // e.g., [{'sku': 'SKU1', 'stock': 10, 'attributes': {'color': 'Red'}}, ...]
  final String sku; // Default SKU or for simple products
  final int stock; // Stock quantity for simple products or overall
  final String stockStatus; // e.g., 'in_stock', 'out_of_stock', 'low_stock'
  final Map<String, dynamic>? shippingInfo; // e.g., {'weight': 1.5, 'dimensions': {'l': 10, 'w': 5, 'h': 2}}
  final String brandId; // Reference to Brand document ID
  final String productStatus; // e.g., 'active', 'inactive', 'draft'
  final Timestamp createdAt;
  final Timestamp updatedAt;
  // New fields added based on user request
  final bool isFreeShipping;
  final bool isFeatured;
  final bool isNew;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    this.discountPrice,
    required this.categories,
    required this.attributes,
    required this.variants,
    required this.sku,
    required this.stock,
    required this.stockStatus,
    this.shippingInfo,
    required this.brandId,
    required this.productStatus,
    required this.createdAt,
    required this.updatedAt,
    // Initialize new fields, default to false
    this.isFreeShipping = false,
    this.isFeatured = false,
    this.isNew = false,
  });

  // Factory constructor to create a Product from a Firestore document
  factory Product.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      images: List<String>.from(data['images'] ?? []),
      price: (data['price'] ?? 0.0).toDouble(),
      discountPrice: (data['discountPrice'] as num?)?.toDouble(),
      categories: List<String>.from(data['categories'] ?? []),
      attributes: Map<String, dynamic>.from(data['attributes'] ?? {}),
      variants: List<Map<String, dynamic>>.from(data['variants'] ?? []),
      sku: data['sku'] ?? '',
      stock: data['stock'] ?? 0,
      stockStatus: data['stockStatus'] ?? 'out_of_stock',
      shippingInfo: data['shippingInfo'] != null ? Map<String, dynamic>.from(data['shippingInfo']) : null,
      brandId: data['brandId'] ?? '',
      productStatus: data['productStatus'] ?? 'inactive',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
      // Read new fields from Firestore, default to false if not present
      isFreeShipping: data['isFreeShipping'] ?? false,
      isFeatured: data['isFeatured'] ?? false,
      isNew: data['isNew'] ?? false,
    );
  }

  // Method to convert a Product instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'discountPrice': discountPrice,
      'categories': categories,
      'attributes': attributes,
      'variants': variants,
      'sku': sku,
      'stock': stock,
      'stockStatus': stockStatus,
      'shippingInfo': shippingInfo,
      'brandId': brandId,
      'productStatus': productStatus,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      // Add new fields to the map
      'isFreeShipping': isFreeShipping,
      'isFeatured': isFeatured,
      'isNew': isNew,
    };
  }
}

