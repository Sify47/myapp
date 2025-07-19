import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OfferDetailsPage extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String description;
  final String category;
  final String expiry;
  final String offerCode;

  const OfferDetailsPage({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.description,
    required this.category,
    required this.expiry,
    required this.offerCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تفاصيل العرض"), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 20),

            // Offer Info Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  infoCard(Icons.category, "الفئة", category),
                  infoCard(Icons.date_range, "تاريخ الانتهاء", expiry),
                  infoCard(Icons.code, "كود الخصم", offerCode),
                  const SizedBox(height: 12),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: offerCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم نسخ الكود بنجاح")),
                );
              },
              child: const Text(
                "استخدم العرض الآن",
                style: TextStyle(fontSize: 18),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget infoCard(IconData icon, String label, String value) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Color(0xFF3366FF)),
        title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(value),
      ),
    );
  }
}
