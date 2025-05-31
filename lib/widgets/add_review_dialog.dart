import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:provider/provider.dart';
import '../services/review_service.dart';

class AddReviewDialog extends StatefulWidget {
  final String productId;

  const AddReviewDialog({super.key, required this.productId});

  @override
  State<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends State<AddReviewDialog> {
  final _formKey = GlobalKey<FormState>();
  final _commentController = TextEditingController();
  double _rating = 3.0; // Default rating
  bool _isLoading = false;

  Future<void> _submitReview() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);
    final reviewService = Provider.of<ReviewService>(context, listen: false);

    try {
      await reviewService.addReview(
        widget.productId,
        _rating,
        _commentController.text.trim(),
      );
      Navigator.pop(context, true); // Return true to indicate success
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('شكراً لك، تم إرسال مراجعتك بنجاح!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      Navigator.pop(context, false); // Return false on failure
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل إرسال المراجعة: $e'), backgroundColor: Colors.red),
      );
    } finally {
      // No need to set isLoading to false if we are popping the dialog
      // if (mounted) {
      //   setState(() => _isLoading = false);
      // }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة مراجعة'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ما هو تقييمك للمنتج؟'),
              const SizedBox(height: 10),
              RatingBar.builder(
                initialRating: _rating,
                minRating: 1,
                direction: Axis.horizontal,
                allowHalfRating: false,
                itemCount: 5,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    _rating = rating;
                  });
                },
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _commentController,
                decoration: const InputDecoration(
                  labelText: 'اكتب تعليقك هنا',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'الرجاء كتابة تعليق';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitReview,
          child: _isLoading ? const SizedBox(height: 15, width: 15, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('إرسال'),
        ),
      ],
    );
  }
}

