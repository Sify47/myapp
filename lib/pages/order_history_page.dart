import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:myapp/pages/or.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> {
  final User? user = FirebaseAuth.instance.currentUser;
  String _selectedFilter = 'الكل';

  final List<String> _filters = [
    'الكل',
    'pending',
    'processing',
    'delivered',
    'cancelled',
  ];

  // دالة لترجمة حالة الطلب
  // String _getStatusArabic(String status) {
  //   switch (status) {
  //     case 'pending': return 'قيد الانتظار';
  //     case 'processing': return 'قيد التجهيز';
  //     case 'delivered': return 'تم التوصيل';
  //     case 'cancelled': return 'ملغي';
  //     default: return status;
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('طلباتي'),
        centerTitle: true,
        backgroundColor: const Color(0xFF3366FF),
      ),
      body: Column(
        children: [
          // فلتر الطلبات
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            color: Colors.grey[100],
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _filters.map((filter) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(
                        filter == 'الكل' ? 'الكل' : filter,
                      ),
                      selected: _selectedFilter == filter,
                      onSelected: (selected) {
                        setState(() {
                          _selectedFilter = selected ? filter : 'الكل';
                        });
                      },
                      backgroundColor: Colors.white,
                      selectedColor: const Color(0xFF3366FF),
                      labelStyle: TextStyle(
                        color: _selectedFilter == filter ? Colors.white : Colors.black,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // قائمة الطلبات
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
              builder: (context, snapshot) {
                // إضافة طباعة للأخطاء
                if (snapshot.hasError) {
                  debugPrint('Error: ${snapshot.error}');
                  return Center(
                    child: Text('حدث خطأ: ${snapshot.error}'),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildEmptyState();
                }

                final orders = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;
                    
                    return _buildOrderCard(data, order.id, order);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_bag_outlined,
            size: 60,
            color: Colors.grey,
          ),
          const SizedBox(height: 16),
          const Text(
            'لا توجد طلبات بعد',
            style: TextStyle(fontSize: 18, color: Colors.grey),
          ),
          Text(
            _selectedFilter == 'الكل' 
              ? 'قم بتجربة منتجاتنا واطلب الآن!'
              : 'لا توجد طلبات بحالة "$_selectedFilter"',
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .where('userId', isEqualTo: user?.uid)
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'الكل') {
      query = query.where('orderStatus', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  Widget _buildOrderCard(Map<String, dynamic> data, String orderId, DocumentSnapshot order) {
    final date = (data['createdAt'] as Timestamp).toDate();
    final formattedDate = DateFormat('yyyy/MM/dd - hh:mm a').format(date);
    final total = data['grandTotal'] ?? data['total'] ?? 0.0;
    final status = data['orderStatus'] ?? 'pending';
    final items = data['items'] as List<dynamic>? ?? [];

    Color statusColor = Colors.orange;
    if (status == 'delivered') statusColor = Colors.green;
    if (status == 'cancelled') statusColor = Colors.red;
    if (status == 'processing') statusColor = Colors.blue;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // رقم الطلب والتاريخ
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'طلب #${orderId.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  formattedDate,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // المنتجات
            if (items.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${items.length} منتج',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 50,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index] as Map<String, dynamic>;
                        final imageUrl = item['productImageUrl'] ?? 
                                        item['image'] ?? 
                                        item['imageUrl'] ?? 
                                        '';
                        
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                            image: imageUrl.isNotEmpty 
                                ? DecorationImage(
                                    image: NetworkImage(imageUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: imageUrl.isEmpty
                              ? const Icon(Icons.image, color: Colors.grey, size: 24)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 12),

            // السعر والحالة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${total.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    (status),
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // أزرار الإجراءات
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _navigateToOrderDetails(order);
                    },
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('تفاصيل الطلب'),
                  ),
                ),
                const SizedBox(width: 8),
                if (status != 'cancelled' && status != 'delivered')
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _cancelOrder(orderId),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('إلغاء الطلب'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToOrderDetails(DocumentSnapshot order) {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderDetailsPage(orderDoc: order),
        ),
      );
    } catch (e) {
      debugPrint('Error navigating to order details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ في فتح تفاصيل الطلب')),
      );
    }
  }

  void _cancelOrder(String orderId) {
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
                    .update({'orderStatus': 'cancelled'});
                
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
}