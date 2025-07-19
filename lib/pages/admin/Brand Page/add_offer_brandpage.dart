import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../../auth_model.dart';

class AddOfferBrandPage extends StatefulWidget {
  const AddOfferBrandPage({super.key});

  @override
  State<AddOfferBrandPage> createState() => _AddOfferBrandPageState();
}

class _AddOfferBrandPageState extends State<AddOfferBrandPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imageController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _offerCodeController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  bool _isLoading = false;
  // List<String> _brands = [];
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();
    // fetchBrands();
  }

  Future<void> _submitOffer() async {
    final auth = Provider.of<AuthModel>(context, listen: false);
    if (_formKey.currentState!.validate() && _selectedBrand != auth.brandId) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance.collection('offers').add({
          'title': _titleController.text.trim(),
          'description': _descController.text.trim(),
          'image': _imageController.text.trim(),
          'category': _categoryController.text.trim(),
          'offerCode': _offerCodeController.text.trim(),
          'expiry': _expiryController.text.trim(),
          'brand': auth.brandname,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تمت إضافة العرض بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedBrand = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Color(0xFF3366FF)),
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF3366FF)),
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.teal, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'هذا الحقل مطلوب';
          }
          return null;
        },
      ),
    );
  }

  // Widget _buildDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 20),
  //     child: DropdownButtonFormField<String>(
  //       decoration: InputDecoration(
  //         prefixIcon: const Icon(Icons.business, color: Color(0xFF3366FF)),
  //         labelText: 'اختر البراند',
  //         labelStyle: const TextStyle(color: Color(0xFF3366FF)),
  //         filled: true,
  //         fillColor: Colors.grey[100],
  //         border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
  //         focusedBorder: OutlineInputBorder(
  //           borderSide: const BorderSide(color: Colors.teal, width: 2),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //       ),
  //       value: _selectedBrand,
  //       items: _brands.map((name) {
  //         return DropdownMenuItem(value: name, child: Text(name));
  //       }).toList(),
  //       onChanged: (value) {
  //         setState(() {
  //           _selectedBrand = value;
  //         });
  //       },
  //       validator: (value) => value == null ? 'يجب اختيار براند' : null,
  //     ),
  //   );
  // }

  @override
  Widget build(BuildContext context) {
    // final auth = Provider.of<AuthModel>(context, listen: false);
    // _selectedBrand = auth.brandId;
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة عرض جديد'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(color: Color(0xFF3366FF)),
        ),
        elevation: 0,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text(
                      'تفاصيل العرض',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildField(_titleController, 'عنوان العرض', Icons.title),
                    _buildField(_descController, 'الوصف', Icons.description),
                    _buildField(_imageController, 'رابط الصورة', Icons.image),
                    _buildField(_categoryController, 'التصنيف', Icons.category),
                    _buildField(_offerCodeController, 'كود العرض', Icons.code),
                    _buildField(
                      _expiryController,
                      'تاريخ الانتهاء (مثال: 2025-06-01)',
                      Icons.date_range,
                      keyboardType: TextInputType.datetime,
                    ),

                    // _selectedBrand = auth.brandid,
                    // _buildDropdown(),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                          onPressed: _submitOffer,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة العرض'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF3366FF),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            textStyle: const TextStyle(fontSize: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
