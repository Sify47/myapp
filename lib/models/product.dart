import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String name;
  final String description;
  final List<String> images;
  final double price;
  final double? discountPrice;
  final List<String> categories;
  final List<Map<String, dynamic>> attributes;
  // final List<Map<String, dynamic>> variants;
  final String sku;
  final int stock;
  final String stockStatus;
  final Map<String, dynamic>? shippingInfo;
  final String brandId;
  final String productStatus;
  final List<String> tags; // ✅ تم تصحيحه من String إلى List<String>
  final Timestamp createdAt;
  final Timestamp updatedAt;

  final bool isFreeShipping;
  final bool isFeatured;
  final bool isNew;
  int averageRating;
  int soldcount;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.images,
    required this.price,
    this.discountPrice,
    required this.categories,
    required this.attributes,
    // required this.variants,
    required this.sku,
    required this.stock,
    required this.stockStatus,
    this.shippingInfo,
    required this.tags,
    required this.brandId,
    required this.productStatus,
    required this.createdAt,
    required this.updatedAt,
    this.isFreeShipping = false,
    this.isFeatured = false,
    this.isNew = false,
    this.soldcount = 0,
    this.averageRating = 0,
  });

  factory Product.fromFirestore(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>? ?? {};

      // تحويل كل حقل مع التعامل مع القيم null والأنواع غير المتوقعة
      return Product(
        id: doc.id,
        name: (data['name'] as String?) ?? 'بدون اسم',
        description: (data['description'] as String?) ?? '',
        images: _parseList<String>(data['images']),
        price: (data['price'] ?? 0.0).toDouble(),
        discountPrice: (data['discountPrice'] as num?)?.toDouble(),
        categories: _parseList<String>(data['categories']),
        attributes: _parseList<Map<String, dynamic>>(data['attributes']),
        sku: (data['sku'] as String?) ?? '',
        stock: (data['stock'] as int?) ?? 0,
        stockStatus: (data['stockStatus'] as String?) ?? 'out_of_stock',
        shippingInfo: _parseMap(data['shippingInfo']),
        brandId: (data['brandId'] as String?) ?? '',
        productStatus: (data['productStatus'] as String?) ?? 'inactive',
        tags: _parseList<String>(data['tags']),
        createdAt: (data['createdAt'] as Timestamp?) ?? Timestamp.now(),
        updatedAt: (data['updatedAt'] as Timestamp?) ?? Timestamp.now(),
        isFreeShipping: (data['isFreeShipping'] as bool?) ?? false,
        isFeatured: (data['isFeatured'] as bool?) ?? false,
        isNew: (data['isNew'] as bool?) ?? false,
        soldcount: 0,
        averageRating: 0, // Initialize averagerating
      );
    } catch (e) {
      throw Exception('Failed to parse product ${doc.id}: $e');
    }
  }

  static List<T> _parseList<T>(dynamic data) {
    if (data is! List) return <T>[];

    if (T == Map<String, dynamic>) {
      return data
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .cast<T>()
          .toList();
    }

    return data.whereType<T>().cast<T>().toList();
  }

  static Map<String, dynamic>? _parseMap(dynamic data) {
    if (data is! Map) return null;
    return Map<String, dynamic>.from(data);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'images': images,
      'price': price,
      'discountPrice': discountPrice,
      'categories': categories,
      'attributes': attributes,
      // 'variants': variants,
      'sku': sku,
      'stock': stock,
      'stockStatus': stockStatus,
      'shippingInfo': shippingInfo,
      'brandId': brandId,
      'productStatus': productStatus,
      'tags': tags, // ✅ تم تصحيحه هنا
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isFreeShipping': isFreeShipping,
      'isFeatured': isFeatured,
      'isNew': isNew,
      'soldcount' : soldcount,
      'averageRating' : averageRating,
    };
  }
}
