import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; 
import '../../models/order.dart';

class ManageOrdersPage extends StatelessWidget {
  const ManageOrdersPage({super.key});

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
      'orderStatus': newStatus,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الطلبات'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('لا توجد طلبات حالياً.'));
          }

          final orders = snapshot.data!.docs
              .map((doc) => Order.fromFirestore(doc))
              .toList();

          return ListView.builder(
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('رقم الطلب: ${order.id}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text('الحالة الحالية: ${_getStatusLabel(order.orderStatus)}'),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: order.orderStatus,
                        decoration: const InputDecoration(
                          labelText: 'تحديث الحالة',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'pending', child: Text('قيد الانتظار')),
                          DropdownMenuItem(value: 'processing', child: Text('قيد المعالجة')),
                          DropdownMenuItem(value: 'shipped', child: Text('تم الشحن')),
                          DropdownMenuItem(value: 'delivered', child: Text('تم التوصيل')),
                          DropdownMenuItem(value: 'cancelled', child: Text('ملغي')),
                        ],
                        onChanged: (newValue) {
                          if (newValue != null && newValue != order.orderStatus) {
                            _updateOrderStatus(order.id, newValue);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'قيد الانتظار';
      case 'processing':
        return 'قيد المعالجة';
      case 'shipped':
        return 'تم الشحن';
      case 'delivered':
        return 'تم التوصيل';
      case 'cancelled':
        return 'ملغي';
      default:
        return status;
    }
  }
}
