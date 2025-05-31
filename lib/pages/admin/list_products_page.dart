import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/product.dart'; // Import Product model
import 'edit_product_form.dart'; // Import the edit form page

class ListProductsPage extends StatefulWidget {
  const ListProductsPage({super.key});

  @override
  State<ListProductsPage> createState() => _ListProductsPageState();
}

class _ListProductsPageState extends State<ListProductsPage> {
  final Stream<QuerySnapshot> _productsStream = FirebaseFirestore.instance.collection('products').snapshots();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Product to Update'),
        centerTitle: true,
         flexibleSpace: Container(decoration: const BoxDecoration(color: Colors.orange)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _productsStream,
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Something went wrong: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No products found.'));
          }

          return ListView( // Changed from GridView for better info display
            padding: const EdgeInsets.all(10.0),
            children: snapshot.data!.docs.map((DocumentSnapshot document) {
              Product product = Product.fromFirestore(document);
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: (product.images.isNotEmpty && product.images[0].isNotEmpty)
                        ? NetworkImage(product.images[0])
                        : null,
                    backgroundColor: Colors.grey[200], // Handle empty image URL
                    child: (product.images.isEmpty || product.images[0].isEmpty)
                        ? const Icon(Icons.shopping_bag) // Placeholder icon
                        : null,
                  ),
                  title: Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('SKU: ${product.sku}\nPrice: ${product.price} SAR'),
                  isThreeLine: true,
                  trailing: const Icon(Icons.edit, color: Colors.orange),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditProductFormPage(product: product),
                      ),
                    );
                  },
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

