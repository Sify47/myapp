import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; // Needed for Timestamp
import 'package:intl/intl.dart'; // For number formatting
import '../../models/order.dart';
import '../../services/order_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  // TODO: Add date range filtering later

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final numberFormat = NumberFormat.currency(locale: 'ar_SA', symbol: 'ر.س');

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الأساسية'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Order>>(
        // Fetch all orders for reporting (consider pagination/filtering for large datasets)
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots()
            .map((snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ في تحميل بيانات التقارير: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بيانات لعرض التقارير.'));
          }

          final orders = snapshot.data!;

          // Calculate basic metrics
          final totalOrders = orders.length;
          final totalSales = orders.fold(0.0, (sum, order) => sum + order.grandTotal);
          final totalDiscountGiven = orders.fold(0.0, (sum, order) => sum + order.discountAmount);

          // Calculate orders by status
          final statusCounts = <String, int>{};
          for (var order in orders) {
            statusCounts[order.orderStatus] = (statusCounts[order.orderStatus] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('نظرة عامة', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                _buildReportCard('إجمالي الطلبات', totalOrders.toString(), Icons.shopping_cart, Colors.blue),
                const SizedBox(height: 12),
                _buildReportCard('إجمالي المبيعات', numberFormat.format(totalSales), Icons.attach_money, Colors.green),
                 const SizedBox(height: 12),
                _buildReportCard('إجمالي الخصومات الممنوحة', numberFormat.format(totalDiscountGiven), Icons.discount, Colors.orange),
                const SizedBox(height: 24),
                Text('حالات الطلبات', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                if (statusCounts.isEmpty)
                  const Text('لا توجد طلبات لعرض الحالات.')
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5, // Adjust aspect ratio
                    ),
                    itemCount: statusCounts.length,
                    itemBuilder: (context, index) {
                      final status = statusCounts.keys.elementAt(index);
                      final count = statusCounts[status]!;
                      final style = _getStatusStyle(status);
                      return _buildStatusCard(style['text'], count.toString(), style['icon'], style['color']);
                    },
                  ),
                // TODO: Add more reports (e.g., top products, sales over time chart)
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

   Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
           mainAxisAlignment: MainAxisAlignment.center,
           crossAxisAlignment: CrossAxisAlignment.center,
          children: [
             Row(
               mainAxisSize: MainAxisSize.min,
               children: [
                 Icon(icon, size: 20, color: color),
                 const SizedBox(width: 8),
                 Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
               ],
             ),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

   // Helper to get status text, color, and icon
  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'text': 'قيد الانتظار', 'color': Colors.orange, 'icon': Icons.hourglass_empty};
      case 'processing':
        return {'text': 'قيد المعالجة', 'color': Colors.blue, 'icon': Icons.sync};
      case 'shipped':
        return {'text': 'تم الشحن', 'color': Colors.purple, 'icon': Icons.local_shipping};
      case 'delivered':
        return {'text': 'تم التوصيل', 'color': Colors.green, 'icon': Icons.check_circle_outline};
      case 'cancelled':
        return {'text': 'ملغي', 'color': Colors.red, 'icon': Icons.cancel_outlined};
      default:
        return {'text': status, 'color': Colors.grey, 'icon': Icons.help_outline};
    }
  }
}

