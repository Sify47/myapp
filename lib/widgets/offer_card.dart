import 'package:flutter/material.dart';

class OfferCard extends StatelessWidget {
  final String title;
  final String discount;
  final String description;

  const OfferCard({super.key, required this.title, required this.discount, required this.description});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.deepPurple,
          child: Text(discount, style: const TextStyle(color: Colors.white)),
        ),
        title: Text(title),
        subtitle: Text(description),
        trailing: IconButton(
          icon: const Icon(Icons.copy),
          onPressed: () {},
        ),
      ),
    );
  }
}
