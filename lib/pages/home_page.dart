import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'brand_details_page.dart';
import 'brands_page.dart';
import 'offer_details_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'offers_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Wafrha'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          // textDirection: TextDirection.,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
//             Padding(
//   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//   child: Row(
//     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//     children: [
//       Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: const [
//           Text('أهلاً بك في', style: TextStyle(fontSize: 14, color: Colors.grey)),
//           Text('Wafrha 👋', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
//         ],
//       ),
//       CircleAvatar(
//         backgroundImage: NetworkImage('https://i.pravatar.cc/150'), // صورة المستخدم أو أيقونة ثابتة
//       ),
//     ],
//   ),
// ),

            const SizedBox(height: 16),

            // 🔥 Section العروض (Offers)
            // Padding(
              // padding: const EdgeInsets.symmetric(horizontal: 16),
              // child: const Text('العروض', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            // ),
            // const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('offers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final offers = snapshot.data!.docs;
                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: offers.length,
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfferDetailsPage(
                                title: offer['title'],
                                imageUrl: offer['image'],
                                description: offer['description'],
                                expiry: offer['expiry'],
                                category: offer['category'],
                                offerCode: offer['offerCode'],
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: offer['image'],
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(offer['image']),
                                fit: BoxFit.contain,
                              ),
                            ),
                            child: Container(
                              alignment: Alignment.bottomLeft,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Text(
                                offer['title'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // 🔥 Section البراندات (Brands)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Brands',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BrandsPage()),
                      );
                    },
                    child: const Text('Show All' , style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('brands').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final brands = snapshot.data!.docs;
                return SizedBox(
                  height: 120,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: brands.length,
                    itemBuilder: (context, index) {
                      final brand = brands[index];
                      return brandCard(
                        context,
                        brand['name'],
                        brand['image'],
                        brand['x'],
                        brand['instagram'],
                        brand['facebook'],
                        brand['website'],
                        brand['description'],
                      );
                    },
                  ),
                );
              },
            ),
            
            const SizedBox(height: 30),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Lastest Offers',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const OffersPage()),
                      );
                    },
                    child: const Text('All Offers' , style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('offers').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final offers = snapshot.data!.docs;
                return SizedBox(
                  height: 220,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: offers.length,
                    padding: const EdgeInsets.only(left: 16),
                    itemBuilder: (context, index) {
                      final offer = offers[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfferDetailsPage(
                                title: offer['title'],
                                imageUrl: offer['image'],
                                description: offer['description'],
                                expiry: offer['expiry'],
                                category: offer['category'],
                                offerCode: offer['offerCode'],
                              ),
                            ),
                          );
                        },
                        child: Hero(
                          tag: offer['image'],
                          child: Container(
                            width: 250,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: NetworkImage(offer['image']),
                                fit: BoxFit.cover,
                              ),
                            ),
                            child: Container(
                              alignment: Alignment.bottomLeft,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: const LinearGradient(
                                  colors: [Colors.black54, Colors.transparent],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              child: Text(
                                offer['title'],
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),

          ],
        ),
      ),
    );
  }

  Widget brandCard(BuildContext context, String name, String imageUrl, String x, String inst, String face, String website, String dec) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BrandDetailsPage(
              name: name,
              imageUrl: imageUrl,
              facebook: face,
              x: x,
              website: website,
              insta: inst,
              dec: dec,
            ),
          ),
        );
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(color: Colors.grey.shade300, blurRadius: 6, offset: const Offset(0, 4)),
                ],
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: imageUrl.endsWith('.svg')
                    ? SvgPicture.network(imageUrl, width: 80, height: 80 ,)
                    : Image.network(imageUrl, width: 80, height: 80, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Text(name, style: const TextStyle(fontSize: 13), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
