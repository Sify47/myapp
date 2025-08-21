import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import 'package:myapp/models/order.dart' ; // تأكد من المسار الصحيح

class OrderDetailsPage extends StatelessWidget {
  final DocumentSnapshot orderDoc;
  
  const OrderDetailsPage({super.key, required this.orderDoc});

  @override
  Widget build(BuildContext context) {
    final order = Order.fromFirestore(orderDoc);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('تفاصيل الطلب'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // بطاقة معلومات الطلب الرئيسية
            _buildOrderHeaderCard(order),
            const SizedBox(height: 20),
            
            // معلومات التوصيل
            _buildDeliveryInfoCard(order),
            const SizedBox(height: 20),
            
            // معلومات الدفع
            _buildPaymentInfoCard(order),
            const SizedBox(height: 20),
            
            // المنتجات
            _buildProductsCard(order),
            const SizedBox(height: 20),
            
            // ملخص السعر
            _buildPriceSummaryCard(order),
            const SizedBox(height: 20),
            
            // تتبع الطلب
            _buildTrackingStepper(order.orderStatus),
          ],
        ),
      ),
      
      // زر الإجراءات
      bottomNavigationBar: _buildActionButtons(context, order),
    );
  }

  Widget _buildOrderHeaderCard(Order order) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF3366FF).withOpacity(0.9),
              const Color(0xFF6A11CB).withOpacity(0.9),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'رقم الطلب',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  '#${order.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'تاريخ الطلب',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Text(
                  DateFormat('yyyy/MM/dd - hh:mm a').format(order.createdAt.toDate()),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالة الطلب',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.orderStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getStatusColor(order.orderStatus)),
                  ),
                  child: Text(
                    _getStatusText(order.orderStatus),
                    style: TextStyle(
                      color: _getStatusColor(order.orderStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'حالة الدفع',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getPaymentStatusColor(order.paymentStatus).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _getPaymentStatusColor(order.paymentStatus)),
                  ),
                  child: Text(
                    _getPaymentStatusText(order.paymentStatus),
                    style: TextStyle(
                      color: _getPaymentStatusColor(order.paymentStatus),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfoCard(Order order) {
    final address = order.shippingAddress;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.location_on_outlined, size: 20, color: Color(0xFF3366FF)),
                SizedBox(width: 8),
                Text(
                  'عنوان التوصيل',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (address.isNotEmpty) ...[
              Text(
                '${address['name']}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(address['addressLine1'] ?? ''),
              const SizedBox(height: 4),
              Text('${address['province']}'),
              const SizedBox(height: 4),
              Text(address['phone'] ?? ''),
              const SizedBox(height: 8),
              if (order.trackingNumber != null) ...[
                const Divider(),
                const SizedBox(height: 8),
                const Row(
                  children: [
                    Icon(Icons.local_shipping, size: 20, color: Color(0xFF3366FF)),
                    SizedBox(width: 8),
                    Text(
                      'رقم التتبع',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  order.trackingNumber!,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                ),
              ],
            ] else
              const Text('لا يوجد عنوان', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentInfoCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payment, size: 20, color: Color(0xFF3366FF)),
                SizedBox(width: 8),
                Text(
                  'معلومات الدفع',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('طريقة الدفع'),
                Text(
                  _getPaymentMethodText(order.paymentMethod),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (order.appliedCouponCode != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('كود الخصم'),
                  Text(
                    order.appliedCouponCode!,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductsCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 20, color: Color(0xFF3366FF)),
                const SizedBox(width: 8),
                Text(
                  'المنتجات (${order.items.length})',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...order.items.map((item) => _buildProductItem(item)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductItem(OrderItem item) {
    final finalPrice = item.discountPrice ?? item.price;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // صورة المنتج
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[200],
              image: item.productImageUrl != null
                  ? DecorationImage(
                      image: NetworkImage(item.productImageUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.productImageUrl == null
                ? const Icon(Icons.image, color: Colors.grey, size: 24)
                : null,
          ),
          const SizedBox(width: 12),
          
          // تفاصيل المنتج
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                
                if (item.selectedAttributes != null && item.selectedAttributes!.isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.selectedAttributes!.entries
                            .map((e) => '${e.key}: ${e.value}')
                            .join(', '),
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 4),
                    ],
                  ),
                
                Text(
                  'الكمية: ${item.quantity}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          
          // السعر
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.discountPrice != null)
                Text(
                  '${item.price.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              Text(
                '${finalPrice.toStringAsFixed(2)} جنيه',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'المجموع: ${(finalPrice * item.quantity).toStringAsFixed(2)} جنيه',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummaryCard(Order order) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildPriceRow('المجموع', order.totalAmount),
            _buildPriceRow('التوصيل', order.shippingCost),
            if (order.discountAmount > 0)
              _buildPriceRow('الخصم', -order.discountAmount),
            const Divider(),
            _buildPriceRow(
              'الإجمالي النهائي',
              order.grandTotal,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isTotal ? const Color(0xFF3366FF) : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            '${amount.toStringAsFixed(2)} جنيه',
            style: TextStyle(
              color: isTotal ? const Color(0xFF3366FF) : Colors.black,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingStepper(String status) {
    final steps = [
      {'title': 'تم استلام الطلب', 'status': 'pending', 'icon': Icons.shopping_cart},
      {'title': 'قيد التجهيز', 'status': 'processing', 'icon': Icons.build},
      {'title': 'قيد الشحن', 'status': 'shipped', 'icon': Icons.local_shipping},
      {'title': 'تم التوصيل', 'status': 'delivered', 'icon': Icons.check_circle},
    ];

    final currentIndex = steps.indexWhere((step) => step['status'] == status);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.track_changes_outlined, size: 20, color: Color(0xFF3366FF)),
                SizedBox(width: 8),
                Text(
                  'تتبع الطلب',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...steps.asMap().entries.map((entry) {
              final index = entry.key;
              final step = entry.value;
              final isActive = index <= currentIndex;
              final isLast = index == steps.length - 1;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // الخط والعلامة
                  Column(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFF3366FF) : Colors.grey[300],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          step['icon'] as IconData?,
                          size: 16,
                          color: isActive ? Colors.white : Colors.grey,
                        ),
                      ),
                      if (!isLast)
                        Container(
                          width: 2,
                          height: 40,
                          color: isActive ? const Color(0xFF3366FF) : Colors.grey[300],
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  // النص
                  // Expanded(
                  //   child: Text(
                  //     step['title']!,
                  //     style: TextStyle(
                  //       fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  //       color: isActive ? Colors.black : Colors.grey,
                  //     ),
                  //   ),
                  // ),
                ],
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, Order order) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (order.orderStatus == 'pending' || order.orderStatus == 'processing')
            Expanded(
              child: OutlinedButton(
                onPressed: () => _cancelOrder(context, order.id),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: const BorderSide(color: Colors.red),
                ),
                child: const Text(
                  'إلغاء الطلب',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          if (order.orderStatus == 'pending' || order.orderStatus == 'processing')
            const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _contactSupport(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3366FF),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('التواصل مع الدعم'),
            ),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context, String orderId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('إلغاء الطلب'),
        content: const Text('هل أنت متأكد من إلغاء هذا الطلب؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseFirestore.instance
                    .collection('orders')
                    .doc(orderId)
                    .update({
                  'orderStatus': 'cancelled',
                  'updatedAt': Timestamp.now(),
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم إلغاء الطلب بنجاح')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('خطأ في الإلغاء: $e')),
                );
              }
            },
            child: const Text('تأكيد الإلغاء', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _contactSupport(BuildContext context) {
    // TODO: تنفيذ التواصل مع الدعم
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      case 'processing': return Colors.blue;
      case 'shipped': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending': return 'قيد الانتظار';
      case 'processing': return 'قيد التجهيز';
      case 'shipped': return 'قيد الشحن';
      case 'delivered': return 'تم التوصيل';
      case 'cancelled': return 'ملغي';
      default: return status;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status) {
      case 'paid': return Colors.green;
      case 'failed': return Colors.red;
      default: return Colors.orange;
    }
  }

  String _getPaymentStatusText(String status) {
    switch (status) {
      case 'paid': return 'مدفوع';
      case 'pending': return 'قيد الانتظار';
      case 'failed': return 'فشل';
      default: return status;
    }
  }

  String _getPaymentMethodText(String method) {
    switch (method) {
      case 'cod': return 'الدفع عند الاستلام';
      case 'stripe': return 'بطاقة ائتمان';
      case 'paypal': return 'PayPal';
      default: return method;
    }
  }
}