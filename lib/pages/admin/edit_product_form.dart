import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart'; // Import the Product model
import 'package:provider/provider.dart';
import '../../auth_model.dart';

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
  late TextEditingController _skuController;
  late TextEditingController _stockController;

  // Attributes and Tags controllers
  late List<Map<String, dynamic>> _attributes;
  final TextEditingController _attributeNameController =
      TextEditingController();
  final TextEditingController _attributeValueController =
      TextEditingController();
  List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tempValues = [];

  bool _isLoading = false;
  late String _selectedStockStatus;
  late String _selectedProductStatus;

  // New boolean flags state
  late bool _isFeatured;
  late bool _isNew;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
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
    _skuController.dispose();
    _stockController.dispose();
    _attributeNameController.dispose();
    _attributeValueController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(text: widget.product.description);
    _imagesController = TextEditingController(
      text: widget.product.images.join(', '),
    );
    _priceController = TextEditingController(
      text: widget.product.price.toString(),
    );
    _discountPriceController = TextEditingController(
      text: widget.product.discountPrice?.toString() ?? '',
    );
    _categoriesController = TextEditingController(
      text: widget.product.categories.join(', '),
    );
    _skuController = TextEditingController(text: widget.product.sku);
    _stockController = TextEditingController(
      text: widget.product.stock.toString(),
    );
    _selectedStockStatus = widget.product.stockStatus;
    _selectedProductStatus = widget.product.productStatus;

    // Initialize attributes and tags
    _attributes = List<Map<String, dynamic>>.from(widget.product.attributes);
    _tags = List<String>.from(widget.product.tags);

    // Initialize flags
    _isFeatured = widget.product.isFeatured;
    _isNew = widget.product.isNew;
  }

  Future<void> _updateProduct() async {
    final auth = Provider.of<AuthModel>(context, listen: false);
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<String> images =
            _imagesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();
        List<String> categories =
            _categoriesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

        final updatedProductData = {
          'name': _nameController.text.trim(),
          'description': _descController.text.trim(),
          'images': images,
          'price': double.tryParse(_priceController.text) ?? 0.0,
          'discountPrice':
              _discountPriceController.text.isNotEmpty
                  ? double.tryParse(_discountPriceController.text)
                  : null,
          'categories': categories,
          'attributes': _attributes,
          'sku': _skuController.text.trim(),
          'stock': int.tryParse(_stockController.text) ?? 0,
          'stockStatus': _selectedStockStatus,
          'productStatus': _selectedProductStatus,
          'updatedAt': Timestamp.now(),
          'isFeatured': _isFeatured,
          'isNew': _isNew,
          'tags': _tags,
        };

        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product.id)
            .update(updatedProductData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تم تحديث المنتج بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back after successful update
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء تحديث المنتج: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          "العلامات (Tags)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children:
              _tags.map((tag) {
                return Chip(
                  label: Text(tag),
                  backgroundColor: Color(0xFF3366FF),
                  deleteIcon: const Icon(Icons.close),
                  onDeleted: () => setState(() => _tags.remove(tag)),
                );
              }).toList(),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(hintText: 'أدخل tag'),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                final tag = _tagController.text.trim();
                if (tag.isNotEmpty && !_tags.contains(tag)) {
                  setState(() {
                    _tags.add(tag);
                    _tagController.clear();
                  });
                }
              },
              child: const Text("إضافة"),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildAdvancedAttributesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 20),
        const Text(
          'السمات (Attributes)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.teal,
          ),
        ),
        const SizedBox(height: 10),

        // عرض السمات كبطاقات
        ..._attributes.map((attr) {
          return Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          attr['name'] ?? 'No name',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _attributes.remove(attr);
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children:
                        (attr['values'] as List<dynamic>).map((value) {
                          return Chip(
                            label: Text(value.toString()),
                            onDeleted: () {
                              setState(() {
                                attr['values'].remove(value);
                                if (attr['values'].isEmpty) {
                                  _attributes.remove(attr);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
          );
        }),

        const Divider(height: 30),

        // إضافة سمة جديدة
        const Text(
          'إضافة سمة جديدة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _attributeNameController,
          decoration: const InputDecoration(
            labelText: 'اسم السمة',
            hintText: 'مثال: الحجم، اللون',
            border: OutlineInputBorder(),
          ),
        ),

        const SizedBox(height: 10),

        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _attributeValueController,
                decoration: const InputDecoration(
                  labelText: 'قيمة',
                  hintText: 'مثال: أحمر',
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (value) => _addTempValue(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addTempValue,
              child: const Text('إضافة'),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // عرض القيم المضافة مؤقتًا قبل حفظ السمة
        if (_tempValues.isNotEmpty)
          Wrap(
            spacing: 6,
            children:
                _tempValues.map((value) {
                  return Chip(
                    label: Text(value),
                    onDeleted: () {
                      setState(() {
                        _tempValues.remove(value);
                      });
                    },
                  );
                }).toList(),
          ),

        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('حفظ السمة'),
          onPressed: () {
            final name = _attributeNameController.text.trim();
            if (name.isNotEmpty && _tempValues.isNotEmpty) {
              setState(() {
                final existingAttr = _attributes.firstWhere(
                  (attr) => attr['name'] == name,
                  orElse: () => {},
                );

                if (existingAttr.isNotEmpty) {
                  for (var val in _tempValues) {
                    if (!existingAttr['values'].contains(val)) {
                      existingAttr['values'].add(val);
                    }
                  }
                } else {
                  _attributes.add({
                    'name': name,
                    'values': [..._tempValues],
                  });
                }

                _attributeNameController.clear();
                _attributeValueController.clear();
                _tempValues.clear();
              });
            }
          },
        ),
      ],
    );
  }

  void _addTempValue() {
    final value = _attributeValueController.text.trim();
    if (value.isNotEmpty && !_tempValues.contains(value)) {
      setState(() {
        _tempValues.add(value);
        _attributeValueController.clear();
      });
    }
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
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
          if (isRequired && (value == null || value.trim().isEmpty)) {
            return 'هذا الحقل مطلوب';
          }
          if (keyboardType == TextInputType.number &&
              value != null &&
              value.isNotEmpty &&
              double.tryParse(value) == null) {
            return 'الرجاء إدخال رقم صحيح';
          }
          if (keyboardType == TextInputType.number &&
              label.contains('Stock') &&
              value != null &&
              value.isNotEmpty &&
              int.tryParse(value) == null) {
            return 'الرجاء إدخال عدد صحيح';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<DropdownMenuItem<String>> items,
    String? currentValue,
    ValueChanged<String?> onChanged, {
    bool isRequired = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
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
        value: currentValue,
        items: items,
        onChanged: onChanged,
        validator:
            (value) => (isRequired && value == null) ? 'هذا الحقل مطلوب' : null,
      ),
    );
  }

  Widget _buildSwitch(
    String title,
    bool currentValue,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(color: Colors.teal)),
      value: currentValue,
      onChanged: onChanged,
      activeColor: Color(0xFF3366FF),
      tileColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل: ${widget.product.name}'),
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
                      'تعديل تفاصيل المنتج',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildField(_nameController, 'اسم المنتج', Icons.label),
                    _buildField(
                      _descController,
                      'الوصف',
                      Icons.description,
                      maxLines: 3,
                    ),
                    _buildField(
                      _imagesController,
                      'روابط الصور (مفصولة بفاصلة)',
                      Icons.image,
                      maxLines: 2,
                    ),
                    _buildField(
                      _priceController,
                      'السعر',
                      Icons.attach_money,
                      keyboardType: TextInputType.number,
                    ),
                    _buildField(
                      _discountPriceController,
                      'سعر الخصم (اختياري)',
                      Icons.local_offer,
                      keyboardType: TextInputType.number,
                      isRequired: false,
                    ),
                    _buildField(
                      _categoriesController,
                      'التصنيفات (مفصولة بفاصلة)',
                      Icons.category,
                    ),
                    _buildField(_skuController, 'SKU', Icons.inventory_2),
                    _buildField(
                      _stockController,
                      'الكمية بالمخزون',
                      Icons.production_quantity_limits,
                      keyboardType: TextInputType.number,
                    ),
                    _buildDropdown(
                      'حالة المخزون',
                      Icons.inventory,
                      [
                        const DropdownMenuItem(
                          value: 'in_stock',
                          child: Text('متوفر'),
                        ),
                        const DropdownMenuItem(
                          value: 'out_of_stock',
                          child: Text('غير متوفر'),
                        ),
                        const DropdownMenuItem(
                          value: 'low_stock',
                          child: Text('كمية قليلة'),
                        ),
                      ],
                      _selectedStockStatus,
                      (value) => setState(() => _selectedStockStatus = value!),
                    ),
                    _buildDropdown(
                      'حالة المنتج',
                      Icons.toggle_on,
                      [
                        const DropdownMenuItem(
                          value: 'active',
                          child: Text('نشط (معروض)'),
                        ),
                        const DropdownMenuItem(
                          value: 'inactive',
                          child: Text('غير نشط (مخفي)'),
                        ),
                        const DropdownMenuItem(
                          value: 'draft',
                          child: Text('مسودة'),
                        ),
                      ],
                      _selectedProductStatus,
                      (value) =>
                          setState(() => _selectedProductStatus = value!),
                    ),

                    const SizedBox(height: 10),
                    _buildSwitch(
                      'منتج مميز',
                      _isFeatured,
                      (value) => setState(() => _isFeatured = value),
                    ),
                    _buildSwitch(
                      'منتج جديد',
                      _isNew,
                      (value) => setState(() => _isNew = value),
                    ),
                    const SizedBox(height: 10),
                    buildAdvancedAttributesSection(),
                    const SizedBox(height: 10),
                    buildTagsSection(),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                          onPressed: _updateProduct,
                          icon: const Icon(Icons.save),
                          label: const Text('حفظ التعديلات'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
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
