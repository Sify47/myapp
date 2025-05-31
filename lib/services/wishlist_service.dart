import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class WishlistService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's wishlist subcollection reference
  CollectionReference<Map<String, dynamic>>? _getWishlistCollectionRef() {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in for wishlist operations");
      return null;
    }
    // Store wishlist items as documents in a subcollection, using product ID as document ID
    return _firestore.collection('users').doc(user.uid).collection('wishlistItems');
  }

  // Add a product to the wishlist
  Future<void> addToWishlist(String productId) async {
    final wishlistRef = _getWishlistCollectionRef();
    if (wishlistRef == null) return;

    // Store minimal data, just the timestamp for now, using product ID as doc ID
    await wishlistRef.doc(productId).set({
      'productId': productId, // Store productId explicitly for easier querying if needed
      'addedAt': Timestamp.now(),
    });
  }

  // Remove a product from the wishlist
  Future<void> removeFromWishlist(String productId) async {
    final wishlistRef = _getWishlistCollectionRef();
    if (wishlistRef == null) return;
    await wishlistRef.doc(productId).delete();
  }

  // Check if a product is in the wishlist
  Stream<bool> isFavoriteStream(String productId) {
    final wishlistRef = _getWishlistCollectionRef();
    if (wishlistRef == null) {
      return Stream.value(false); // Not favorite if not logged in
    }
    return wishlistRef.doc(productId).snapshots().map((snapshot) => snapshot.exists);
  }

  // Get a stream of wishlist product IDs
  Stream<List<String>> getWishlistProductIdsStream() {
    final wishlistRef = _getWishlistCollectionRef();
    if (wishlistRef == null) {
      return Stream.value([]); // Empty list if not logged in
    }
    return wishlistRef.orderBy('addedAt', descending: true).snapshots().map((snapshot) {
      // Extract product IDs from the documents
      return snapshot.docs.map((doc) => doc.id).toList();
    });
  }

  // Toggle wishlist status (add if not present, remove if present)
  Future<void> toggleWishlistStatus(String productId) async {
     final wishlistRef = _getWishlistCollectionRef();
    if (wishlistRef == null) return;

    final docRef = wishlistRef.doc(productId);
    final docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      await removeFromWishlist(productId);
    } else {
      await addToWishlist(productId);
    }
  }
}

