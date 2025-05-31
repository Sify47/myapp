import 'package:cloud_firestore/cloud_firestore.dart';

class Offer {
  final String id;
  final String title;
  final String description;
  final String image; // URL to the offer image
  final String category;
  final String? offerCode; // Optional offer code
  final Timestamp? expiryDate; // Optional expiry date
  final String brandName; // Keep brand name as per existing structure, or change to brandId
  // final String brandId; // Alternative: Use brandId for consistency with Product model
  final String? productId; // Optional: Link to a specific Product ID
  final String offerType; // e.g., 'standalone', 'product_discount', 'informational'
  final Timestamp createdAt;
  final Timestamp updatedAt;

  Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.image,
    required this.category,
    this.offerCode,
    this.expiryDate,
    required this.brandName,
    // required this.brandId,
    this.productId,
    required this.offerType,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor to create an Offer from a Firestore document
  factory Offer.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    Timestamp? parseExpiryDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue;
      } else if (dateValue is String) {
        try {
          // Attempt to parse if it's a string like 'YYYY-MM-DD'
          // Note: Firestore typically stores dates as Timestamps.
          // Parsing string dates here might indicate an issue in data saving.
          // Consider saving dates as Timestamps directly.
          DateTime parsed = DateTime.parse(dateValue);
          return Timestamp.fromDate(parsed);
        } catch (e) {
          return null; // Handle parsing error
        }
      }
      return null;
    }

    return Offer(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      image: data['image'] ?? '',
      category: data['category'] ?? '',
      offerCode: data['offerCode'],
      expiryDate: parseExpiryDate(data['expiry']), // Handle potential String or Timestamp
      brandName: data['name'] ?? '', // Assuming 'name' field holds brand name
      // brandId: data['brandId'] ?? '', // If using brandId
      productId: data['productId'], // Optional field
      offerType: data['offerType'] ?? 'standalone', // Default type
      createdAt: data['timestamp'] ?? data['createdAt'] ?? Timestamp.now(), // Check for legacy 'timestamp'
      updatedAt: data['updatedAt'] ?? Timestamp.now(),
    );
  }

  // Method to convert an Offer instance to a map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'image': image,
      'category': category,
      'offerCode': offerCode,
      'expiry': expiryDate, // Save as Timestamp
      'name': brandName, // Keep 'name' for consistency with existing data
      // 'brandId': brandId, // If using brandId
      'productId': productId,
      'offerType': offerType,
      'createdAt': createdAt,
      'updatedAt': updatedAt, // Ensure this is updated on edits
      // 'timestamp': createdAt, // Avoid redundant legacy field if possible
    };
  }
}

