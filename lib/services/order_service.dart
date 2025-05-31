import 'package:cloud_firestore/cloud_firestore.dart' hide Order; // Hide the conflicting Order definition from Firestore
import 'package:firebase_auth/firebase_auth.dart';
import '../models/order.dart'; // Keep using our own Order model
import '../models/cart_item.dart';
import 'cart_service.dart'; // To clear cart after order creation

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;

  // Create a new order from cart items
  Future<Order?> createOrderFromCart(
      List<CartItem> cartItems,
      Map<String, dynamic> shippingAddress,
      String paymentMethod, // e.g., 'cod'
      {double shippingCost = 0.0, // Example shipping cost
       String? appliedCouponCode, // Added for coupon
       double discountAmount = 0.0, required String paymentStatus // Added for coupon
      }) async {
    final userId = _userId;
    if (userId == null || cartItems.isEmpty) {
      print("User not logged in or cart is empty");
      return null; // Or throw an exception
    }

    // Calculate totals
    double totalAmount = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    // Ensure grandTotal is calculated correctly with discount
    double grandTotal = totalAmount + shippingCost - discountAmount;
    grandTotal = grandTotal < 0 ? 0 : grandTotal; // Prevent negative total

    // Convert CartItems to OrderItems
    List<OrderItem> orderItems = cartItems.map((cartItem) => OrderItem(
      productId: cartItem.productId,
      productName: cartItem.productName,
      productImageUrl: cartItem.productImageUrl,
      quantity: cartItem.quantity,
      price: cartItem.price,
      discountPrice: cartItem.discountPrice,
      selectedAttributes: cartItem.selectedAttributes,
      variantSku: cartItem.variantSku,
    )).toList();

    // Create the Order object, including coupon details
    final newOrder = Order(
      id: '', // Firestore will generate ID
      userId: userId,
      items: orderItems,
      totalAmount: totalAmount,
      shippingCost: shippingCost,
      appliedCouponCode: appliedCouponCode, // Pass coupon code
      discountAmount: discountAmount,     // Pass discount amount
      grandTotal: grandTotal,
      orderStatus: 'pending', // Initial status
      paymentMethod: paymentMethod,
      paymentStatus: 'pending', // Initial status, update upon actual payment
      shippingAddress: shippingAddress,
      createdAt: Timestamp.now(),
      updatedAt: Timestamp.now(),
    );

    try {
      // Add the order to the 'orders' collection
      DocumentReference docRef = await _firestore.collection('orders').add(newOrder.toFirestore());

      // Clear the user's cart after successful order creation
      final cartService = CartService(); // Consider injecting via Provider if needed
      await cartService.clearCart();

      // Return the created order with its ID
      // Fetch the document again to get the data including the ID
      DocumentSnapshot createdDoc = await docRef.get();
      return Order.fromFirestore(createdDoc);

    } catch (e) {
      print("Error creating order: $e");
      // Handle error appropriately (e.g., show message to user)
      return null;
    }
  }

  // Get stream of user's orders
  Stream<List<Order>> getUserOrdersStream() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]); // Return empty stream if user not logged in
    }
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
             return snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList();
          } catch (e) {
            print("Error mapping orders from Firestore: $e");
            // Return an empty list or rethrow, depending on desired error handling
            return []; 
          }
    });
  }

  // TODO: Add methods to update order status (for admin), get specific order details, etc.
}

