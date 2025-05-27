import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditOfferForm extends StatefulWidget {
  final String offerId;
  final DocumentSnapshot initialData;

  const EditOfferForm({super.key, required this.offerId, required this.initialData});

  @override
  State<EditOfferForm> createState() => _EditOfferFormState();
}

class _EditOfferFormState extends State<EditOfferForm> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _imageController;
  late TextEditingController _descriptionController;
  late TextEditingController _expiryController;
  late TextEditingController _categoryController;
  late TextEditingController _offerCodeController;

  bool _isLoading = false;
  List<String> _brands = [];
  String? _selectedBrand;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(text: widget.initialData['title']);
    _imageController = TextEditingController(text: widget.initialData['image']);
    _descriptionController = TextEditingController(text: widget.initialData['description']);
    _expiryController = TextEditingController(text: widget.initialData['expiry']);
    _categoryController = TextEditingController(text: widget.initialData['category']);
    _offerCodeController = TextEditingController(text: widget.initialData['offerCode']);
    _selectedBrand = widget.initialData['brandName'];

    fetchBrands();
  }

  Future<void> fetchBrands() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('brands').get();
      setState(() {
        _brands = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      debugPrint('Error loading brands: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageController.dispose();
    _descriptionController.dispose();
    _expiryController.dispose();
    _categoryController.dispose();
    _offerCodeController.dispose();
    super.dispose();
  }

  Future<void> _updateOffer() async {
    if (_formKey.currentState!.validate() && _selectedBrand != null) {
      setState(() => _isLoading = true);

      try {
        await FirebaseFirestore.instance.collection('offers').doc(widget.offerId).update({
          'title': _titleController.text.trim(),
          'image': _imageController.text.trim(),
          'description': _descriptionController.text.trim(),
          'expiry': _expiryController.text.trim(),
          'category': _categoryController.text.trim(),
          'offerCode': _offerCodeController.text.trim(),
          'name': _selectedBrand,
          // 'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تعديل العرض بنجاح')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ: $e')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) => value == null || value.trim().isEmpty ? 'الحقل مطلوب' : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تعديل العرض')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField('عنوان العرض', _titleController),
              _buildTextField('الوصف', _descriptionController),
              _buildTextField('رابط الصورة', _imageController),
              _buildTextField('التصنيف', _categoryController),
              _buildTextField('كود العرض', _offerCodeController),
              _buildTextField('تاريخ الانتهاء (مثال: 2025-06-01)', _expiryController),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'اختر البراند',
                ),
                value: _selectedBrand,
                items: _brands.map((name) {
                  return DropdownMenuItem(value: name, child: Text(name));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedBrand = value;
                  });
                },
                validator: (value) => value == null ? 'يجب اختيار براند' : null,
              ),
              const SizedBox(height: 20),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: _updateOffer,
                      child: const Text('تحديث العرض'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
