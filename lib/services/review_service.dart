import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/review.dart';

class ReviewService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get reviews for a specific product
  Stream<List<Review>> getReviewsForProductStream(String productId) {
    return _firestore
        .collection('products')
        .doc(productId)
        .collection('reviews')
        .orderBy('createdAt', descending: true)
        // .where('isApproved', isEqualTo: true) // Optional: Only show approved reviews
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => Review.fromFirestore(doc)).toList());
  }

  // Add a review for a product
  Future<void> addReview(String productId, double rating, String comment) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User must be logged in to add a review.');
    }

    // Optional: Check if user has already reviewed this product
    // final existingReview = await _firestore
    //     .collection('products')
    //     .doc(productId)
    //     .collection('reviews')
    //     .where('userId', isEqualTo: user.uid)
    //     .limit(1)
    //     .get();
    // if (existingReview.docs.isNotEmpty) {
    //   throw Exception('You have already reviewed this product.');
    // }

    // Optional: Fetch user's display name (consider storing it during signup/profile update)
    // For simplicity, using email or a placeholder if display name is null
    final userName = user.displayName ?? user.email ?? 'Anonymous User';

    final newReviewRef = _firestore.collection('products').doc(productId).collection('reviews').doc(); // Auto-generate ID

    final newReview = Review(
      id: newReviewRef.id,
      productId: productId,
      userId: user.uid,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: Timestamp.now(),
      // isApproved: false, // Start as not approved if moderation is needed
    );

    await newReviewRef.set(newReview.toFirestore());

    // Optional: Update the product's average rating and review count
    // This is better done using Cloud Functions for atomicity and scalability
    // await _updateProductRating(productId);
  }

  // --- Helper for updating product rating (Better implemented in Cloud Functions) ---
  // Future<void> _updateProductRating(String productId) async {
  //   final reviewsSnapshot = await _firestore
  //       .collection('products')
  //       .doc(productId)
  //       .collection('reviews')
  //       // .where('isApproved', isEqualTo: true) // Only count approved reviews
  //       .get();

  //   if (reviewsSnapshot.docs.isEmpty) {
  //     await _firestore.collection('products').doc(productId).update({
  //       'averageRating': 0.0,
  //       'reviewCount': 0,
  //     });
  //     return;
  //   }

  //   double totalRating = 0;
  //   for (var doc in reviewsSnapshot.docs) {
  //     totalRating += (doc.data()['rating'] ?? 0.0).toDouble();
  //   }
  //   double averageRating = totalRating / reviewsSnapshot.docs.length;
  //   int reviewCount = reviewsSnapshot.docs.length;

  //   await _firestore.collection('products').doc(productId).update({
  //     'averageRating': double.parse(averageRating.toStringAsFixed(1)), // Store with 1 decimal place
  //     'reviewCount': reviewCount,
  //   });
  // }
}

