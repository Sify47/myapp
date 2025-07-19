import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/pages/admin/Brand%20Page/sales_report_model.dart';

class SalesReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // إنشاء تقرير مبيعات لعلامة تجارية
  Future<void> generateBrandSalesReport({
    required String brandId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final orders = await _firestore
        .collection('orders')
        .where('brandId', isEqualTo: brandId)
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
        .get();

    // حساب الإحصائيات
    double totalRevenue = 0;
    Map<String, int> ordersByStatus = {};
    Map<String, double> revenueByCategory = {};

    for (var order in orders.docs) {
      final data = order.data();
      totalRevenue += (data['grandTotal'] as num).toDouble();

      // تحديث حالة الطلب
      final status = data['orderStatus'] ?? 'unknown';
      ordersByStatus[status] = (ordersByStatus[status] ?? 0) + 1;

      // تحديث الإيرادات حسب الفئة (افترض أن لديك حقل category في OrderItem)
      final items = data['items'] as List<dynamic>;
      for (var item in items) {
        final category = item['category'] ?? 'uncategorized';
        final itemTotal = (item['price'] as num).toDouble() * (item['quantity'] as int);
        revenueByCategory[category] = (revenueByCategory[category] ?? 0) + itemTotal;
      }
    }

    // الحصول على اسم العلامة التجارية
    final brandDoc = await _firestore.collection('brands').doc(brandId).get();
    final brandName = brandDoc.data()?['name'] ?? 'Unknown Brand';

    // حفظ التقرير
    await _firestore.collection('sales_reports').add({
      'brandId': brandId,
      'brandName': brandName,
      'totalOrders': orders.size,
      'totalRevenue': totalRevenue,
      'averageOrderValue': orders.size > 0 ? totalRevenue / orders.size : 0,
      'ordersByStatus': ordersByStatus,
      'revenueByCategory': revenueByCategory,
      'periodStart': Timestamp.fromDate(startDate),
      'periodEnd': Timestamp.fromDate(endDate),
      'generatedAt': Timestamp.now(),
    });
  }

  // جلب التقارير لعلامة تجارية معينة
  Stream<List<SalesReport>> getBrandReports(String brandId) {
    return _firestore
        .collection('sales_reports')
        .where('brandId', isEqualTo: brandId)
        .orderBy('periodEnd', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalesReport.fromFirestore(doc))
            .toList());
  }

  // جلب كل التقارير (للوحة تحكم المسؤول)
  Stream<List<SalesReport>> getAllReports() {
    return _firestore
        .collection('sales_reports')
        .orderBy('periodEnd', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SalesReport.fromFirestore(doc))
            .toList());
  }
}