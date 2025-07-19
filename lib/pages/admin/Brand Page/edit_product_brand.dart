import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

import '../../../models/product.dart';
import '../../../auth_model.dart';

class EditProductPage extends StatefulWidget {
  final Product product;
  final String productId;

  const EditProductPage({
    super.key,
    required this.product,
    required this.productId,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _discountPriceController;
  late TextEditingController _skuController;
  late TextEditingController _stockController;
  final List<Map<String, dynamic>> _attributes = [];
  final TextEditingController _attributeNameController = TextEditingController();
  final TextEditingController _attributeValueController = TextEditingController();
  final List<String> _tags = [];
  final TextEditingController _tagController = TextEditingController();
  final List<String> _tempValues = [];

  final List<File> _selectedImages = [];
  final List<String> _existingImages = [];
  bool _isLoading = false;
  bool _isUploadingImages = false;
  String _selectedStockStatus = 'in_stock';
  String _selectedProductStatus = 'active';
  bool _isFeatured = false;
  bool _isNew = true;

  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoadingCategories = false;

  // الألوان المعدلة
  final Color _primaryColor = const Color(0xFF4CAF50);
  final Color _secondaryColor = const Color(0xFF2196F3);
  final Color _accentColor = const Color(0xFFFF9800);
  final Color _errorColor = const Color(0xFFF44336);
  final Color _cardColor = Colors.white;
  final Color _textColor = const Color(0xFF333333);

  @override
  void initState() {
    super.initState();
    _initializeData();
    _fetchCategories();
  }

  void _initializeData() {
    _nameController = TextEditingController(text: widget.product.name);
    _descController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _discountPriceController = TextEditingController(
      text: widget.product.discountPrice?.toString() ?? '',
    );
    _skuController = TextEditingController(text: widget.product.sku);
    _stockController = TextEditingController(text: widget.product.stock.toString());
    _selectedStockStatus = widget.product.stockStatus;
    _selectedProductStatus = widget.product.productStatus;
    _isFeatured = widget.product.isFeatured;
    _isNew = widget.product.isNew;
    _tags.addAll(widget.product.tags);
    _attributes.addAll(widget.product.attributes);
    _existingImages.addAll(widget.product.images);
    _selectedCategory = widget.product.categories.isNotEmpty 
        ? widget.product.categories.first 
        : null;
  }

  Future<void> _fetchCategories() async {
    setState(() => _isLoadingCategories = true);
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('categories')
          .orderBy('name')
          .get();

      setState(() {
        _categories = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ في تحميل الأقسام: $e')),
      );
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء اختيار الصور: ${e.toString()}')),
      );
    }
  }

  Future<List<String>> _uploadImages() async {
    if (_selectedImages.isEmpty) return _existingImages;

    setState(() => _isUploadingImages = true);
    List<String> imageUrls = [..._existingImages];

    try {
      for (final image in _selectedImages) {
        final url = Uri.parse(
          'https://api.cloudinary.com/v1_1/db1bvjebn/image/upload?upload_preset=Dolabk'
        );
        
        var request = http.MultipartRequest('POST', url)
          ..files.add(await http.MultipartFile.fromPath('file', image.path));

        var response = await request.send();
        
        if (response.statusCode == 200) {
          final responseData = await response.stream.bytesToString();
          final jsonData = jsonDecode(responseData);
          if (jsonData['secure_url'] != null) {
            imageUrls.add(jsonData['secure_url']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error uploading image: $e');
    } finally {
      setState(() => _isUploadingImages = false);
    }

    return imageUrls;
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      if (index < _existingImages.length) {
        _existingImages.removeAt(index);
      } else {
        _selectedImages.removeAt(index - _existingImages.length);
      }
    });
  }

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = Provider.of<AuthModel>(context, listen: false);
    setState(() => _isLoading = true);

    try {
      final imageUrls = await _uploadImages();
      
      if (imageUrls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('يجب إضافة صورة واحدة على الأقل')),
        );
        return;
      }

      final updatedProduct = Product(
        id: widget.productId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        images: imageUrls,
        price: double.tryParse(_priceController.text) ?? 0.0,
        discountPrice: _discountPriceController.text.isNotEmpty
            ? double.tryParse(_discountPriceController.text)
            : null,
        categories: _selectedCategory != null ? [_selectedCategory!] : [],
        attributes: _attributes,
        sku: _skuController.text.trim(),
        stock: int.tryParse(_stockController.text) ?? 0,
        stockStatus: _selectedStockStatus,
        brandId: auth.brandId!,
        productStatus: _selectedProductStatus,
        createdAt: widget.product.createdAt,
        updatedAt: Timestamp.now(),
        isFeatured: _isFeatured,
        isNew: _isNew,
        tags: _tags,
        soldcount: widget.product.soldcount,
      );

      await FirebaseFirestore.instance
          .collection('products')
          .doc(widget.productId)
          .update(updatedProduct.toFirestore());

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

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('حدث خطأ أثناء تحديث المنتج: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildImageUploadSection() {
    final allImages = [..._existingImages, ..._selectedImages.map((_) => '')];
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'صور المنتج',
          style: TextStyle(
            fontSize: 16,
            color: _textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        
        if (allImages.isEmpty)
          Container(
            height: 120,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
              color: Colors.grey[50],
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.image, size: 40, color: Colors.grey[400]),
                  const SizedBox(height: 8),
                  Text(
                    'لا توجد صور مضافة',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: allImages.length,
              itemBuilder: (ctx, index) {
                final isExisting = index < _existingImages.length;
                final imageUrl = isExisting ? _existingImages[index] : null;
                
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: isExisting
                            ? Image.network(
                                imageUrl!,
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : Image.file(
                                _selectedImages[index - _existingImages.length],
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () => _removeImage(index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _errorColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            padding: const EdgeInsets.all(4),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.add_photo_alternate, color: _secondaryColor),
                label: Text('اختر من المعرض', style: TextStyle(color: _secondaryColor)),
                onPressed: _pickImages,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _secondaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                icon: Icon(Icons.camera_alt, color: _accentColor),
                label: Text('التقاط صورة', style: TextStyle(color: _accentColor)),
                onPressed: () async {
                  final image = await ImagePicker().pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _selectedImages.add(File(image.path)));
                  }
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  side: BorderSide(color: _accentColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        if (_isUploadingImages)
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(
              backgroundColor: Colors.grey[200],
              color: _primaryColor,
            ),
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

  Widget _buildDropdownCat() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      items: _categories.map((String category) {
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
      hint: _isLoadingCategories
          ? const Text('جاري تحميل الأقسام...', style: TextStyle(color: Colors.grey))
          : const Text('اختر تصنيف', style: TextStyle(color: Colors.grey)),
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
        Text(
          "العلامات (Tags)",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          children: _tags.map((tag) {
            return Chip(
              label: Text(tag),
              backgroundColor: _secondaryColor.withOpacity(0.1),
              deleteIcon: Icon(Icons.close, size: 18, color: _errorColor),
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
                decoration: InputDecoration(
                  hintText: 'أدخل tag',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
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
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
        Text(
          'السمات (Attributes)',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _primaryColor,
          ),
        ),
        const SizedBox(height: 10),

        ..._attributes.map((attr) {
          return Card(
            elevation: 2,
            margin: const EdgeInsets.symmetric(vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
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
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: _textColor,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: _errorColor),
                        onPressed: () {
                          setState(() => _attributes.remove(attr));
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    children: (attr['values'] as List<dynamic>).map((value) {
                      return Chip(
                        label: Text(value.toString()),
                        backgroundColor: _secondaryColor.withOpacity(0.1),
                        deleteIcon: Icon(Icons.close, size: 18, color: _errorColor),
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
        Text(
          'إضافة سمة جديدة',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: _textColor,
          ),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: _attributeNameController,
          decoration: InputDecoration(
            labelText: 'اسم السمة',
            hintText: 'مثال: الحجم، اللون',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),

        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _attributeValueController,
                decoration: InputDecoration(
                  labelText: 'قيمة',
                  hintText: 'مثال: أحمر',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                onSubmitted: (value) => _addTempValue(),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _addTempValue,
              style: ElevatedButton.styleFrom(
                backgroundColor: _secondaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('إضافة'),
            ),
          ],
        ),

        const SizedBox(height: 10),
        if (_tempValues.isNotEmpty)
          Wrap(
            spacing: 6,
            children: _tempValues.map((value) {
              return Chip(
                label: Text(value),
                backgroundColor: _secondaryColor.withOpacity(0.1),
                deleteIcon: Icon(Icons.close, size: 18, color: _errorColor),
                onDeleted: () {
                  setState(() => _tempValues.remove(value));
                },
              );
            }).toList(),
          ),

        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: Icon(Icons.save, color: Colors.white),
          label: const Text('حفظ السمة', style: TextStyle(color: Colors.white)),
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
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
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
        title: const Text('تعديل المنتج', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: _primaryColor,
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
                            'تعديل المنتج',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: _primaryColor,
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
                            Expanded(
                              child: _buildDropdownCat(),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildField(
                                _skuController, 
                                'SKU', 
                                Icons.inventory_2
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
                                (value) => setState(() => _selectedStockStatus = value!),
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
                          (value) => setState(() => _selectedProductStatus = value!),
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
                                      onPressed: _updateProduct,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _primaryColor,
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                      child: const Text(
                                        'حفظ التعديلات',
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
    _skuController.dispose();
    _stockController.dispose();
    _attributeNameController.dispose();
    _attributeValueController.dispose();
    _tagController.dispose();
    super.dispose();
  }
}