import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'update_brand_form.dart';
// import 'update_offer_page.dart'; // نموذج التعديل (لو عندك)

class UpdateBrandPage extends StatelessWidget {
  const UpdateBrandPage({super.key});

  Future<void> _deleteBrand(BuildContext context, String brandId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('تأكيد الحذف'),
            content: const Text(
              'هل أنت متأكد من حذف هذا البراند وكل العروض المرتبطة به؟',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('حذف'),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      final batch = FirebaseFirestore.instance.batch();

      // جلب العروض المرتبطة بالبراند
      final offersQuery =
          await FirebaseFirestore.instance
              .collection('offers')
              .where('brandId', isEqualTo: brandId)
              .get();

      // حذف كل العروض في الدفعة
      for (var doc in offersQuery.docs) {
        batch.delete(doc.reference);
      }

      // حذف البراند نفسه
      final brandRef = FirebaseFirestore.instance
          .collection('brands')
          .doc(brandId);
      batch.delete(brandRef);

      // تنفيذ عملية الحذف دفعة واحدة
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم حذف البراند وكل العروض المرتبطة به بنجاح'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل البراندات')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('brands').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final brands = snapshot.data!.docs;

          if (brands.isEmpty) {
            return const Center(child: Text('لا توجد براندات حالياً.'));
          }

          return ListView.builder(
            itemCount: brands.length,
            itemBuilder: (context, index) {
              final brand = brands[index];
              return ListTile(
                leading:
                    brand['image'] != null &&
                            brand['image'].toString().isNotEmpty
                        ? Image.network(
                          brand['image'],
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (context, error, stackTrace) =>
                                  const Icon(Icons.image_not_supported),
                        )
                        : const Icon(Icons.store, size: 50),
                title: Text(brand['name'] ?? 'براند بدون اسم'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () {
                        // هنا افتح صفحة تعديل البراند (لو عندك نموذج تعديل)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => UpdateBrandForm(brandId: brand.id),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteBrand(context, brand.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
