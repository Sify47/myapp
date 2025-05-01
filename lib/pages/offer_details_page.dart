import 'package:flutter/material.dart';

class OfferDetailsPage extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String expiry;
  final String category;

  const OfferDetailsPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.expiry,
    required this.category,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        children: [
          Hero(
            tag: title,
            child: Image.network(
              imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 100),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text("الفئة: $category", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 10),
                Text("ينتهي في: $expiry", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 20),
                const Text("تفاصيل العرض:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Text(description, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    // implement share or favorite later
                  },
                  icon: const Icon(Icons.favorite_border),
                  label: const Text("أضف إلى المفضلة"),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
