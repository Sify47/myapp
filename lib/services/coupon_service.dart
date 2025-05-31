import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/coupon.dart';

class CouponService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Reference to the coupons collection
  CollectionReference<Map<String, dynamic>> get _couponsCollectionRef =>
      _firestore.collection('coupons');

  // Validate a coupon code and return the Coupon object if valid
  Future<Coupon?> validateCoupon(String code, double orderTotal) async {
    try {
      final docSnapshot = await _couponsCollectionRef.doc(code).get();

      if (!docSnapshot.exists) {
        print('Coupon code not found.');
        return null; // Coupon code doesn't exist
      }

      final coupon = Coupon.fromFirestore(docSnapshot);

      // Check basic validity (active, not expired, usage limit)
      if (!coupon.isValid) {
        print('Coupon is not valid (inactive, expired, or usage limit reached).');
        return null;
      }

      // Check minimum spend requirement
      if (coupon.minimumSpend != null && orderTotal < coupon.minimumSpend!) {
        print('Order total does not meet minimum spend requirement for this coupon.');
        return null;
      }

      // All checks passed
      return coupon;

    } catch (e) {
      print('Error validating coupon: $e');
      return null;
    }
  }

  // Increment coupon usage count (use Firestore transaction for safety)
  Future<bool> incrementCouponUsage(String couponCode) async {
    final docRef = _couponsCollectionRef.doc(couponCode);

    try {
      await _firestore.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) {
          throw Exception("Coupon does not exist!");
        }
        final currentUsage = snapshot.data()?['currentUsage'] ?? 0;
        transaction.update(docRef, {'currentUsage': currentUsage + 1});
      });
      return true;
    } catch (e) {
      print("Failed to increment coupon usage: $e");
      return false;
    }
  }

  // --- Admin Methods ---

  // Add a new coupon
  Future<void> addCoupon(Coupon coupon) async {
    // Use the coupon code as the document ID for easy lookup
    await _couponsCollectionRef.doc(coupon.code).set(coupon.toFirestore());
  }

  // Update an existing coupon
  Future<void> updateCoupon(Coupon coupon) async {
    await _couponsCollectionRef.doc(coupon.id).update(coupon.toFirestore());
  }

  // Delete a coupon
  Future<void> deleteCoupon(String couponId) async {
    await _couponsCollectionRef.doc(couponId).delete();
  }

  // Get a stream of all coupons (for admin panel)
  Stream<List<Coupon>> getAllCouponsStream() {
    return _couponsCollectionRef.orderBy('createdAt', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Coupon.fromFirestore(doc)).toList();
    });
  }
}

