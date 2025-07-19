import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/cart_item.dart';
import '../models/coupon.dart';
import '../services/cart_service.dart';
import '../services/order_service.dart';
import '../services/coupon_service.dart';
import '../auth_model.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _isApplyingCoupon = false;

  // Controllers for shipping address
  final _nameController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _phoneController = TextEditingController();

  // Coupon state
  final _couponController = TextEditingController();
  Coupon? _appliedCoupon;
  double _discountAmount = 0.0;
  String? _couponError;

  // Payment method
  final String _paymentMethod = 'cod'; // Cash on Delivery

  // Shipping province state
  late String _selectedProvince = 'Cairo';
  double _shippingCost = 50.0;
  List<Map<String, dynamic>> _provinces = [];
  bool _isLoadingProvinces = false;

  @override
  void initState() {
    super.initState();
    _loadShippingProvinces();
  }

  Future<void> _loadShippingProvinces() async {
    setState(() => _isLoadingProvinces = true);
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection('shipping_costs').get();
      _provinces = snapshot.docs.map((doc) => doc.data()).toList();
      if (_provinces.isNotEmpty) {
        _selectedProvince = _provinces.first['name'];
        _shippingCost = _provinces.first['cost'] as double;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل بيانات الشحن: $e')),
      );
    } finally {
      setState(() => _isLoadingProvinces = false);
    }
  }

  Map<String, double> _calculateTotals(List<CartItem> cartItems) {
    double itemsTotal = cartItems.fold(
      0.0,
      (sum, item) => sum + item.totalPrice,
    );
    double discount = 0.0;

    if (_appliedCoupon != null) {
      discount = _appliedCoupon!.calculateDiscount(itemsTotal);
    }

    double grandTotal = itemsTotal + _shippingCost - discount;
    grandTotal = grandTotal < 0 ? 0 : grandTotal;
    return {
      'itemsTotal': itemsTotal,
      'shippingCost': _shippingCost,
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
            SnackBar(
              content: Text(
                'تم تطبيق الكوبون بنجاح! خصم ${_discountAmount.toStringAsFixed(2)} ج.م',
              ),
              backgroundColor: Colors.green,
            ),
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

  Future<void> _placeOrder(
    List<CartItem> cartItems,
    double discountAmount,
    String? couponCode,
    double grandTotal,
  ) async {
    if (!_formKey.currentState!.validate() || cartItems.isEmpty) {
      return;
    }

    setState(() => _isLoading = true);

    final brandIds = cartItems.map((item) => item.brandId).toSet().toList();
    const String paymentStatus = 'pending';

    final orderService = Provider.of<OrderService>(context, listen: false);
    final couponService = Provider.of<CouponService>(context, listen: false);

    final shippingAddress = {
      'name': _nameController.text.trim(),
      'province': _selectedProvince,
      'addressLine1': _addressLine1Controller.text.trim(),
      'postalCode': _postalCodeController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    try {
      final createdOrder = await orderService.createOrderFromCart(
        cartItems,
        shippingAddress,
        _paymentMethod,
        paymentStatus: paymentStatus,
        brandIds: brandIds,
        shippingCost: _shippingCost,
        appliedCouponCode: couponCode,
        discountAmount: discountAmount,
      );

      if (createdOrder != null) {
        if (couponCode != null) {
          await couponService.incrementCouponUsage(couponCode);
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إنشاء طلبك بنجاح!'),
            backgroundColor: Colors.green,
          ),
        );
        Provider.of<CartService>(context, listen: false).clearCart();
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حفظ الطلب. الرجاء المحاولة مرة أخرى.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
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
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF3366FF)),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF3366FF)),
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
          if (keyboardType == TextInputType.phone &&
              !RegExp(r'^[0-9]+$').hasMatch(value)) {
            return 'الرجاء إدخال رقم هاتف صحيح';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildProvinceDropdown() {
    if (_isLoadingProvinces) {
      return const CircularProgressIndicator();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        value: _selectedProvince,
        decoration: InputDecoration(
          labelText: 'المحافظة',
          prefixIcon: const Icon(Icons.location_on, color: Color(0xFF3366FF)),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        items:
            _provinces.map((province) {
              return DropdownMenuItem<String>(
                value: province['name'],
                child: Text('${province['name']}'),
              );
            }).toList(),
        onChanged: (value) {
          setState(() {
            _selectedProvince = value!;
            final selectedProvinceData = _provinces.firstWhere(
              (p) => p['name'] == value,
              orElse: () => _provinces.first,
            );
            _shippingCost = selectedProvinceData['cost'].toDouble();
          });
        },
        validator: (value) => value == null ? 'الرجاء اختيار المحافظة' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('إتمام الشراء'), centerTitle: true),
      body: StreamBuilder<List<CartItem>>(
        stream: cartService.getCartItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !_isLoading) {
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
                  Text(
                    'عنوان الشحن',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 15),
                  _buildTextField(
                    _nameController,
                    'الاسم الكامل',
                    Icons.person,
                  ),
                  _buildProvinceDropdown(),
                  _buildTextField(
                    _addressLine1Controller,
                    'العنوان (الشارع، المبنى)',
                    Icons.location_on,
                  ),
                  _buildTextField(
                    _postalCodeController,
                    'الرمز البريدي',
                    Icons.local_post_office,
                    keyboardType: TextInputType.number,
                  ),
                  _buildTextField(
                    _phoneController,
                    'رقم الهاتف',
                    Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'كوبون الخصم',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
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
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed:
                            _isApplyingCoupon
                                ? null
                                : () => _applyCoupon(itemsTotal),
                        child:
                            _isApplyingCoupon
                                ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : const Text('تطبيق'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'طريقة الدفع',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  ListTile(
                    leading: const Icon(Icons.money, color: Colors.green),
                    title: const Text(
                      'الدفع عند الاستلام',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: const Text(
                      'سيتم تحصيل المبلغ نقداً عند توصيل الطلب.',
                    ),
                  ),

                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 10),
                  Text(
                    'ملخص الطلب',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    title: Text('مجموع المنتجات (${cartItems.length} صنف)'),
                    trailing: Text('${itemsTotal.toStringAsFixed(2)} ج.م'),
                  ),
                  ListTile(
                    title: const Text('تكلفة الشحن'),
                    trailing: Text('${shippingCost.toStringAsFixed(2)} ج.م'),
                  ),
                  if (_appliedCoupon != null)
                    ListTile(
                      title: Text('خصم الكوبون (${_appliedCoupon!.code})'),
                      trailing: Text(
                        '- ${discount.toStringAsFixed(2)} ج.م',
                        style: const TextStyle(color: Colors.green),
                      ),
                    ),
                  const Divider(),
                  ListTile(
                    title: const Text(
                      'المجموع الكلي',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    trailing: Text(
                      '${grandTotal.toStringAsFixed(2)} ج.م',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),
                  Center(
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed:
                                  () => _placeOrder(
                                    cartItems,
                                    discount,
                                    _appliedCoupon?.code,
                                    grandTotal,
                                  ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF3366FF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 50,
                                  vertical: 15,
                                ),
                                textStyle: const TextStyle(fontSize: 18),
                              ),
                              child: const Text(
                                'تأكيد الطلب (الدفع عند الاستلام)',
                              ),
                            ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
