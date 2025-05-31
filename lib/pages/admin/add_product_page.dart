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
  final TextEditingController _imagesController = TextEditingController(); // Simple comma-separated URLs for now
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _discountPriceController = TextEditingController();
  final TextEditingController _categoriesController = TextEditingController(); // Simple comma-separated
  final TextEditingController _attributesController = TextEditingController(); // Simple JSON format for now e.g., {"color":"Red"}
  final TextEditingController _variantsController = TextEditingController(); // Simple JSON format for now e.g., [{"sku":"SKU1", "stock":10}]
  final TextEditingController _skuController = TextEditingController();
  final TextEditingController _stockController = TextEditingController();

  bool _isLoading = false;
  List<Map<String, String>> _brands = []; // Store brand ID and name
  String? _selectedBrandId;
  String _selectedStockStatus = 'in_stock';
  String _selectedProductStatus = 'active';
  bool _isFreeShipping = false;
  String _badge = 'none'; // values: none, new, featured, best_seller


  @override
  void initState() {
    super.initState();
    _fetchBrands();
  }

  Future<void> _fetchBrands() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('brands').get();
      setState(() {
        _brands = snapshot.docs.map((doc) => {
          'id': doc.id,
          'name': doc['name'].toString()
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading brands: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطأ في تحميل البراندات: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _submitProduct() async {
    if (_formKey.currentState!.validate() && _selectedBrandId != null) {
      setState(() => _isLoading = true);

      try {
        // Basic parsing for complex fields (improve with dedicated UI later)
        List<String> images = _imagesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        List<String> categories = _categoriesController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        // TODO: Add proper JSON parsing and validation for attributes/variants
        Map<String, dynamic> attributes = {}; // Placeholder
        List<Map<String, dynamic>> variants = []; // Placeholder

        final newProduct = Product(
          id: '', // Firestore will generate ID
          name: _nameController.text.trim(),
          description: _descController.text.trim(),
          images: images,
          price: double.tryParse(_priceController.text) ?? 0.0,
          discountPrice: _discountPriceController.text.isNotEmpty ? double.tryParse(_discountPriceController.text) : null,
          categories: categories,
          attributes: attributes, // Placeholder
          variants: variants, // Placeholder
          sku: _skuController.text.trim(),
          stock: int.tryParse(_stockController.text) ?? 0,
          stockStatus: _selectedStockStatus,
          brandId: _selectedBrandId!,
          productStatus: _selectedProductStatus,
          createdAt: Timestamp.now(),
          updatedAt: Timestamp.now(),
          // shippingInfo: null, // Add later if needed
        );

        await FirebaseFirestore.instance.collection('products').add(newProduct.toFirestore());
        // await FirebaseFirestore.instance.collection('products').add(newProduct.toFirestore());


        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 8), Text('تمت إضافة المنتج بنجاح!')]),
            backgroundColor: Colors.green,
          ),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedBrandId = null;
          _selectedStockStatus = 'in_stock';
          _selectedProductStatus = 'active';
          _imagesController.clear();
          _categoriesController.clear();
          _attributesController.clear();
          _variantsController.clear();
        });

      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('حدث خطأ أثناء إضافة المنتج: $e'), backgroundColor: Colors.red),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

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


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة منتج جديد'),
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
                    const Text('تفاصيل المنتج', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.teal), textAlign: TextAlign.center),
                    const SizedBox(height: 20),
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
                    // شحن مجاني
SwitchListTile(
  title: const Text('شحن مجاني', style: TextStyle(color: Colors.teal)),
  value: _isFreeShipping,
  onChanged: (value) => setState(() => _isFreeShipping = value),
  activeColor: Colors.orange,
),

// الشعار (Badge)
DropdownButtonFormField<String>(
  decoration: InputDecoration(
    prefixIcon: const Icon(Icons.star, color: Colors.orange),
    labelText: 'الشعار المميز',
    labelStyle: const TextStyle(color: Colors.orange),
    filled: true,
    fillColor: Colors.grey[100],
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: Colors.teal, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
  ),
  value: _badge,
  items: const [
    DropdownMenuItem(value: 'none', child: Text('بدون')),
    DropdownMenuItem(value: 'new', child: Text('جديد')),
    DropdownMenuItem(value: 'featured', child: Text('مميز')),
    DropdownMenuItem(value: 'best_seller', child: Text('الأكثر مبيعًا')),
  ],
  onChanged: (value) => setState(() => _badge = value!),
),

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
                              backgroundColor: Colors.orange,
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

