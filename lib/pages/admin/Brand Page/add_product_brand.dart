import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/product.dart';
import '../../../auth_model.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController =
      TextEditingController();
  final TextEditingController _categoriesController = TextEditingController();
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();
  final List<Map<String, dynamic>> _attributes = [];
  final TextEditingController _attributeNameController =
      TextEditingController();
  final TextEditingController _attributeValueController =
      TextEditingController();
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tempValues = [];

  List<File> _selectedImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  String _selectedStockStatus = 'in_stock';
  String _selectedProductStatus = 'active';
  bool _isFeatured = false;
  bool _isNew = true;

  List<String> _categories = []; // لتخزين الأقسام من Firebase
  String? _selectedCategory; // القسم المختار
  bool _isLoadingCategories = false; // حالة التحميل

  final Color _primaryColor = const Color(0xFF3366FF); // أخضر هادئ
  final Color _secondaryColor = const Color(0xFF2196F3); // أزرق هادئ
  // final Color _accentColor = const Color(0xFFFF9800); // برتقالي هادئ
  // final Color _errorColor = const Color(0xFFF44336); // أحمر هادئ
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);

    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection('categories')
              .orderBy('name')
              .get();

      setState(() {
        _categories =
            snapshot.docs.map((doc) => doc['name'].toString()).toList();

        if (_categories.isNotEmpty) {
          _selectedCategory = _categories.first;
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading sections: $e')));
    } finally {
      setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImages() async {
    try {
      final pickedFiles = await ImagePicker().pickMultiImage(
        imageQuality: 80,
        maxWidth: 800,
      );

      if (pickedFiles.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((file) => File(file.path)));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('An error occurred while selecting images: $e')));
    }
  }

  Future<List<String>> _uploadImages() async {
    List<String> imageUrls = [];
    setState(() => _isUploadingImages = true);

    try {
      for (final image in _selectedImages) {
        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/db1bvjebn/image/upload?upload_preset=Dolabk',
        );

        var request = http.MultipartRequest('POST', url);
        request.files.add(
          await http.MultipartFile.fromPath('file', image.path),
        );

        var response = await request.send();
        var jsonData = await response.stream.bytesToString();
        var json = jsonDecode(jsonData);

        if (response.statusCode == 200) {
          imageUrls.add(json['secure_url']);
        } else {
          debugPrint('Cloudinary Error: ${json['error']?.toString()}');
          throw Exception('Failed to upload image: ${json['error']}');
        }
      }
    } catch (e) {
      debugPrint('Image Upload Error: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Image Upload Error: $e')));
      return []; // إرجاع قائمة فارغة في حالة الخطأ
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return imageUrls;
  }

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _submitProduct() async {
    final auth = Provider.of<AuthModel>(context, listen: false);

    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<String> imageUrls = await _uploadImages();

        if (imageUrls.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فشل في رفع الصور، يرجى المحاولة مرة أخرى'),
            ),
          );
          return;
        }

        List<String> categories =
            _categoriesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList();

        final newProduct = Product(
          id: '',
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          images: imageUrls,
          price: double.tryParse(_priceController.text) ?? 0.0,
          discountPrice:
              _discountPriceController.text.isNotEmpty
                  ? double.tryParse(_discountPriceController.text)
                  : null,
          categories: _selectedCategory != null ? [_selectedCategory!] : [],
          attributes: _attributes,
          sku: _skuController.text.trim(),
          stock: int.tryParse(_stockController.text) ?? 0,
          stockStatus: _selectedStockStatus,
          brandId: auth.brandId!,
          productStatus: _selectedProductStatus,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          isFeatured: _isFeatured,
          isNew: _isNew,
          tags: _tags,
          soldcount: 0,
        );

        await FirebaseFirestore.instance
            .collection('products')
            .add(newProduct.toFirestore());

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('تمت إضافة المنتج بنجاح!'),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedImages.clear();
          _selectedStockStatus = 'in_stock';
          _selectedProductStatus = 'active';
          _isFeatured = false;
          _isNew = true;
          _categoriesController.clear();
          _attributes.clear();
          _tags.clear();
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ أثناء إضافة المنتج: $e'),
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

  Widget _buildDropdownCat() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items:
          _categories.map((String category) {
            return DropdownMenuItem<String>(
              value: category,
              child: Text(category, style: TextStyle(color: _textColor)),
            );
          }).toList(),
      onChanged: (String? newValue) {
        setState(() {
          _selectedCategory = newValue;
        });
      },
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: 'التصنيف',
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(Icons.category, color: _secondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _secondaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      validator: (value) => value == null ? 'يجب اختيار تصنيف' : null,
      isExpanded: true,
      hint:
          _isLoadingCategories
              ? const Text(
                'جاري تحميل الأقسام...',
                style: TextStyle(color: Colors.grey),
              )
              : const Text('اختر تصنيف', style: TextStyle(color: Colors.grey)),
    );
  }

  //   Widget _buildCategoryDropdown() {
  //   return Padding(
  //     padding: const EdgeInsets.only(bottom: 16),
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         Padding(
  //           padding: const EdgeInsets.only(bottom: 8),
  //           child: Text(
  //             'القسم',
  //             style: TextStyle(
  //               color: Colors.grey[700],
  //               fontWeight: FontWeight.w500,
  //             ),
  //           ),
  //         ),
  //         Container(
  //           decoration: BoxDecoration(
  //             color: Colors.grey[50],
  //             borderRadius: BorderRadius.circular(10),
  //           ),
  //           padding: const EdgeInsets.symmetric(horizontal: 12),
  //           child: DropdownButton<String>(
  //             value: _selectedCategory,
  //             isExpanded: true,
  //             underline: const SizedBox(), // إزالة الخط السفلي
  //             items: _categories.map((String category) {
  //               return DropdownMenuItem<String>(
  //                 value: category,
  //                 child: Text(category),
  //               );
  //             }).toList(),
  //             onChanged: (String? newValue) {
  //               setState(() {
  //                 _selectedCategory = newValue;
  //               });
  //             },
  //             hint: _isLoadingCategories
  //                 ? const Text('جاري تحميل الأقسام...')
  //                 : const Text('اختر القسم'),
  //           ),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  Widget _buildImageUploadSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'صور المنتج',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (_selectedImages.isNotEmpty)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _selectedImages.length,
              itemBuilder: (ctx, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          _selectedImages[index],
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 20,
                          ),
                          onPressed:
                              () => setState(
                                () => _selectedImages.removeAt(index),
                              ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('اختر الصور'),
          onPressed: _pickImages,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),

        if (_isUploadingImages)
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool isRequired = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        hintStyle: TextStyle(color: Colors.grey[400]),
        prefixIcon: Icon(icon, color: _secondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _secondaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
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
        return null;
      },
    );
  }

  Widget _buildDropdown(
    String label,
    IconData icon,
    List<DropdownMenuItem<String>> items,
    String? currentValue,
    ValueChanged<String?> onChanged,
  ) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      items: items,
      onChanged: onChanged,
      style: TextStyle(color: _textColor),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600]),
        prefixIcon: Icon(icon, color: _secondaryColor),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: _secondaryColor, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      ),
      validator: (value) => value == null ? 'هذا الحقل مطلوب' : null,
      isExpanded: true,
    );
  }

  Widget _buildSwitch(
    String title,
    bool currentValue,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(color: _textColor)),
      value: currentValue,
      onChanged: onChanged,
      activeColor: _primaryColor,
      inactiveThumbColor: Colors.grey[300],
      inactiveTrackColor: Colors.grey[200],
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                          setState(() => _attributes.remove(attr));
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
        if (_tempValues.isNotEmpty)
          Wrap(
            spacing: 6,
            children:
                _tempValues.map((value) {
                  return Chip(
                    label: Text(value),
                    onDeleted: () {
                      setState(() => _tempValues.remove(value));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'إضافة منتج جديد',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: _secondaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        color: Colors.grey[50],
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: _cardColor,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Center(
                          child: Text(
                            'تفاصيل المنتج',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _secondaryColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // اسم المنتج
                        _buildField(_nameController, 'اسم المنتج', Icons.label),
                        const SizedBox(height: 16),

                        // الوصف
                        _buildField(
                          _descController,
                          'الوصف',
                          Icons.description,
                          maxLines: 3,
                        ),
                        const SizedBox(height: 16),

                        // صور المنتج
                        _buildImageUploadSection(),
                        const SizedBox(height: 24),

                        // السعر وسعر الخصم في صف واحد
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                _priceController,
                                'السعر',
                                Icons.attach_money,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                _discountPriceController,
                                'سعر الخصم',
                                Icons.local_offer,
                                keyboardType: TextInputType.number,
                                isRequired: false,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // التصنيف وSKU في صف واحد
                        Row(
                          children: [
                            Expanded(child: _buildDropdownCat()),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                _skuController,
                                'SKU',
                                Icons.inventory_2,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // الكمية وحالة المخزون في صف واحد
                        Row(
                          children: [
                            Expanded(
                              child: _buildField(
                                _stockController,
                                'الكمية',
                                Icons.production_quantity_limits,
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildDropdown(
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
                                (value) => setState(
                                  () => _selectedStockStatus = value!,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // حالة المنتج والمميز والجديد
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
                        const SizedBox(height: 8),

                        Row(
                          children: [
                            Expanded(
                              child: _buildSwitch(
                                'منتج مميز',
                                _isFeatured,
                                (value) => setState(() => _isFeatured = value),
                              ),
                            ),
                            Expanded(
                              child: _buildSwitch(
                                'منتج جديد',
                                _isNew,
                                (value) => setState(() => _isNew = value),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // السمات
                        buildAdvancedAttributesSection(),
                        const SizedBox(height: 24),

                        // العلامات
                        buildTagsSection(),
                        const SizedBox(height: 32),

                        // أزرار الحفظ
                        _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    onPressed: _submitProduct,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _primaryColor,
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'حفظ المنتج',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
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
}
