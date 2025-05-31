import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../../models/coupon.dart';
import '../../services/coupon_service.dart';

class AddCouponPage extends StatefulWidget {
  const AddCouponPage({super.key});

  @override
  State<AddCouponPage> createState() => _AddCouponPageState();
}

class _AddCouponPageState extends State<AddCouponPage> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minimumSpendController = TextEditingController();
  final _usageLimitController = TextEditingController();

  String _discountType = 'fixed_amount'; // Default
  DateTime _expiryDate = DateTime.now().add(const Duration(days: 30)); // Default expiry
  bool _isActive = true;
  bool _isLoading = false;

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitCoupon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final couponService = Provider.of<CouponService>(context, listen: false);
    final code = _codeController.text.trim().toUpperCase();
    final discountValue = double.tryParse(_discountValueController.text.trim());
    final minimumSpend = _minimumSpendController.text.trim().isEmpty
        ? null
        : double.tryParse(_minimumSpendController.text.trim());
    final usageLimit = _usageLimitController.text.trim().isEmpty
        ? null
        : int.tryParse(_usageLimitController.text.trim());

    if (discountValue == null) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('قيمة الخصم غير صالحة'), backgroundColor: Colors.red),
      );
       setState(() => _isLoading = false);
       return;
    }

    final newCoupon = Coupon(
      id: code, // Use code as ID
      code: code,
      description: _descriptionController.text.trim(),
      discountType: _discountType,
      discountValue: discountValue,
      minimumSpend: minimumSpend,
      expiryDate: Timestamp.fromDate(_expiryDate),
      usageLimit: usageLimit,
      currentUsage: 0,
      isActive: _isActive,
      createdAt: Timestamp.now(),
    );

    try {
      await couponService.addCoupon(newCoupon);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تمت إضافة الكوبون بنجاح'), backgroundColor: Colors.green),
      );
      Navigator.pop(context); // Go back after successful addition
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إضافة الكوبون: $e'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('إضافة كوبون جديد'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(labelText: 'رمز الكوبون (Code)'),
                textCapitalization: TextCapitalization.characters,
                validator: (value) => value == null || value.trim().isEmpty ? 'رمز الكوبون مطلوب' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                validator: (value) => value == null || value.trim().isEmpty ? 'الوصف مطلوب' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'نوع الخصم'),
                items: const [
                  DropdownMenuItem(value: 'fixed_amount', child: Text('مبلغ ثابت')),
                  DropdownMenuItem(value: 'percentage', child: Text('نسبة مئوية')),
                ],
                onChanged: (value) => setState(() => _discountType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'قيمة الخصم',
                  suffixText: _discountType == 'percentage' ? '%' : 'ر.س',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) return 'قيمة الخصم مطلوبة';
                  if (double.tryParse(value.trim()) == null) return 'قيمة غير صالحة';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimumSpendController,
                decoration: const InputDecoration(labelText: 'الحد الأدنى للطلب (اختياري)', suffixText: 'ر.س'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty && double.tryParse(value.trim()) == null) {
                    return 'قيمة غير صالحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(labelText: 'حد الاستخدام الكلي (اختياري)'),
                keyboardType: TextInputType.number,
                 validator: (value) {
                  if (value != null && value.trim().isNotEmpty && int.tryParse(value.trim()) == null) {
                    return 'قيمة غير صالحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text('تاريخ الانتهاء: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}'),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('تحديد التاريخ'),
                    onPressed: () => _selectExpiryDate(context),
                  ),
                ],
              ),
              SwitchListTile(
                title: const Text('فعال'),
                value: _isActive,
                onChanged: (value) => setState(() => _isActive = value),
              ),
              const SizedBox(height: 20),
              Center(
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                        onPressed: _submitCoupon,
                        child: const Text('إضافة الكوبون'),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

