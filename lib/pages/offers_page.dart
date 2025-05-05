import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'offer_details_page.dart';

class OffersPage extends StatefulWidget {
  const OffersPage({super.key});

  @override
  State<OffersPage> createState() => _OffersPageState();
}

class _OffersPageState extends State<OffersPage> {
  String selectedCategory = 'الكل';
  String searchQuery = '';
  DateTime? selectedExpiryDate;

  final List<Map<String, String>> allOffers = [
    {
      'brand': 'Nike',
      'title': 'خصم 30% على الجري',
      'image':
          'https://media.gq.com/photos/61673a9178f964335d8b9bf7/master/pass/101321-nike-deals-lead.jpg',
      'category': 'رياضي',
      'expiry': '2025/7/1',
      'offerCode': "SAVE20",
    },
    {
      'brand': 'Adidas',
      'title': '8% Cash Back',
      'image':
          'https://product-images.ibotta.com/admin/2020-04-23/0deb4a45f56feec3Ibotta_OfferCard_Adidas.png',
      'category': 'رياضي',
      'expiry': '2025/7/1',
      'offerCode': "SAVE20",
    },
    {
      'brand': 'Gucci',
      'title': 'خصم على العطور حتى 20%',
      'image':
          'https://www.dubaidutyfree.com/file/general/GUCCI_TOP_BANNER_1.jpg',
      'category': 'فاخر',
      'expiry': '2025/7/1',
      'offerCode': "SAVE20",
    },
    {
      'brand': 'Zara',
      'title': 'تشكيلة كلاسيكية جديدة',
      'image':
          'https://cdn.grabon.in/gograbon/images/web-images/uploads/1583914766701/zara-offers.jpg',
      'category': 'كلاسيكي',
      'expiry': '2025/7/1',
      'offerCode': "SAVE20",
    },
    {
      'brand': 'Puma',
      'title': 'خصومات حتى 40%',
      'image':
          'https://www.sears.com.mx/c/puma/img/Banner_principal/PUMA-SEARS-SEPTIEMBRE-D-1.jpg',
      'category': 'كلاسيكي',
      'expiry': '2025/7/5',
      'offerCode': "SAVE20",
    },
  ];

  List<Map<String, String>> get filteredOffers {
    return allOffers.where((offer) {
      final matchesCategory =
          selectedCategory == 'الكل' || offer['category'] == selectedCategory;
      final matchesSearch =
          offer['brand']!.toLowerCase().contains(searchQuery.toLowerCase()) ||
          offer['title']!.toLowerCase().contains(searchQuery.toLowerCase());

      // final offerExpiry = DateTime.tryParse(offer['expiry']!.replaceAll('/', '-'));
      // final matchesDate = selectedExpiryDate == null || (offerExpiry != null && offerExpiry.isBefore(selectedExpiryDate!.add(const Duration(days: 1))));

      return matchesCategory && matchesSearch;
    }).toList();
  }

  // void _pickDate() async {
  //   final picked = await showDatePicker(
  //     context: context,
  //     initialDate: selectedExpiryDate ?? DateTime.now(),
  //     firstDate: DateTime(2020),
  //     lastDate: DateTime(2030),
  //   );
  //   if (picked != null) {
  //     setState(() => selectedExpiryDate = picked);
  //   }
  // }

  // void _clearDate() {
  //   setState(() => selectedExpiryDate = null);
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جميع العروض'), centerTitle: true),
      body: Column(
        children: [
          const SizedBox(height: 8),

          // شريط البحث
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
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          const SizedBox(height: 10),

          // تصنيفات + اختيار التاريخ
          SizedBox(
            height: 45,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                ...['الكل', 'رياضي', 'كلاسيكي', 'فاخر'].map((category) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected:
                          (_) => setState(() => selectedCategory = category),
                      selectedColor: Colors.orange.shade300,
                      backgroundColor: Colors.grey.shade200,
                      labelStyle: TextStyle(
                        color:
                            selectedCategory == category
                                ? Colors.white
                                : Colors.black,
                      ),
                    ),
                  );
                  // ignore: unnecessary_to_list_in_spreads
                }).toList(),
                const SizedBox(width: 10),
                //   TextButton.icon(
                //     onPressed: _pickDate,
                //     icon: const Icon(Icons.date_range),
                //     label: Text(
                //       selectedExpiryDate != null
                //           ? DateFormat('yyyy/MM/dd').format(selectedExpiryDate!)
                //           : 'تصفية بالتاريخ',
                //       style: const TextStyle(fontSize: 13),
                //     ),
                //   ),
                //   if (selectedExpiryDate != null)
                //     IconButton(onPressed: _clearDate, icon: const Icon(Icons.close, size: 20))
              ],
            ),
          ),

          const SizedBox(height: 10),

          // العروض
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.builder(
                itemCount: filteredOffers.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.70,
                ),
                itemBuilder: (context, index) {
                  final offer = filteredOffers[index];
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
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            // ignore: deprecated_member_use
                            color: Colors.black.withOpacity(
                              0.04,
                            ), // ظل خفيف جدًا
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(14),
                            ),
                            child: Image.network(
                              offer['image']!,
                              height: 110, // تقليل الطول
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  offer['brand']!,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  offer['title']!,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.category,
                                      size: 14,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      offer['category']!,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'ينتهي ${offer['expiry']}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange,
                                      ),
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
