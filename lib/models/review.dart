import 'package:cloud_firestore/cloud_firestore.dart';

class Review {
  final String id; // Firestore document ID
  final String productId;
  final String userId;
  final String userName; // Store username for display
  final double rating; // e.g., 1.0 to 5.0
  final String comment;
  final Timestamp createdAt;
  // final bool isApproved; // Optional: for moderation

  Review({
    required this.id,
    required this.productId,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    // this.isApproved = false,
  });

  // Factory constructor from Firestore document
  factory Review.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Review(
      id: doc.id,
      productId: data['productId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'مستخدم غير معروف',
      rating: (data['rating'] ?? 0.0).toDouble(),
      comment: data['comment'] ?? '',
      createdAt: data['createdAt'] ?? Timestamp.now(),
      // isApproved: data['isApproved'] ?? false,
    );
  }

  // Method to convert to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'productId': productId,
      'userId': userId,
      'userName': userName,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt,
      // 'isApproved': isApproved,
    };
  }
}

