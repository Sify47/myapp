import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Removed Stripe imports

import '../models/cart_item.dart';
import '../models/coupon.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/coupon_service.dart';
import '../auth_model.dart'; // To get user ID

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isApplyingCoupon = false;
  // Removed _isProcessingPayment

  // Controllers for shipping address
  final _nameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  // Coupon state
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  String? _couponError;

  // Removed _selectedPaymentMethod, defaulting to COD
  final String _paymentMethod = 'cod'; // Fixed to Cash on Delivery

  // Calculate totals based on cart items and applied coupon
  Map<String, double> _calculateTotals(List<CartItem> cartItems) {
    double itemsTotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
    double shippingCost = 15.0; // Example fixed shipping cost
    double discount = 0.0;

    if (_appliedCoupon != null) {
      discount = _appliedCoupon!.calculateDiscount(itemsTotal);
    }

    double grandTotal = itemsTotal + shippingCost - discount;
    // Ensure grandTotal is not negative
    grandTotal = grandTotal < 0 ? 0 : grandTotal;
    return {
      'itemsTotal': itemsTotal,
      'shippingCost': shippingCost,
      'discount': discount,
      'grandTotal': grandTotal,
    };
  }

  Future<void> _applyCoupon(double currentItemsTotal) async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _couponError = 'الرجاء إدخال رمز الكوبون';
        _appliedCoupon = null;
        _discountAmount = 0.0;
      });
      return;
    }

    setState(() {
      _isApplyingCoupon = true;
      _couponError = null;
    });

    final couponService = Provider.of<CouponService>(context, listen: false);
    final coupon = await couponService.validateCoupon(code, currentItemsTotal);

    if (mounted) {
      setState(() {
        if (coupon != null) {
          _appliedCoupon = coupon;
          _discountAmount = coupon.calculateDiscount(currentItemsTotal);
          _couponError = null;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تطبيق الكوبون بنجاح! خصم ${_discountAmount.toStringAsFixed(2)} ر.س'), backgroundColor: Colors.green),
          );
        } else {
          _appliedCoupon = null;
          _discountAmount = 0.0;
          _couponError = 'رمز الكوبون غير صالح أو لا ينطبق';
        }
        _isApplyingCoupon = false;
      });
    }
  }

  // --- Removed Stripe Payment Logic --- 

  Future<void> _placeOrder(List<CartItem> cartItems, double discountAmount, String? couponCode, double grandTotal) async {
    if (!_formKey.currentState!.validate() || cartItems.isEmpty) {
      return; // Form is invalid or cart is empty
    }

    setState(() => _isLoading = true);

    // Payment is always COD, so paymentSuccessful is true and status is pending
    const bool paymentSuccessful = true;
    const String paymentStatus = 'pending';

    // Proceed to create order in Firestore
    if (paymentSuccessful) { // This condition is always true now
      final orderService = Provider.of<OrderService>(context, listen: false);
      final couponService = Provider.of<CouponService>(context, listen: false);

      final shippingAddress = {
        'name': _nameController.text.trim(),
        'addressLine1': _addressLine1Controller.text.trim(),
        'city': _cityController.text.trim(),
        'postalCode': _postalCodeController.text.trim(),
        'phone': _phoneController.text.trim(),
      };

      try {
        final createdOrder = await orderService.createOrderFromCart(
          cartItems,
          shippingAddress,
          _paymentMethod, // Always 'cod'
          paymentStatus: paymentStatus, // Always 'pending'
          shippingCost: 15.0, // Example fixed shipping cost
          appliedCouponCode: couponCode,
          discountAmount: discountAmount,
        );

        if (createdOrder != null) {
          // Increment coupon usage if one was applied
          if (couponCode != null) {
            await couponService.incrementCouponUsage(couponCode);
          }

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('تم إنشاء طلبك بنجاح!'),
              backgroundColor: Colors.green,
            ),
          );
          // Clear cart and navigate home
          Provider.of<CartService>(context, listen: false).clearCart();
          Navigator.popUntil(context, (route) => route.isFirst);
        } else {
          // This case might happen if Firestore write fails
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في حفظ الطلب. الرجاء المحاولة مرة أخرى.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // Handle Firestore or other errors during order creation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء حفظ الطلب: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
         if (mounted) {
           setState(() => _isLoading = false);
         }
      }
    // ignore: dead_code
    } else {
       // This block should technically not be reachable anymore
       if (mounted) {
         setState(() => _isLoading = false);
       }
    }
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text}) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.orange),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          if (keyboardType == TextInputType.phone && !RegExp(r'^[0-9]+$').hasMatch(value)) {
             return 'الرجاء إدخال رقم هاتف صحيح';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إتمام الشراء'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: cartService.getCartItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !_isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('خطأ في تحميل السلة: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا يمكن المتابعة، السلة فارغة.'));
          }

          final cartItems = snapshot.data!;
          final totals = _calculateTotals(cartItems);
          final itemsTotal = totals['itemsTotal']!;
          final shippingCost = totals['shippingCost']!;
          final discount = totals['discount']!;
          final grandTotal = totals['grandTotal']!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('عنوان الشحن', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 15),
                  _buildTextField(_nameController, 'الاسم الكامل', Icons.person),
                  _buildTextField(_addressLine1Controller, 'العنوان (الشارع، المبنى)', Icons.location_on),
                  _buildTextField(_cityController, 'المدينة', Icons.location_city),
                  _buildTextField(_postalCodeController, 'الرمز البريدي', Icons.local_post_office, keyboardType: TextInputType.number),
                  _buildTextField(_phoneController, 'رقم الهاتف', Icons.phone, keyboardType: TextInputType.phone),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('كوبون الخصم', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _couponController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'أدخل رمز الكوبون (إن وجد)',
                            errorText: _couponError,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _isApplyingCoupon ? null : () => _applyCoupon(itemsTotal),
                        child: _isApplyingCoupon ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('تطبيق'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('طريقة الدفع', style: Theme.of(context).textTheme.titleLarge),
                  // Only show Cash on Delivery option
                  ListTile(
                    leading: const Icon(Icons.money, color: Colors.green),
                    title: const Text('الدفع عند الاستلام', style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: const Text('سيتم تحصيل المبلغ نقداً عند توصيل الطلب.'),
                  ),
                  // Removed Stripe RadioListTile
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text('ملخص الطلب', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text('مجموع المنتجات (${cartItems.length} صنف)'),
                    trailing: Text('${itemsTotal.toStringAsFixed(2)} ر.س'),
                  ),
                  ListTile(
                    title: const Text('تكلفة الشحن'),
                    trailing: Text('${shippingCost.toStringAsFixed(2)} ر.س'),
                  ),
                  if (_appliedCoupon != null)
                    ListTile(
                      title: Text('خصم الكوبون (${_appliedCoupon!.code})'),
                      trailing: Text('- ${discount.toStringAsFixed(2)} ر.س', style: const TextStyle(color: Colors.green)),
                    ),
                  const Divider(),
                  ListTile(
                    title: const Text('المجموع الكلي', style: TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Text('${grandTotal.toStringAsFixed(2)} ر.س', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: () => _placeOrder(cartItems, discount, _appliedCoupon?.code, grandTotal),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                              textStyle: const TextStyle(fontSize: 18)
                            ),
                            child: const Text('تأكيد الطلب (الدفع عند الاستلام)'), // Updated button text
                          ),
                  ),
                  // Removed note about Stripe backend requirement
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

