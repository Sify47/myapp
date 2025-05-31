import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // For date formatting
import '../../models/coupon.dart';
import '../../services/coupon_service.dart';
import 'edit_coupon_form.dart'; // To navigate to edit page
import 'add_coupon_page.dart';

class ListCouponsPage extends StatelessWidget {
  const ListCouponsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final couponService = Provider.of<CouponService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('إدارة الكوبونات'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Coupon>>(
        stream: couponService.getAllCouponsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('لا توجد كوبونات حالياً.'));
          }

          final coupons = snapshot.data!;

          return ListView.builder(
            itemCount: coupons.length,
            itemBuilder: (context, index) {
              final coupon = coupons[index];
              final expiryFormatted = DateFormat('yyyy-MM-dd').format(coupon.expiryDate.toDate());
              final isValid = coupon.isValid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  title: Text(coupon.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(coupon.description),
                      Text('النوع: ${coupon.discountType == 'percentage' ? 'نسبة' : 'مبلغ ثابت'} - القيمة: ${coupon.discountValue}${coupon.discountType == 'percentage' ? '%' : ' ر.س'}'),
                      Text('الانتهاء: $expiryFormatted - فعال: ${coupon.isActive ? 'نعم' : 'لا'}'),
                      Text('الاستخدام: ${coupon.currentUsage}/${coupon.usageLimit ?? 'غير محدود'}'),
                      if (!isValid)
                        const Text('غير صالح حالياً', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        tooltip: 'تعديل',
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EditCouponForm(coupon: coupon)),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        tooltip: 'حذف',
                        onPressed: () async {
                          // Show confirmation dialog before deleting
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('تأكيد الحذف'),
                              content: Text('هل أنت متأكد من رغبتك في حذف الكوبون ${coupon.code}؟'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('إلغاء'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('حذف', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await couponService.deleteCoupon(coupon.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('تم حذف الكوبون بنجاح'), backgroundColor: Colors.green),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('فشل حذف الكوبون: $e'), backgroundColor: Colors.red),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                  isThreeLine: true, // Adjust based on content length
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddCouponPage()),
          );
        },
        tooltip: 'إضافة كوبون جديد',
        child: const Icon(Icons.add),
      ),
    );
  }
}

