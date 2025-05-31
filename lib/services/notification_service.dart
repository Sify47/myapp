import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Function to handle background messages (must be top-level)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, like Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  // await Firebase.initializeApp(); // Usually initialized in main

  print("Handling a background message: ${message.messageId}");
  // You can process the message here (e.g., show a local notification)
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> initialize() async {
    // Request permission for iOS and web
    NotificationSettings settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('User granted permission: ${settings.authorizationStatus}');

    // Get the FCM token
    await _getAndSaveDeviceToken();

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen(_getAndSaveDeviceToken);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        // TODO: Display the notification using a local notifications package (e.g., flutter_local_notifications)
        // Or update the UI directly if needed
      }
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle notification tap when app is terminated/background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('A new onMessageOpenedApp event was published!');
      // TODO: Navigate to a specific screen based on message data
      // e.g., if it's an order update, navigate to the order details page
    });

     // Check if app was opened from a terminated state via notification
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
       print('App opened from terminated state via notification!');
       // TODO: Handle initial message navigation
    }

  }

  Future<void> _getAndSaveDeviceToken([String? token]) async {
    final user = _auth.currentUser;
    if (user == null) {
      print("User not logged in, cannot save FCM token.");
      return;
    }

    try {
      String? currentToken = token; // Use provided token if available (from onTokenRefresh)
      if (currentToken == null) {
         if (kIsWeb) {
           // Use VAPID key for web
           // IMPORTANT: Replace 'YOUR_VAPID_KEY' with your actual VAPID key from Firebase Console
           currentToken = await _firebaseMessaging.getToken(vapidKey: 'BIEzW9tqsiO59BYyH5eAMCacCe0johqcfjV5DwdjXkbviJkydUK1w7bLBixGJ3ZJ0VEgNkl11Aer28ywLpg2k2s');
         } else {
           currentToken = await _firebaseMessaging.getToken();
         }
      }

      if (currentToken != null) {
        print('FCM Token: $currentToken');
        // Save the token to Firestore under the user's document
        // Store tokens in a subcollection or an array field
        final userRef = _firestore.collection('users').doc(user.uid);
        await userRef.set({
          'fcmTokens': FieldValue.arrayUnion([currentToken])
        }, SetOptions(merge: true)); // Use merge to avoid overwriting other user data
        print('FCM token saved for user ${user.uid}');
      } else {
         print('Failed to get FCM token.');
      }
    } catch (e) {
      print('Error getting/saving FCM token: $e');
    }
  }

  // TODO: Add method to remove token on logout if needed
  Future<void> removeDeviceToken() async {
     final user = _auth.currentUser;
     if (user == null) return;
     try {
        String? currentToken;
        if (kIsWeb) {
           currentToken = await _firebaseMessaging.getToken(vapidKey: 'BIEzW9tqsiO59BYyH5eAMCacCe0johqcfjV5DwdjXkbviJkydUK1w7bLBixGJ3ZJ0VEgNkl11Aer28ywLpg2k2s');
        } else {
           currentToken = await _firebaseMessaging.getToken();
        }
        if (currentToken != null) {
           final userRef = _firestore.collection('users').doc(user.uid);
           await userRef.update({
             'fcmTokens': FieldValue.arrayRemove([currentToken])
           });
           print('FCM token removed for user ${user.uid}');
        }
     } catch (e) {
        print('Error removing FCM token: $e');
     }
  }

  // --- Methods to trigger notifications (usually called from backend/Cloud Functions) ---
  // Example: Send notification when order status changes (implement in Cloud Function)
  // Example: Send notification for new offers (implement in Cloud Function or admin panel)
}

