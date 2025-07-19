import 'package:flutter/material.dart';

class SearchBarWidget extends StatelessWidget {
  final Function(String) onSearch;
  final String hintText;
  final bool autofocus;

  const SearchBarWidget({
    super.key,
    required this.onSearch,
    this.hintText = 'ابحث عن منتجات، عروض، ماركات...',
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: TextField(
        onSubmitted: onSearch,
        autofocus: autofocus,
        decoration: InputDecoration(
          hintText: hintText,
          prefixIcon: const Icon(Icons.search, color: Color(0xFF3366FF)),
          suffixIcon: IconButton(
            icon: const Icon(Icons.filter_list, color: Colors.grey),
            onPressed: () {
              // Show filter options
              // This will be implemented later
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
