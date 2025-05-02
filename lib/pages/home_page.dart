import 'package:flutter/material.dart';
import 'brands_page.dart';
import 'offers_page.dart'; // تأكد من وجودها
import 'offer_details_page.dart'; // تأكد من وجودها
import 'package:flutter_svg/flutter_svg.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
            final List<Map<String, String>> offers = [
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wafrha'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO SECTION

// ثم غيّر ListView الخاص بالعروض ليصبح:

Container(
height: 160,
padding: const EdgeInsets.only(left: 16),
child: ListView.builder(
scrollDirection: Axis.horizontal,
itemCount: offers.length,
itemBuilder: (context, index) {
final offer = offers[index];
return GestureDetector(
onTap: () {
Navigator.push(
context,
MaterialPageRoute(
builder: (_) => OfferDetailsPage(
title : offer['title']! , imageUrl : offer['image']! ,  description : offer['title']! , expiry : offer['expiry']! , category : offer['category']! , offerCode: offer['offerCode']!,
),
),
);
},
child: Hero(
tag: offer['image']!,
child: Container(
width: 220,
margin: const EdgeInsets.only(right: 10),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(12),
image: DecorationImage(
image: NetworkImage(offer['image']!),
fit: BoxFit.cover,
),
),
child: Container(
alignment: Alignment.bottomLeft,
padding: const EdgeInsets.all(10),
decoration: BoxDecoration(
borderRadius: BorderRadius.circular(12),
gradient: LinearGradient(
colors: [Colors.black, Colors.transparent],
begin: Alignment.bottomCenter,
end: Alignment.topCenter,
),
),
child: Text(
offer['title']!,
style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
),
),
),
),
);
},
),
),

            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 30),
              child: Text('البراندات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 20),

            // BRAND PREVIEW
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                children: [
                  brandCard('Nike', 'https://1000logos.net/wp-content/uploads/2017/03/Nike-Logo.png'),
                  brandCard('Adidas', 'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg'),
                  brandCard('Puma', 'https://1000logos.net/wp-content/uploads/2017/05/PUMA-logo.jpg'),
                ],
              ),
            ),

            // const SizedBox(height: 0),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('العروض المميزة', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const OffersPage()));
                    },
                    child: const Text('عرض الكل'),
                  ),
                ],
              ),
            ),

            // OFFERS PREVIEW (Static Placeholder)
            Container(
              height: 160,
              padding: const EdgeInsets.only(left: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 3, // افتراضي
                itemBuilder: (context, index) => Container(
                  width: 220,
                  margin: const EdgeInsets.only(right: 10),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                    image: const DecorationImage(
                      image: NetworkImage('https://img.freepik.com/free-photo/fashion-sale-banner-template_23-2148503377.jpg'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget brandCard(String name, String imageUrl) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: imageUrl.endsWith('.svg')
                ? SvgPicture.network(imageUrl, width: 60, height: 60)
                : Image.network(imageUrl, width: 60, height: 60, fit: BoxFit.cover),
          ),
          const SizedBox(height: 5),
          Text(name, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
