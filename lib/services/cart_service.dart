import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/product.dart'; // Needed to get product details when adding to cart

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's cart items subcollection reference
  CollectionReference<Map<String, dynamic>>? _getCartCollectionRef() {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in");
      return null; // Or throw an exception
    }
    return _firestore.collection('users').doc(user.uid).collection('cartItems');
  }

  // Add item to cart or update quantity if it already exists
  Future<void> addItemToCart(Product product, {int quantity = 1, Map<String, dynamic>? selectedAttributes, String? variantSku}) async {
    final cartRef = _getCartCollectionRef();
    if (cartRef == null) return; // Handle user not logged in

    // Use product ID or variant SKU as the document ID in the cart subcollection
    final String cartDocId = variantSku ?? product.id;
    final docRef = cartRef.doc(cartDocId);

    await _firestore.runTransaction((transaction) async {
      final docSnapshot = await transaction.get(docRef);

      final effectivePrice = product.discountPrice ?? product.price;
      final imageUrl = product.images.isNotEmpty ? product.images[0] : null;

      if (docSnapshot.exists) {
        // Item exists, update quantity
        final existingQuantity = docSnapshot.data()?['quantity'] ?? 0;
        transaction.update(docRef, {
          'quantity': existingQuantity + quantity,
          // Optionally update price/image in case they changed, though cart price usually locks on add
          'price': product.price,
          'discountPrice': product.discountPrice,
          'productName': product.name,
          'productImageUrl': imageUrl,
        });
      } else {
        // Item does not exist, create new cart item document
        final newItem = CartItem(
          productId: product.id,
          productName: product.name,
          brandId: product.brandId,
          productImageUrl: imageUrl,
          quantity: quantity,
          price: product.price, // Price when added
          discountPrice: product.discountPrice, // Discount price when added
          selectedAttributes: selectedAttributes,
          variantSku: variantSku,
        );
        transaction.set(docRef, newItem.toMap());
      }
    });
  }

  // Update item quantity in cart
  Future<void> updateItemQuantity(String cartDocId, int newQuantity) async {
    final cartRef = _getCartCollectionRef();
    if (cartRef == null) return;

    if (newQuantity <= 0) {
      // If quantity is zero or less, remove the item
      await removeItemFromCart(cartDocId);
    } else {
      await cartRef.doc(cartDocId).update({'quantity': newQuantity});
    }
  }

  // Remove item from cart
  Future<void> removeItemFromCart(String cartDocId) async {
    final cartRef = _getCartCollectionRef();
    if (cartRef == null) return;
    await cartRef.doc(cartDocId).delete();
  }

  // Get stream of cart items
  Stream<List<CartItem>> getCartItemsStream() {
    final cartRef = _getCartCollectionRef();
    if (cartRef == null) {
      return Stream.value([]); // Return empty stream if user not logged in
    }
    return cartRef.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => CartItem.fromMap(doc.data())).toList();
    });
  }

  // Clear the entire cart (e.g., after checkout)
  Future<void> clearCart() async {
    final cartRef = _getCartCollectionRef();
    if (cartRef == null) return;

    final snapshot = await cartRef.get();
    WriteBatch batch = _firestore.batch();
    for (var doc in snapshot.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }
}

