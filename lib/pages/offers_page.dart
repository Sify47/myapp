import 'package:flutter/material.dart';
import 'offer_details_page.dart'; // تأكد من أنك أضفت الاستيراد الصحيح

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  String selectedCategory = 'الكل';

  final List<Map<String, String>> allOffers = [
    {
      'brand': 'Nike',
      'title': 'خصم 30% على الجري',
      'image': 'nike.png',
      'category': 'رياضي'
    },
    {
      'brand': 'Adidas',
      'title': 'اشتر 2 واحصل على 1 مجاناً',
      'image': 'https://via.placeholder.com/300x150?text=Adidas+عرض',
      'category': 'رياضي'
    },
    {
      'brand': 'Gucci',
      'title': 'خصم حتى 50% على الأحذية',
      'image': 'https://via.placeholder.com/300x150?text=Gucci+عرض',
      'category': 'فاخر'
    },
    {
      'brand': 'Zara',
      'title': 'تشكيلة كلاسيكية جديدة',
      'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg',
      'category': 'كلاسيكي'
    },
  ];

  List<Map<String, String>> get filteredOffers {
    if (selectedCategory == 'الكل') return allOffers;
    return allOffers.where((offer) => offer['category'] == selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('كل العروض')), 
        body: Column(
          children: [
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                children: [
                  'الكل', 'رياضي', 'كلاسيكي', 'فاخر'
                ].map((category) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: selectedCategory == category,
                    onSelected: (_) => setState(() => selectedCategory = category),
                  ),
                )).toList(),
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: filteredOffers.length,
                itemBuilder: (context, index) {
                  final offer = filteredOffers[index];
                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => OfferDetailsPage(title : offer['title']! , imageUrl : offer['image']! ,  description : offer['brand']! , expiry : offer['category']! , category : offer['category']!),
                        ),
                      );
                    },
                    child: Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              offer['image']!,
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(offer['brand']!, style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                const SizedBox(height: 4),
                                Text(offer['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
