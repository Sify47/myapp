import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:myapp/pages/invoicePage.dart';
import '../models/order.dart';

class OrderDetailsPage extends StatelessWidget {
  final Order order;

  const OrderDetailsPage({super.key, required this.order});

  // Helper to get a readable status and color (same as in OrderHistoryPage)
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'text': 'قيد الانتظار', 'color': Colors.orange};
      case 'processing':
        return {'text': 'قيد المعالجة', 'color': Colors.blue};
      case 'shipped':
        return {'text': 'تم الشحن', 'color': Colors.purple};
      case 'delivered':
        return {'text': 'تم التوصيل', 'color': Colors.green};
      case 'cancelled':
        return {'text': 'ملغي', 'color': Colors.red};
      default:
        return {'text': status, 'color': Colors.grey};
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusStyle = _getStatusStyle(order.orderStatus);
    final formattedDate = DateFormat(
      'yyyy-MM-dd – hh:mm a',
      'en_US',
    ).format(order.createdAt.toDate());

    return Scaffold(
      appBar: AppBar(
        title: Text('تفاصيل الطلب: ${order.id.substring(0, 8)}...'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.print),
            onPressed:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => InvoicePage(order: order)),
                ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Summary Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ملخص الطلب',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow('رقم الطلب:', order.id),
                    _buildDetailRow('تاريخ الطلب:', formattedDate),
                    _buildDetailRow(
                      'حالة الطلب:',
                      statusStyle['text'],
                      valueColor: statusStyle['color'],
                    ),
                    _buildDetailRow(
                      'طريقة الدفع:',
                      order.paymentMethod == 'cod'
                          ? 'الدفع عند الاستلام'
                          : order.paymentMethod,
                    ),
                    _buildDetailRow(
                      'حالة الدفع:',
                      order.paymentStatus == 'pending'
                          ? 'قيد الانتظار'
                          : order.paymentStatus,
                    ),
                    if (order.trackingNumber != null)
                      _buildDetailRow('رقم التتبع:', order.trackingNumber!),
                  ],
                ),
              ),
            ),

            // Shipping Address Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'عنوان الشحن',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 20),
                    _buildDetailRow(
                      'الاسم:',
                      order.shippingAddress['name'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'العنوان:',
                      order.shippingAddress['addressLine1'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'المدينة:',
                      order.shippingAddress['city'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'الرمز البريدي:',
                      order.shippingAddress['postalCode'] ?? 'N/A',
                    ),
                    _buildDetailRow(
                      'الهاتف:',
                      order.shippingAddress['phone'] ?? 'N/A',
                    ),
                  ],
                ),
              ),
            ),

            // Items List Card
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'المنتجات المطلوبة',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const Divider(height: 20),
                    ListView.separated(
                      shrinkWrap: true,
                      physics:
                          const NeverScrollableScrollPhysics(), // Disable scrolling inside SingleChildScrollView
                      itemCount: order.items.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        final item = order.items[index];
                        final itemPrice = item.discountPrice ?? item.price;
                        return ListTile(
                          leading: SizedBox(
                            width: 50,
                            height: 50,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child:
                                  item.productImageUrl != null
                                      ? Image.network(
                                        item.productImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (c, e, s) =>
                                                const Icon(Icons.image),
                                      )
                                      : const Icon(Icons.image),
                            ),
                          ),
                          title: Text(
                            item.productName,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          subtitle: Text('الكمية: ${item.quantity}'),
                          trailing: Text(
                            '${(itemPrice * item.quantity).toStringAsFixed(2)} ر.س',
                          ),
                        );
                      },
                    ),
                    const Divider(height: 20),
                    _buildTotalRow(
                      'مجموع المنتجات:',
                      '${order.totalAmount.toStringAsFixed(2)} ر.س',
                    ),
                    _buildTotalRow(
                      'تكلفة الشحن:',
                      '${order.shippingCost.toStringAsFixed(2)} ر.س',
                    ),
                    const Divider(),
                    _buildTotalRow(
                      'المجموع الكلي:',
                      '${order.grandTotal.toStringAsFixed(2)} ر.س',
                      isBold: true,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w500, color: valueColor),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
