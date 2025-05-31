import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/wishlist_service.dart';

class FavoriteButton extends StatelessWidget {
  final String productId;

  const FavoriteButton({super.key, required this.productId});

  @override
  Widget build(BuildContext context) {
    final wishlistService = Provider.of<WishlistService>(context);

    return StreamBuilder<bool>(
      stream: wishlistService.isFavoriteStream(productId),
      builder: (context, snapshot) {
        // Handle loading state if needed, though snapshots update quickly
        // if (snapshot.connectionState == ConnectionState.waiting) {
        //   return IconButton(
        //     icon: const Icon(Icons.favorite_border, color: Colors.grey),
        //     onPressed: null, // Disable while loading
        //   );
        // }

        final isFavorite = snapshot.data ?? false;

        return IconButton(
          icon: Icon(
            isFavorite ? Icons.favorite : Icons.favorite_border,
            color: isFavorite ? Colors.red : Colors.grey,
          ),
          tooltip: isFavorite ? 'إزالة من المفضلة' : 'إضافة إلى المفضلة',
          onPressed: () async {
            try {
              await wishlistService.toggleWishlistStatus(productId);
              // Optional: Show a confirmation SnackBar
              // ScaffoldMessenger.of(context).showSnackBar(
              //   SnackBar(content: Text(isFavorite ? 'تمت الإزالة من المفضلة' : 'تمت الإضافة إلى المفضلة')),
              // );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('حدث خطأ: $e'), backgroundColor: Colors.red),
              );
            }
          },
        );
      },
    );
  }
}

