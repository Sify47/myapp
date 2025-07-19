import 'package:flutter/material.dart';
import 'package:myapp/pages/admin/Brand%20Page/sales_report_model.dart';
import 'package:myapp/services/sales_report_service.dart';
import 'package:provider/provider.dart';

class BrandSalesReportScreen extends StatelessWidget {
  final String brandId;

  const BrandSalesReportScreen({super.key, required this.brandId});

  @override
  Widget build(BuildContext context) {
    final reportService = Provider.of<SalesReportService>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('تقارير المبيعات')),
      body: StreamBuilder<List<SalesReport>>(
        stream: reportService.getBrandReports(brandId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد تقارير لعرضها'));
          }

          final reports = snapshot.data!;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDateFilter(reportService, context),
              const SizedBox(height: 20),
              _buildSummaryCard(context, reports.first),
              const SizedBox(height: 20),
              _buildOrdersByStatus(reports.first),
              const SizedBox(height: 20),
              _buildRevenueByCategory(reports.first),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generateReport(context),
        child: const Icon(Icons.refresh),
      ),
    );
  }

  Widget _buildDateFilter(SalesReportService service, BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () => _selectDateRange(context, service),
            child: const Text('اختر الفترة الزمنية'),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(BuildContext context, SalesReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              report.brandName,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Divider(),
            _buildStatItem('إجمالي الطلبات', report.totalOrders.toString()),
            _buildStatItem(
              'إجمالي الإيرادات',
              '${report.totalRevenue.toStringAsFixed(2)} ج.م',
            ),
            _buildStatItem(
              'متوسط قيمة الطلب',
              '${report.averageOrderValue.toStringAsFixed(2)} ج.م',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildOrdersByStatus(SalesReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'توزيع الطلبات حسب الحالة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...report.ordersByStatus.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text('${entry.key}: ${entry.value} طلب'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueByCategory(SalesReport report) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'الإيرادات حسب الفئة',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            ...report.revenueByCategory.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  '${entry.key}: ${entry.value.toStringAsFixed(2)} ج.م',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange(
    BuildContext context,
    SalesReportService service,
  ) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      await service.generateBrandSalesReport(
        brandId: brandId,
        startDate: picked.start,
        endDate: picked.end,
      );
    }
  }

  Future<void> _generateReport(BuildContext context) async {
    final service = Provider.of<SalesReportService>(context, listen: false);
    await service.generateBrandSalesReport(
      brandId: brandId,
      startDate: DateTime.now().subtract(const Duration(days: 30)),
      endDate: DateTime.now(),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم تحديث التقرير بنجاح')));
  }
}
