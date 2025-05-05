import 'package:flutter/material.dart';
import 'brands_page.dart';
import 'brand_details_page.dart';
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
        'image':
            'https://media.gq.com/photos/61673a9178f964335d8b9bf7/master/pass/101321-nike-deals-lead.jpg',
        'category': 'رياضي',
        'expiry': '2025/7/1',
        'offerCode': "SAVE20",
        // 'description' : ''
      },
      {
        'brand': 'Adidas',
        'title': '8% Cash Back',
        'image':
            'https://product-images.ibotta.com/admin/2020-04-23/0deb4a45f56feec3Ibotta_OfferCard_Adidas.png',
        'category': 'رياضي',
        'expiry': '2025/7/1',
        'offerCode': "SAVE20",
        // 'description' : ''
      },
      {
        'brand': 'Gucci',
        'title': 'خصم على العطور حتى 20%',
        'image':
            'https://www.dubaidutyfree.com/file/general/GUCCI_TOP_BANNER_1.jpg',
        'category': 'فاخر',
        'expiry': '2025/7/1',
        'offerCode': "SAVE20",
        // 'description' : ''
      },
      {
        'brand': 'Zara',
        'title': 'تشكيلة كلاسيكية جديدة',
        'image':
            'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg',
        'category': 'كلاسيكي',
        'expiry': '2025/7/1',
        'offerCode': "SAVE20",
        // 'description' : ''
      },
      {
        'brand': 'Puma',
        'title': 'خصومات حتى 40%',
        'image':
            'https://www.sears.com.mx/c/puma/img/Banner_principal/PUMA-SEARS-SEPTIEMBRE-D-1.jpg',
        'category': 'كلاسيكي',
        'expiry': '2025/7/5',
        'offerCode': "SAVE20",
        // 'description' : ''
      },
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Wafrha'), centerTitle: true),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HERO SECTION

            // ثم غيّر ListView الخاص بالعروض ليصبح:
            Container(
              height: 220,
              // width: 220,
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
                          builder:
                              (_) => OfferDetailsPage(
                                title: offer['title']!,
                                imageUrl: offer['image']!,
                                description: offer['title']!,
                                expiry: offer['expiry']!,
                                category: offer['category']!,
                                offerCode: offer['offerCode']!,
                              ),
                        ),
                      );
                    },
                    child: Hero(
                      tag: offer['image']!,
                      child: Container(
                        width: 250,
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'البراندات',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const BrandsPage()),
                      );
                    },
                    child: const Text('عرض الكل' , style: TextStyle(color: Colors.orange)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // BRAND PREVIEW
            SizedBox(
              height: 120,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  brandCard(
                    context,
                    'Nike',
                    'https://1000logos.net/wp-content/uploads/2017/03/Nike-Logo.png',
                    'https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                    
                  ),
                  brandCard(
                    context,
                    'Adidas',
                    'https://upload.wikimedia.org/wikipedia/commons/2/20/Adidas_Logo.svg','https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                  ),
                  brandCard(
                    context,
                    'Puma',
                    'https://1000logos.net/wp-content/uploads/2017/05/PUMA-logo.jpg','https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                  ),
                  brandCard(
                    context,
                    'New Balance',
                    'https://logos-world.net/wp-content/uploads/2020/09/New-Balance-Logo.png','https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                  ),
                  brandCard(
                    context,
                    'Zara',
                    'https://logos-world.net/wp-content/uploads/2020/05/Zara-Logo-1975-2008.png','https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                  ),
                  brandCard(
                    context,
                    'H&M',
                    'https://logos-world.net/wp-content/uploads/2020/04/HM-Logo.png','https://x.com/nike',
                    'https://instagram.com/nike',
                    'https://facebook.com/nike',
                    'https://www.nike.com',
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'أحدث العروض',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  // TextButton(
                  //   onPressed: () {
                  //     Navigator.push(
                  //       context,
                  //       MaterialPageRoute(builder: (_) => const OffersPage()),
                  //     );
                  //   },
                  //   child: const Text('عرض الكل'),
                  // ),
                ],
              ),
            ),

            // OFFERS PREVIEW (Static Placeholder)
            const SizedBox(height: 20),
            Container(
              height: 160,
              padding: const EdgeInsets.only(left: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: offers.length, // افتراضي
                itemBuilder: (context, index) {
                  final offer = offers[index];
                  return GestureDetector(
                    // onTap: () {
                    //   Navigator.push(
                    //     context,
                    //     MaterialPageRoute(
                    //       builder:
                    //           (_) => OfferDetailsPage(
                    //             title: offer['title']!,
                    //             imageUrl: offer['image']!,
                    //             description: offer['title']!,
                    //             expiry: offer['expiry']!,
                    //             category: offer['category']!,
                    //             offerCode: offer['offerCode']!,
                    //           ),
                    //     ),
                    //   );
                    // },
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
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget brandCard(BuildContext context, String name, String imageUrl , String x , String inst , String face , String website) {
    return GestureDetector(
      onTap: () {
       Navigator.push(
         context,
          MaterialPageRoute(builder: (_) => BrandDetailsPage(name: name , imageUrl: imageUrl, facebook: face , x: x, website: website, insta: inst,)),
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
                  BoxShadow(
                    color: Colors.grey,
                    blurRadius: 6,
                    offset: const Offset(0, 4),
                  ),
                ],
                borderRadius: BorderRadius.circular(50),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(6),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child:
                    imageUrl.endsWith('.svg')
                        ? SvgPicture.network(imageUrl, width: 50, height: 50)
                        : Image.network(
                          imageUrl,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: const TextStyle(fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
