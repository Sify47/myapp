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
      'image': 'https://media.gq.com/photos/61673a9178f964335d8b9bf7/master/pass/101321-nike-deals-lead.jpg',
      'category': 'رياضي',
      'expiry' : '2025/7/1',
      'offerCode': "SAVE20",
      // 'description' : ''
    },
    {
      'brand': 'Adidas',
      'title': '8% Cash Back',
      'image': 'https://product-images.ibotta.com/admin/2020-04-23/0deb4a45f56feec3Ibotta_OfferCard_Adidas.png',
      'category': 'رياضي',
      'expiry' : '2025/7/1',
      'offerCode': "SAVE20",
      // 'description' : ''
    },
    {
      'brand': 'Gucci',
      'title': 'خصم على العطور حتى 20%',
      'image': 'https://www.dubaidutyfree.com/file/general/GUCCI_TOP_BANNER_1.jpg',
      'category': 'فاخر',
      'expiry' : '2025/7/1',
      'offerCode': "SAVE20",
      // 'description' : ''
    },
    {
      'brand': 'Zara',
      'title': 'تشكيلة كلاسيكية جديدة',
      'image': 'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg',
      'category': 'كلاسيكي',
      'expiry' : '2025/7/1',
      'offerCode': "SAVE20",
      // 'description' : ''
    },
    {
      'brand': 'Puma',
      'title': 'خصومات حتى 40%',
      'image': 'https://www.sears.com.mx/c/puma/img/Banner_principal/PUMA-SEARS-SEPTIEMBRE-D-1.jpg',
      'category': 'كلاسيكي',
      'expiry' : '2025/7/5',
      'offerCode': "SAVE20",
      // 'description' : ''
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
        appBar: AppBar(title: const Row(mainAxisAlignment: MainAxisAlignment.center , children: [Text('All Offers')],)), 
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
                          builder: (context) => OfferDetailsPage(title : offer['title']! , imageUrl : offer['image']! ,  description : offer['title']! , expiry : offer['expiry']! , category : offer['category']! , offerCode: offer['offerCode']!,),
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
