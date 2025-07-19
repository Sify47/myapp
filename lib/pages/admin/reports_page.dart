import 'dart:math';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/order.dart';
import '../../services/order_service.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    final orderService = Provider.of<OrderService>(context);
    final numberFormat = NumberFormat.currency(locale: 'ar_EG', symbol: 'ج.م');

    return Scaffold(
      appBar: AppBar(
        title: const Text('التقارير الأساسية'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.date_range),
            tooltip: 'تحديد الفترة',
            onPressed: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2025),
                lastDate: DateTime.now(),
                // locale: const Locale('ar'),
              );
              if (picked != null) {
                setState(() {
                  selectedDateRange = picked;
                });
              }
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Order>>(
        stream: () {
          var query = FirebaseFirestore.instance
              .collection('orders')
              .orderBy('createdAt', descending: true);

          if (selectedDateRange != null) {
            query = query
                .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.start))
                .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(selectedDateRange!.end));
          }

          return query.snapshots().map(
                (snapshot) => snapshot.docs.map((doc) => Order.fromFirestore(doc)).toList(),
              );
        }(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في تحميل بيانات التقارير: ${snapshot.error}',
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد بيانات لعرض التقارير.'));
          }

          final orders = snapshot.data!;
          final totalOrders = orders.length;
          final totalSales = orders.fold(0.0, (sum, order) => sum + order.grandTotal);
          final totalDiscountGiven = orders.fold(0.0, (sum, order) => sum + order.discountAmount);

          final statusCounts = <String, int>{};
          for (var order in orders) {
            statusCounts[order.orderStatus] = (statusCounts[order.orderStatus] ?? 0) + 1;
          }

          // حساب المبيعات اليومية للرسم البياني
          final salesPerDay = <DateTime, double>{};
for (var order in orders) {
  // ignore: unnecessary_type_check
  final createdAtDate = (order.createdAt is Timestamp)
      ? (order.createdAt).toDate()
      : order.createdAt as DateTime;

  final date = DateTime(createdAtDate.year, createdAtDate.month, createdAtDate.day);
  salesPerDay[date] = (salesPerDay[date] ?? 0) + order.grandTotal;
}

          final sortedDates = salesPerDay.keys.toList()..sort();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (selectedDateRange != null) ...[
                  Text(
                    'الفترة المختارة: '
                    '${DateFormat.yMd().format(selectedDateRange!.start)} - '
                    '${DateFormat.yMd().format(selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 12),
                ],
                Text(
                  'نظرة عامة',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _buildReportCard('إجمالي الطلبات', totalOrders.toString(), Icons.shopping_cart, const Color(0xFF3366FF)),
                const SizedBox(height: 12),
                _buildReportCard('إجمالي المبيعات', numberFormat.format(totalSales), Icons.attach_money, Colors.green),
                const SizedBox(height: 12),
                _buildReportCard('إجمالي الخصومات الممنوحة', numberFormat.format(totalDiscountGiven), Icons.discount, const Color(0xFF3366FF)),
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
                      childAspectRatio: 2.5,
                    ),
                    itemCount: statusCounts.length,
                    itemBuilder: (context, index) {
                      final status = statusCounts.keys.elementAt(index);
                      final count = statusCounts[status]!;
                      final style = _getStatusStyle(status);
                      return _buildStatusCard(style['text'], count.toString(), style['icon'], style['color']);
                    },
                  ),
                const SizedBox(height: 24),
                Text('المبيعات اليومية', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),

// بهذا الكود المحسن:
if (salesPerDay.isEmpty)
  const Center(child: Text('لا توجد بيانات لرسم المبيعات.'))
else
  SizedBox(
    height: 300, // زيادة الارتفاع
    child: Padding(
      padding: const EdgeInsets.only(right: 8.0, left: 8.0, top: 16.0, bottom: 24.0),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (sortedDates.length - 1).toDouble(),
          minY: 0,
          maxY: salesPerDay.values.reduce(max) * 1.1, // زيادة المساحة أعلى الرسم
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false, // إخفاء الخطوط الشبكية العمودية
          ),
          titlesData: FlTitlesData(
            rightTitles: AxisTitles( // إضافة التسميات على اليمين
              sideTitles: SideTitles(showTitles: true),
            ),
            topTitles: AxisTitles( // إخفاء التسميات العلوية
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22, // زيادة المساحة المخصصة للتسميات
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= sortedDates.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Transform.rotate(
                      angle: -0.4, // إمالة النص بزاوية
                      child: Text(
                        DateFormat.Md().format(sortedDates[index]),
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                        ),
                        overflow: TextOverflow.visible,
                      ),
                    ),
                  );
                },
                interval: _calculateInterval(sortedDates.length), // حساب الفاصل تلقائيًا
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40, // زيادة المساحة المخصصة للتسميات
                interval: _calculateYInterval(salesPerDay.values.reduce(max)),
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(fontSize: 10),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              isCurved: true,
              color: Colors.blue,
              barWidth: 3,
              spots: List.generate(sortedDates.length, (index) {
                final date = sortedDates[index];
                return FlSpot(index.toDouble(), salesPerDay[date]!);
              }),
              dotData: FlDotData(show: false), // إخفاء النقاط
              belowBarData: BarAreaData( // تظليل المنطقة تحت الخط
                show: true,
                color: Colors.blue.withOpacity(0.1),
              ),
            ),
          ],
          borderData: FlBorderData(show: false),
        ),
      ),
    ),
  ),

// أضف هذه الدوال المساعدة خارج دالة build:
             ],
            ),
          );
        },
      ),
    );
  }
  double _calculateInterval(int dataLength) {
  if (dataLength <= 7) return 1;
  if (dataLength <= 14) return 2;
  if (dataLength <= 30) return 5;
  return 7;
}

double _calculateYInterval(double maxValue) {
  if (maxValue <= 1000) return 200;
  if (maxValue <= 5000) return 500;
  return 1000;
} 

  Widget _buildReportCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
          children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontSize: 14, color: color, fontWeight: FontWeight.w500)),
            ]),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusStyle(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return {'text': 'قيد الانتظار', 'color': const Color(0xFF3366FF), 'icon': Icons.hourglass_empty};
      case 'processing':
        return {'text': 'قيد المعالجة', 'color': const Color(0xFF3366FF), 'icon': Icons.sync};
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
