import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'offer_details_page.dart';
import 'package:url_launcher/url_launcher.dart';

class BrandDetailsPage extends StatelessWidget {
  final String name;
  final String imageUrl;
  final String facebook;
  final String x;
  final String website;
  final String insta;
  final String dec;

  const BrandDetailsPage({
    super.key,
    required this.name,
    required this.imageUrl,
    required this.facebook,
    required this.insta,
    required this.website,
    required this.x,
    required this.dec,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(name),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'العروض'),
              Tab(text: 'عن البراند'),
            ],
            labelColor: Colors.black,
            indicatorColor: Colors.deepPurple,
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب العروض من Firestore
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('offers')
                  .where('brand', isEqualTo: name)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('لا توجد عروض متاحة'));
                }

                final offers = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: offers.length,
                  itemBuilder: (context, index) {
                    final offer = offers[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfferDetailsPage(
                                title: offer['title'] ?? '',
                                imageUrl: offer['image'] ?? '',
                                description: offer['description'] ?? '',
                                category: offer['category'] ?? 'عام',
                                expiry: offer['expiry'] ?? 'غير محدد',
                                offerCode: offer['offerCode'] ?? '',
                              ),
                            ),
                          );
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                              child: Image.network(
                                offer['image'] ?? '',
                                height: 160,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const SizedBox(height: 160, child: Center(child: Text("خطأ في تحميل الصورة"))),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(offer['title'] ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Text('الفئة: ${offer['category'] ?? 'عام'}', style: const TextStyle(color: Colors.grey)),
                                  Text('ينتهي في: ${offer['expiry'] ?? 'غير محدد'}', style: const TextStyle(color: Colors.grey)),
                                  if ((offer['offerCode'] ?? '').isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(top: 8),
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.deepPurple.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text('كود العرض: ${offer['offerCode']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // تبويب عن البراند
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Center(
                    child: Hero(
                      tag: name,
                      child: imageUrl.endsWith('.svg')
                          ? SvgPicture.network(imageUrl, height: 100)
                          : Image.network(imageUrl, height: 100),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(dec, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                  const SizedBox(height: 20),
                  const Text('تابعنا على:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.facebook, color: Colors.blue),
                        onPressed: () => launchUrl(Uri.parse(facebook)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.purple),
                        onPressed: () => launchUrl(Uri.parse(insta)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.alternate_email, color: Colors.lightBlue),
                        onPressed: () => launchUrl(Uri.parse(x)),
                      ),
                      IconButton(
                        icon: const Icon(Icons.language),
                        onPressed: () => launchUrl(Uri.parse(website)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
