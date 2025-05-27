import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'offer_details_page.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorites'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final favorites = snapshot.data!.docs;

          if (favorites.isEmpty) {
            return const Center(child: Text('No favorites added yet.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final offer = favorites[index];
              final data = offer.data()! as Map<String, dynamic>;

              return ListTile(
                leading: Hero(
                  tag: data['image'],
                  child: Image.network(data['image'], width: 60, fit: BoxFit.cover),
                ),
                title: Text(data['title']),
                subtitle: Text(data['category']),
                trailing: Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OfferDetailsPage(
                        title: data['title'],
                        imageUrl: data['image'],
                        description: data['description'],
                        expiry: data['expiry'],
                        category: data['category'],
                        offerCode: data['offerCode'],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
