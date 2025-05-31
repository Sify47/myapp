import 'package:flutter/material.dart';
import 'package:myapp/pages/checkout_page.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
// import 'checkout_page.dart'; // Placeholder for checkout navigation

class CartPage extends StatelessWidget {
  const CartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('سلة التسوق'),
        centerTitle: true,
      ),
      body: StreamBuilder<List<CartItem>>(
        stream: cartService.getCartItemsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'سلة التسوق فارغة.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final cartItems = snapshot.data!;
          // Calculate total price
          double totalPrice = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final item = cartItems[index];
                    final itemDocId = item.variantSku ?? item.productId; // Use the same ID logic as in service
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Row(
                          children: [
                            // Image
                            SizedBox(
                              width: 70,
                              height: 70,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: item.productImageUrl != null
                                    ? Image.network(
                                        item.productImageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image_not_supported, color: Colors.grey),
                                      )
                                    : const Icon(Icons.image_not_supported, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.productName,
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    '${item.discountPrice ?? item.price} ر.س',
                                    style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.w600),
                                  ),
                                  // TODO: Display selected attributes if any
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            // Quantity Control & Remove
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline, size: 20, color: Colors.redAccent),
                                      onPressed: () {
                                        if (item.quantity > 1) {
                                          cartService.updateItemQuantity(itemDocId, item.quantity - 1);
                                        } else {
                                          // Optional: Confirm before removing last item
                                          cartService.removeItemFromCart(itemDocId);
                                        }
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                    Text('${item.quantity}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline, size: 20, color: Colors.green),
                                      onPressed: () {
                                        // TODO: Check against available stock before increasing
                                        cartService.updateItemQuantity(itemDocId, item.quantity + 1);
                                      },
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 22, color: Colors.grey),
                                  onPressed: () {
                                    cartService.removeItemFromCart(itemDocId);
                                  },
                                   padding: const EdgeInsets.only(top: 8),
                                   constraints: const BoxConstraints(),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Total and Checkout Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'المجموع: ${totalPrice.toStringAsFixed(2)} ر.س',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        // Navigate to Checkout Page
                        Navigator.push(context, MaterialPageRoute(builder: (_) => CheckoutPage()));
                        //  ScaffoldMessenger.of(context).showSnackBar(
                        //    const SnackBar(content: Text('سيتم إضافة صفحة الدفع قريباً.')),
                        //  );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
                        textStyle: const TextStyle(fontSize: 16)
                      ),
                      child: const Text('إتمام الشراء'),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

