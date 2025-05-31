// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart'; // Import the Product model

class EditProductFormPage extends StatefulWidget {
  final Product product; // Product to be edited

  const EditProductFormPage({super.key, required this.product});

  @override
  State<EditProductFormPage> createState() => _EditProductFormPageState();
}

class _EditProductFormPageState extends State<EditProductFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers initialized with existing product data
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _imagesController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _categoriesController;
  late TextEditingController _attributesController;
  late TextEditingController _variantsController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;

  bool _isLoading = false;
  List<Map<String, String>> _brands = [];
  String? _selectedBrandId;
  late String _selectedStockStatus;
  late String _selectedProductStatus;

  // New boolean flags state
  late bool _isFreeShipping;
  late bool _isFeatured;
  late bool _isNew;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _fetchBrands();
  }

   @override
  void dispose() {
    // Dispose controllers
    _nameController.dispose();
    _descController.dispose();
    _imagesController.dispose();
    _priceController.dispose();
    _discountPriceController.dispose();
    _categoriesController.dispose();
    _attributesController.dispose();
    _variantsController.dispose();
    _skuController.dispose();
    _stockController.dispose();
    super.dispose();
  }


  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(text: widget.product.description);
    _imagesController = TextEditingController(text: widget.product.images.join(', '));
    _priceController = TextEditingController(text: widget.product.price.toString());
    _discountPriceController = TextEditingController(text: widget.product.discountPrice?.toString() ?? '');
    _categoriesController = TextEditingController(text: widget.product.categories.join(', '));
    _skuController = TextEditingController(text: widget.product.sku);
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _selectedBrandId = widget.product.brandId;
    _selectedStockStatus = widget.product.stockStatus;
    _selectedProductStatus = widget.product.productStatus;

    // Initialize new flags from the product object
    _isFreeShipping = widget.product.isFreeShipping;
    _isFeatured = widget.product.isFeatured;
    _isNew = widget.product.isNew;

    // Placeholders for complex fields - load actual data if available and format
    _attributesController = TextEditingController(text: widget.product.attributes.toString()); // Basic display
    _variantsController = TextEditingController(text: widget.product.variants.toString()); // Basic display
  }

  Future<void> _fetchBrands() async {
    // Original fetchBrands logic
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('brands').get();
       if (!mounted) return;
      setState(() {
        _brands = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name']?.toString() ?? 'Unnamed Brand'
        }).toList();
        // Ensure the current brand ID is valid
        if (!_brands.any((brand) => brand['id'] == _selectedBrandId)) {
          _selectedBrandId = _brands.isNotEmpty ? _brands.first['id'] : null; // Default to first or null
        }
      });
    } catch (e) {
      debugPrint('Error loading brands: $e');
       if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البراندات: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateProduct() async {
    if (_formKey.currentState!.validate() && _selectedBrandId != null) {
      setState(() => _isLoading = true);

      try {
        List<String> images = _imagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        List<String> categories = _categoriesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        // TODO: Add proper JSON parsing and validation for attributes/variants
        Map<String, dynamic> attributes = {}; // Placeholder
        List<Map<String, dynamic>> variants = []; // Placeholder

        final updatedProductData = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'images': images,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'discountPrice': _discountPriceController.text.isNotEmpty ? double.tryParse(_discountPriceController.text) : null,
          'categories': categories,
          'attributes': attributes, // Placeholder
          'variants': variants, // Placeholder
          'sku': _skuController.text.trim(),
          'stock': int.tryParse(_stockController.text) ?? 0,
          'stockStatus': _selectedStockStatus,
          'brandId': _selectedBrandId!,
          'productStatus': _selectedProductStatus,
          'updatedAt': Timestamp.now(), // Update the timestamp
          // Add the new flags to the update map
          'isFreeShipping': _isFreeShipping,
          'isFeatured': _isFeatured,
          'isNew': _isNew,
          // Keep createdAt the same
          // 'createdAt': widget.product.createdAt, // Don't need to include if not changing
        };

        await FirebaseFirestore.instance.collection('products').doc(widget.product.id).update(updatedProductData);

         if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('تم تحديث المنتج بنجاح!')]),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after successful update

      } catch (e) {
         if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء تحديث المنتج: $e'), backgroundColor: Colors.red),
        );
      } finally {
         if (mounted) {
           setState(() => _isLoading = false);
        }
      }
    }
  }

  // Original _buildField
  Widget _buildField(TextEditingController controller, String label, IconData icon, {TextInputType keyboardType = TextInputType.text, bool isRequired = true, int maxLines = 1}) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (keyboardType == TextInputType.number && value != null && value.isNotEmpty && double.tryParse(value) == null) {
             return 'الرجاء إدخال رقم صحيح';
          }
           if (keyboardType == TextInputType.number && label.contains('Stock') && value != null && value.isNotEmpty && int.tryParse(value) == null) {
             return 'الرجاء إدخال عدد صحيح';
          }
          return null;
        },
      ),
    );
  }

  // Original _buildDropdown
 Widget _buildDropdown(String label, IconData icon, List<DropdownMenuItem<String>> items, String? currentValue, ValueChanged<String?> onChanged, {bool isRequired = true}) {
     return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
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
        value: currentValue,
        items: items,
        onChanged: onChanged,
        validator: (value) => (isRequired && value == null) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  // Simple SwitchListTile using original theme context (copied from add_product_page)
  Widget _buildSwitch(String title, bool currentValue, ValueChanged<bool> onChanged) {
     return SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.teal)), // Using original style color
        value: currentValue,
        onChanged: onChanged,
        activeColor: Colors.orange, // Using original active color
        tileColor: Colors.grey[100], // Match background
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0), // Adjust padding if needed
      );
  }

  @override
  Widget build(BuildContext context) {
    // Original Scaffold and AppBar
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل: ${widget.product.name}'),
        centerTitle: true,
        flexibleSpace: Container(decoration: const BoxDecoration(color: Colors.orange)),
        elevation: 0,
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        color: Colors.grey[100],
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    const Text('تعديل تفاصيل المنتج', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
                    // Original Fields
                    _buildField(_nameController, 'اسم المنتج', Icons.label),
                    _buildField(_descController, 'الوصف', Icons.description, maxLines: 3),
                    _buildField(_imagesController, 'روابط الصور (مفصولة بفاصلة)', Icons.image, maxLines: 2),
                    _buildField(_priceController, 'السعر', Icons.attach_money, keyboardType: TextInputType.number),
                    _buildField(_discountPriceController, 'سعر الخصم (اختياري)', Icons.local_offer, keyboardType: TextInputType.number, isRequired: false),
                    _buildField(_categoriesController, 'التصنيفات (مفصولة بفاصلة)', Icons.category),
                    _buildField(_skuController, 'SKU', Icons.inventory_2),
                    _buildField(_stockController, 'الكمية بالمخزون', Icons.production_quantity_limits, keyboardType: TextInputType.number),
                     _buildDropdown('حالة المخزون', Icons.inventory, [
                      const DropdownMenuItem(value: 'in_stock', child: Text('متوفر')),
                      const DropdownMenuItem(value: 'out_of_stock', child: Text('غير متوفر')),
                      const DropdownMenuItem(value: 'low_stock', child: Text('كمية قليلة')),
                    ], _selectedStockStatus, (value) => setState(() => _selectedStockStatus = value!)),
                    _buildDropdown('البراند', Icons.business, _brands.map((brand) {
                      return DropdownMenuItem(value: brand['id'], child: Text(brand['name']!));
                    }).toList(), _selectedBrandId, (value) => setState(() => _selectedBrandId = value)),
                     _buildDropdown('حالة المنتج', Icons.toggle_on, [
                      const DropdownMenuItem(value: 'active', child: Text('نشط (معروض)')),
                      const DropdownMenuItem(value: 'inactive', child: Text('غير نشط (مخفي)')),
                      const DropdownMenuItem(value: 'draft', child: Text('مسودة')),
                    ], _selectedProductStatus, (value) => setState(() => _selectedProductStatus = value!)),

                    // Add Switches for new flags
                    const SizedBox(height: 10),
                    _buildSwitch('شحن مجاني', _isFreeShipping, (value) => setState(() => _isFreeShipping = value)),
                    _buildSwitch('منتج مميز', _isFeatured, (value) => setState(() => _isFeatured = value)),
                    _buildSwitch('منتج جديد', _isNew, (value) => setState(() => _isNew = value)),
                    const SizedBox(height: 10),

                    // TODO: Add fields for attributes and variants
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                            onPressed: _updateProduct,
                            icon: const Icon(Icons.save),
                            label: const Text('حفظ التعديلات'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal, // Original color for update button
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              textStyle: const TextStyle(fontSize: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

