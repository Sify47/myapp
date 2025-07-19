import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:provider/provider.dart';
import '../../models/coupon.dart';
import '../../services/coupon_service.dart';

class EditCouponForm extends StatefulWidget {
  final Coupon coupon;

  const EditCouponForm({super.key, required this.coupon});

  @override
  State<EditCouponForm> createState() => _EditCouponFormState();
}

class _EditCouponFormState extends State<EditCouponForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _descriptionController;
  late TextEditingController _discountValueController;
  late TextEditingController _minimumSpendController;
  late TextEditingController _usageLimitController;

  late String _discountType;
  late DateTime _expiryDate;
  late bool _isActive;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers and state with existing coupon data
    _descriptionController = TextEditingController(
      text: widget.coupon.description,
    );
    _discountValueController = TextEditingController(
      text: widget.coupon.discountValue.toString(),
    );
    _minimumSpendController = TextEditingController(
      text: widget.coupon.minimumSpend?.toString() ?? '',
    );
    _usageLimitController = TextEditingController(
      text: widget.coupon.usageLimit?.toString() ?? '',
    );
    _discountType = widget.coupon.discountType;
    _expiryDate = widget.coupon.expiryDate.toDate();
    _isActive = widget.coupon.isActive;
  }

  Future<void> _selectExpiryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate,
      firstDate: DateTime.now().subtract(
        const Duration(days: 365),
      ), // Allow past dates for viewing/editing
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _expiryDate) {
      setState(() {
        _expiryDate = picked;
      });
    }
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final couponService = Provider.of<CouponService>(context, listen: false);
    final discountValue = double.tryParse(_discountValueController.text.trim());
    final minimumSpend =
        _minimumSpendController.text.trim().isEmpty
            ? null
            : double.tryParse(_minimumSpendController.text.trim());
    final usageLimit =
        _usageLimitController.text.trim().isEmpty
            ? null
            : int.tryParse(_usageLimitController.text.trim());

    if (discountValue == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('قيمة الخصم غير صالحة'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    // Create updated Coupon object
    final updatedCoupon = Coupon(
      id: widget.coupon.id, // Keep the original ID
      code: widget.coupon.code, // Code is usually not editable
      description: _descriptionController.text.trim(),
      discountType: _discountType,
      discountValue: discountValue,
      minimumSpend: minimumSpend,
      expiryDate: Timestamp.fromDate(_expiryDate),
      usageLimit: usageLimit,
      currentUsage: widget.coupon.currentUsage, // Keep current usage
      isActive: _isActive,
      createdAt: widget.coupon.createdAt, // Keep original creation date
    );

    try {
      await couponService.updateCoupon(updatedCoupon);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم تحديث الكوبون بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context); // Go back after successful update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل تحديث الكوبون: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('تعديل كوبون: ${widget.coupon.code}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Code is usually not editable, display it
              Text(
                'رمز الكوبون: ${widget.coupon.code}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'الوصف'),
                validator:
                    (value) =>
                        value == null || value.trim().isEmpty
                            ? 'الوصف مطلوب'
                            : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(labelText: 'نوع الخصم'),
                items: const [
                  DropdownMenuItem(
                    value: 'fixed_amount',
                    child: Text('مبلغ ثابت'),
                  ),
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('نسبة مئوية'),
                  ),
                ],
                onChanged: (value) => setState(() => _discountType = value!),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _discountValueController,
                decoration: InputDecoration(
                  labelText: 'قيمة الخصم',
                  suffixText: _discountType == 'percentage' ? '%' : 'ج.م',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty)
                    return 'قيمة الخصم مطلوبة';
                  if (double.tryParse(value.trim()) == null)
                    return 'قيمة غير صالحة';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _minimumSpendController,
                decoration: const InputDecoration(
                  labelText: 'الحد الأدنى للطلب (اختياري)',
                  suffixText: 'ج.م',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      double.tryParse(value.trim()) == null) {
                    return 'قيمة غير صالحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _usageLimitController,
                decoration: const InputDecoration(
                  labelText: 'حد الاستخدام الكلي (اختياري)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null &&
                      value.trim().isNotEmpty &&
                      int.tryParse(value.trim()) == null) {
                    return 'قيمة غير صالحة';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'تاريخ الانتهاء: ${DateFormat('yyyy-MM-dd').format(_expiryDate)}',
                  ),
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
                child:
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                          onPressed: _submitUpdate,
                          child: const Text('تحديث الكوبون'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
