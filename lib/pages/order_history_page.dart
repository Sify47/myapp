import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../models/order.dart';
import '../services/order_service.dart';
import 'order_details_page.dart'; // To navigate to order details

class OrderHistoryPage extends StatelessWidget {
  const OrderHistoryPage({super.key});

  // Helper to get a readable status and color
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
    final orderService = Provider.of<OrderService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سجل الطلبات'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Order>>(
        stream: orderService.getUserOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'لا توجد طلبات سابقة.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final orders = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.all(10.0),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              final statusStyle = _getStatusStyle(order.orderStatus);
              final formattedDate = DateFormat('yyyy-MM-dd – hh:mm a', 'en_US').format(order.createdAt.toDate()); // Arabic locale for date

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
                  title: Text(
                    'طلب رقم: ${order.id.substring(0, 8)}...', // Show partial ID
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('التاريخ: $formattedDate'),
                      const SizedBox(height: 4),
                      Text('المجموع: ${order.grandTotal.toStringAsFixed(2)} ر.س'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('الحالة: '),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusStyle['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              statusStyle['text'],
                              style: TextStyle(color: statusStyle['color'], fontWeight: FontWeight.w500, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  isThreeLine: true, // Adjust based on content
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsPage(order: order),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

