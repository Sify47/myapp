import 'package:cloud_firestore/cloud_firestore.dart'
    hide Order; // Hide the conflicting Order definition from Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myapp/auth_model.dart';
import 'package:path/path.dart';
import 'package:provider/provider.dart';
import '../models/order.dart'; // Keep using our own Order model
import '../models/cart_item.dart';
import 'cart_service.dart'; // To clear cart after order creation

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get the current user's ID
  String? get _userId => _auth.currentUser?.uid;
  void _awardLoyaltyPoints(String userId, double orderTotal) {
    final points = (orderTotal / 10).floor(); // نقطة لكل 10 جنيه

    FirebaseFirestore.instance.collection('users').doc(userId).update({
      'loyaltyPoints': FieldValue.increment(points),
    });

    // إضافة إلى السجل
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('pointsHistory')
        .add({
          'points': points,
          'reason': 'شراء منتج',
          'date': Timestamp.now(),
          'orderTotal': orderTotal,
        });
  }

  Future<DocumentReference?> createOrderFromCart(
    List<CartItem> cartItems,
    Map<String, dynamic> shippingAddress,
    String paymentMethod, {
    String paymentStatus = 'pending',
    required List<String> brandIds, // تغيير من String إلى List<String>
    double shippingCost = 0.0,
    String? appliedCouponCode,
    double discountAmount = 0.0,
  }) async {
    try {
      // final authModel = Provider.of<AuthModel>(context as BuildContext, listen: false);
      // final userId = authModel.currentUser?.uid;

      if (_userId == null) throw Exception('User not authenticated');
      await _validateProductQuantities(cartItems);

      // حساب المجاميع
      final itemsTotal = cartItems.fold(
        0.0,
        (sum, item) => sum + item.totalPrice,
      );
      final grandTotal = itemsTotal + shippingCost - discountAmount;

      // تحضير بيانات الطلب
      final orderData = {
        'userId': _userId,
        'items': cartItems.map((item) => item.toMap()).toList(),
        'shippingAddress': shippingAddress,
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'brandIds': brandIds, // حفظ جميع الـ brandIds
        'itemsTotal': itemsTotal,
        'shippingCost': shippingCost,
        'discountAmount': discountAmount,
        'grandTotal': grandTotal,
        'appliedCouponCode': appliedCouponCode,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // إضافة الطلب إلى Firestore
      final docRef = await FirebaseFirestore.instance
          .collection('orders')
          .add(orderData);
      // Update product quantities after successful order creation
      await updateProductQuantitiesAfterPurchase(cartItems);
      _awardLoyaltyPoints(_userId! , grandTotal);
      // Clear the cart after order creation
      // final cartService = CartService();
      // await cartService.clearCart();
      return docRef;
    } catch (e) {
      // debugPrint('Error creating order: $e');
      return null;
    }
  } // Get stream of user's orders

  Future<void> updateProductQuantitiesAfterPurchase(
    List<CartItem> cartItems,
  ) async {
    try {
      final batch = _firestore.batch();

      for (final item in cartItems) {
        final productRef = _firestore
            .collection('products')
            .doc(item.productId);

        batch.update(productRef, {
          'stock': FieldValue.increment(-item.quantity),
          'soldcount': FieldValue.increment(item.quantity),
        });
      }

      await batch.commit();
    } catch (e) {
      print('Error updating product quantities: $e');
      throw Exception('Failed to update product quantities');
    }
  }

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
            return snapshot.docs
                .map((doc) => Order.fromFirestore(doc))
                .toList();
          } catch (e) {
            print("Error mapping orders from Firestore: $e");
            // Return an empty list or rethrow, depending on desired error handling
            return [];
          }
        });
  }

  Stream<List<Order>> getbrandOrdersStream(String brandid) {
    return _firestore
        .collection('orders')
        .where('brandIds', arrayContains: brandid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .handleError((error) {
          print("Firestore error: $error");
          throw error;
        })
        .map((snapshot) {
          print('Fetched ${snapshot.docs.length} orders for brand: $brandid');

          return snapshot.docs.map((doc) {
            try {
              return Order.fromFirestore(doc);
            } catch (e) {
              print("Error parsing order ${doc.id}: $e");
              throw Exception("Failed to parse order ${doc.id}");
            }
          }).toList();
        });
  }

  Future<void> _validateProductQuantities(List<CartItem> cartItems) async {
    try {
      // جلب جميع المنتجات في عملية واحدة لتحسين الأداء
      final productIds = cartItems.map((item) => item.productId).toList();
      final productsSnapshot =
          await _firestore
              .collection('products')
              .where(FieldPath.documentId, whereIn: productIds)
              .get();

      final productsMap = {
        for (var doc in productsSnapshot.docs) doc.id: doc.data(),
      };

      // التحقق من كل عنصر في السلة
      for (final item in cartItems) {
        final productData = productsMap[item.productId];
        if (productData == null) {
          throw Exception('Product ${item.productId} not found');
        }

        final availableQuantity = productData['stock'] ?? 0;
        if (availableQuantity < item.quantity) {
          throw Exception(
            'Not enough stock for product ${item.productName}. Available: $availableQuantity, Requested: ${item.quantity}',
          );
        }
      }
    } catch (e) {
      print('Error validating product quantities: $e');
      rethrow;
    }
  }

  Future<void> checkStockBeforeAddToCart(String productId, int quantity) async {
    final doc = await _firestore.collection('products').doc(productId).get();
    if (!doc.exists) throw Exception('Product not found');

    final available = doc.data()?['stock'] ?? 0;
    if (available < quantity) {
      throw Exception('Insufficient stock. Only $available available');
    }
  }

  Stream<List<Order>> getBrandOrdersStream() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]); // Return empty stream if user not logged in
    }
    return _firestore
        .collection('orders')
        .where('brandIds', arrayContains: userId)
        // .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
          try {
            return snapshot.docs
                .map((doc) => Order.fromFirestore(doc))
                .toList();
          } catch (e) {
            print("Error mapping orders from Firestore: $e");
            // Return an empty list or rethrow, depending on desired error handling
            return [];
          }
        });
  }

  // TODO: Add methods to update order status (for admin), get specific order details, etc.
}
