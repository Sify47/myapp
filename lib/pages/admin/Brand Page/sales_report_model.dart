import 'package:cloud_firestore/cloud_firestore.dart';

class SalesReport {
  final String brandId;
  final String brandName;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final Map<String, int> ordersByStatus;
  final Map<String, double> revenueByCategory;
  final Timestamp periodStart;
  final Timestamp periodEnd;

  SalesReport({
    required this.brandId,
    required this.brandName,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.ordersByStatus,
    required this.revenueByCategory,
    required this.periodStart,
    required this.periodEnd,
  });

  factory SalesReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SalesReport(
      brandId: data['brandId'],
      brandName: data['brandName'],
      totalOrders: data['totalOrders'],
      totalRevenue: (data['totalRevenue'] as num).toDouble(),
      averageOrderValue: (data['averageOrderValue'] as num).toDouble(),
      ordersByStatus: Map<String, int>.from(data['ordersByStatus']),
      revenueByCategory: Map<String, double>.from(data['revenueByCategory']),
      periodStart: data['periodStart'],
      periodEnd: data['periodEnd'],
    );
  }
}