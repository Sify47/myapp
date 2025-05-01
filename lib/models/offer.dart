import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String title;
  final String description;
  final String brand;
  final String discount;
  final String code;

  Offer({
    required this.title,
    required this.description,
    required this.brand,
    required this.discount,
    required this.code,
  });

  factory Offer.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Offer(
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      brand: data['brand'] ?? '',
      discount: data['discount'] ?? '',
      code: data['code'] ?? '',
    );
  }
}