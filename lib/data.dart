import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> addBrandWithOffer() async {
  final brandRef = await FirebaseFirestore.instance.collection('brands').add({
    'name': 'Nike',
    'category': 'رياضي',
    'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg',
    'description': 'براند رياضي عالمي',
  });

  await brandRef.collection('offers').add({
    'title': 'خصم 30%',
    'description': 'خصم على كل الأحذية الرياضية',
    'imageUrl': 'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg',
    'validUntil': Timestamp.fromDate(DateTime(2025, 5, 31)),
  });
}
