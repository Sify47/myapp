import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart'; // Import the Product model

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for Product fields
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _imagesController =
      TextEditingController(); // Simple comma-separated URLs for now
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController =
      TextEditingController();
  final TextEditingController _categoriesController =
      TextEditingController(); // Simple comma-separated
  final TextEditingController _attributesController =
      TextEditingController(); // Simple JSON format for now e.g., {"color":"Red"}
  final TextEditingController _variantsController =
      TextEditingController(); // Simple JSON format for now e.g., [{"sku":"SKU1", "stock":10}]
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  final List<Map<String, dynamic>> _attributes = []; // Changed to List<Map>
  // final TextEditingController _attributeNameController =
  //     TextEditingController();
  // final TextEditingController _attributeValueController =
  //     TextEditingController();
  bool _isLoading = false;
  List<Map<String, String>> _brands = []; // Store brand ID and name
  String? _selectedBrandId;
  String _selectedStockStatus = 'in_stock';
  String _selectedProductStatus = 'active';

  // New boolean flags state
  // bool _isFreeShipping = false;
  bool _isFeatured = false;
  bool _isNew = true; // Default new products to 'true'
  // String _badge = 'none'; // Removed as we use boolean flags now

  @override
  void initState() {
    super.initState();
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

  Future<void> _fetchBrands() async {
    // Original fetchBrands logic
    try {
      QuerySnapshot snapshot =
          await FirebaseFirestore.instance.collection('brands').get();
      if (!mounted) return;
      setState(() {
        _brands =
            snapshot.docs
                .map(
                  (doc) => {
                    'id': doc.id,
                    'name': doc['name']?.toString() ?? 'Unnamed Brand',
                  },
                )
                .toList();
      });
    } catch (e) {
      debugPrint('Error loading brands: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('خطأ في تحميل البراندات: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate() && _selectedBrandId != null) {
      setState(() => _isLoading = true);

      try {
        // Basic parsing for complex fields (improve with dedicated UI later)
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
        // TODO: Add proper JSON parsing and validation for attributes/variants
        Map<String, dynamic> attributes = {}; // Placeholder
        List<Map<String, dynamic>> variants = []; // Placeholder

        final newProduct = Product(
          id: '', // Firestore will generate ID
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          images: images,
          price: double.tryParse(_priceController.text) ?? 0.0,
          discountPrice:
              _discountPriceController.text.isNotEmpty
                  ? double.tryParse(_discountPriceController.text)
                  : null,
          categories: categories,
          attributes: _attributes, // Placeholder
          // variants: variants, // Placeholder
          sku: _skuController.text.trim(),
          stock: int.tryParse(_stockController.text) ?? 0,
          stockStatus: _selectedStockStatus,
          brandId: _selectedBrandId!,
          productStatus: _selectedProductStatus,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          // Add the new flags
          // isFreeShipping: _isFreeShipping,
          isFeatured: _isFeatured,
          isNew: _isNew,
          tags: "t" as List<String>, // Placeholder
          // shippingInfo: null, // Add later if needed
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
          _selectedBrandId = null;
          _selectedStockStatus = 'in_stock';
          _selectedProductStatus = 'active';
          // _isFreeShipping = false; // Reset flag
          _isFeatured = false; // Reset flag
          _isNew = true; // Reset flag to default
          _imagesController.clear();
          _categoriesController.clear();
          _attributesController.clear();
          _variantsController.clear();
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

  // Original _buildField
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

  // Original _buildDropdown
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

  // Simple SwitchListTile using original theme context
  Widget _buildSwitch(
    String title,
    bool currentValue,
    ValueChanged<bool> onChanged,
  ) {
    return SwitchListTile(
      title: Text(
        title,
        style: const TextStyle(color: Colors.teal),
      ), // Using original style color
      value: currentValue,
      onChanged: onChanged,
      activeColor: Color(0xFF3366FF), // Using original active color
      tileColor: Colors.grey[100], // Match background
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 0,
        vertical: 0,
      ), // Adjust padding if needed
    );
  }

  @override
  Widget build(BuildContext context) {
    // Original Scaffold and AppBar
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
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
                      'تفاصيل المنتج',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    // Original Fields
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
                      'البراند',
                      Icons.business,
                      _brands.map((brand) {
                        return DropdownMenuItem(
                          value: brand['id'],
                          child: Text(brand['name']!),
                        );
                      }).toList(),
                      _selectedBrandId,
                      (value) => setState(() => _selectedBrandId = value),
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

                    // Add Switches for new flags
                    const SizedBox(height: 10),
                    // _buildSwitch('شحن مجاني', _isFreeShipping, (value) => setState(() => _isFreeShipping = value)),
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

                    // Removed original Badge Dropdown

                    // TODO: Add fields for attributes and variants (potentially using more complex widgets)
                    // _buildField(_attributesController, 'السمات (JSON)', Icons.settings_input_component, isRequired: false, maxLines: 2),
                    // _buildField(_variantsController, 'المتغيرات (JSON)', Icons.merge_type, isRequired: false, maxLines: 3),
                    const SizedBox(height: 20),
                    _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton.icon(
                          onPressed: _submitProduct,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة المنتج'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(
                              0xFF3366FF,
                            ), // Original color
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
