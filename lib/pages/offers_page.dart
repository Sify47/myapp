import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'offer_details_page.dart'; // عدّل حسب مسار الصفحة

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  String selectedCategory = 'الكل';
  String searchQuery = '';
  List<Map<String, dynamic>> allOffers = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchOffers();
  }

  Future<void> fetchOffers() async {
    final snapshot = await FirebaseFirestore.instance.collection('offers').get();

    final fetched = snapshot.docs.map((doc) {
      return {
        'brand': doc['brand'],
        'title': doc['title'],
        'image': doc['image'],
        'category': doc['category'],
        'expiry': doc['expiry'],
        'offerCode': doc['offerCode'],
      };
    }).toList();

    setState(() {
      allOffers = fetched;
      isLoading = false;
    });
  }

  List<Map<String, dynamic>> get filteredOffers {
    return allOffers.where((offer) {
      final matchesCategory = selectedCategory == 'الكل' || offer['category'] == selectedCategory;
      final matchesSearch = offer['brand'].toLowerCase().contains(searchQuery.toLowerCase()) ||
          offer['title'].toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Offerrs'), centerTitle: true),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'ابحث عن عرض أو براند...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.grey.shade200,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setState(() => searchQuery = value),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 45,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    children: [
                      ...['الكل', 'رياضي', 'كلاسيكي', 'فاخر', 'ملابس', 'ادوات منزليه'].map((category) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: ChoiceChip(
                            label: Text(category),
                            selected: selectedCategory == category,
                            onSelected: (_) => setState(() => selectedCategory = category),
                            selectedColor: Colors.orange.shade300,
                            backgroundColor: Colors.grey.shade200,
                            labelStyle: TextStyle(
                              color: selectedCategory == category ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: GridView.builder(
                      itemCount: filteredOffers.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 15,
                        crossAxisSpacing: 15,
                        childAspectRatio: 0.90,
                      ),
                      itemBuilder: (context, index) {
                        final offer = filteredOffers[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfferDetailsPage(
                                  title: offer['title'],
                                  imageUrl: offer['image'],
                                  description: offer['title'],
                                  expiry: offer['expiry'],
                                  category: offer['category'],
                                  offerCode: offer['offerCode'],
                                ),
                              ),
                            );
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                                  child: (offer['image'] ?? '').toString().endsWith('.svg')
                        ? SvgPicture.network(offer['image'] ?? '', height: 110, width: double.infinity , fit: BoxFit.contain)
                        : Image.network(offer['image'] ?? '', height: 110, width: double.infinity, fit: BoxFit.contain), 
                                  // Image.network(
                                  //   offer['image'],
                                  //   height: 110,
                                  //   width: double.infinity,
                                  //   fit: BoxFit.cover,
                                  // ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        offer['brand'],
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        offer['title'],
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.category, size: 14, color: Colors.blueGrey),
                                          const SizedBox(width: 4),
                                          Text(
                                            offer['category'],
                                            style: const TextStyle(fontSize: 12, color: Colors.blueGrey),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.calendar_today, size: 14, color: Colors.orange),
                                          const SizedBox(width: 4),
                                          Text(
                                            'ينتهي ${offer['expiry']}',
                                            style: const TextStyle(fontSize: 12, color: Colors.orange),
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
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
