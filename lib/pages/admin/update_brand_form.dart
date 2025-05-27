import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UpdateBrandForm extends StatefulWidget {
  final String brandId;

  const UpdateBrandForm({super.key, required this.brandId});

  @override
  State<UpdateBrandForm> createState() => _UpdateBrandPageState();
}

class _UpdateBrandPageState extends State<UpdateBrandForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController imageController = TextEditingController();
  final TextEditingController descController = TextEditingController();
  final TextEditingController facebookController = TextEditingController();
  final TextEditingController xController = TextEditingController();
  final TextEditingController instaController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadBrandData();
  }

  Future<void> _loadBrandData() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('brands').doc(widget.brandId).get();
      final data = doc.data();
      if (data != null) {
        nameController.text = data['name'] ?? '';
        imageController.text = data['image'] ?? '';
        descController.text = data['description'] ?? '';
        facebookController.text = data['facebook'] ?? '';
        xController.text = data['x'] ?? '';
        instaController.text = data['instagram'] ?? '';
        websiteController.text = data['website'] ?? '';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateBrand() async {
    if (_formKey.currentState!.validate()) {
      try {
        await FirebaseFirestore.instance.collection('brands').doc(widget.brandId).update({
          'name': nameController.text.trim(),
          'image': imageController.text.trim(),
          'description': descController.text.trim(),
          'facebook': facebookController.text.trim(),
          'x': xController.text.trim(),
          'instagram': instaController.text.trim(),
          'website': websiteController.text.trim(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم تحديث بيانات البراند بنجاح')),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطأ: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تحديث بيانات البراند'),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.orange,
          ),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildField(nameController, 'اسم البراند', Icons.business),
                    _buildField(imageController, 'رابط الصورة', Icons.image),
                    _buildField(descController, 'الوصف', Icons.description),
                    _buildField(facebookController, 'Facebook', Icons.facebook),
                    _buildField(xController, 'X (تويتر)', Icons.alternate_email),
                    _buildField(instaController, 'Instagram', Icons.camera_alt),
                    _buildField(websiteController, 'Website', Icons.link),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: _updateBrand,
                      icon: const Icon(Icons.save),
                      label: const Text('تحديث البيانات'),
                      style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
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
    );
  }

  Widget _buildField(TextEditingController controller, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.orange),
          labelText: label,
          labelStyle: const TextStyle(color: Colors.orange),
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
}

