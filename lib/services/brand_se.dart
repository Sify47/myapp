import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/brand.dart';

class BrandService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<Brand> getBrandStream(String brandId) {
    return _firestore
        .collection('brands')
        .doc(brandId)
        .snapshots()
        .map((snapshot) => Brand.fromFirestore(snapshot));
  }
}