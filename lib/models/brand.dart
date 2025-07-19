import 'package:cloud_firestore/cloud_firestore.dart';

class Brand {
  final String id;
  final String name;
  final String? image;

  Brand({
    required this.id,
    required this.name,
    this.image,
  });

  factory Brand.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Brand(
      id: doc.id,
      name: data['name'] ?? '',
      image: data['image'],
    );
  }
}