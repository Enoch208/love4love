import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin = 
      FlutterLocalNotificationsPlugin();
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  // Initialize notification services
  Future<void> initialize() async {
    // Request permission for notifications
    await _requestPermissions();

    // Initialize local notifications
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidSettings);
    
    await _flutterLocalNotificationsPlugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        if (kDebugMode) {
          print('Notification tapped: ${response.payload}');
        }
      },
    );

    // Configure Firebase Cloud Messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showNotificationFromRemoteMessage(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('App opened from notification: ${message.data}');
      }
    });
  }

  // Request notification permissions
  Future<void> _requestPermissions() async {
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  // Subscribe to topics for receiving notifications
  Future<void> subscribeToTopic(String topic) async {
    await _firebaseMessaging.subscribeToTopic(topic);
  }

  // Unsubscribe from topics
  Future<void> unsubscribeFromTopic(String topic) async {
    await _firebaseMessaging.unsubscribeFromTopic(topic);
  }

  // Show a local notification
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'dating_app_channel',
      'Dating App Notifications',
      channelDescription: 'Notifications for dating app matches and likes',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformDetails = 
        NotificationDetails(android: androidDetails);
    
    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecond, // Unique ID based on current time
      title,
      body,
      platformDetails,
      payload: payload,
    );
  }

  // Show notification from FCM remote message
  Future<void> _showNotificationFromRemoteMessage(RemoteMessage message) async {
    final RemoteNotification? notification = message.notification;
    if (notification != null) {
      await showLocalNotification(
        title: notification.title ?? 'New Notification',
        body: notification.body ?? '',
        payload: message.data.toString(),
      );
    }
  }

  // Store user's FCM token in Firestore for sending targeted notifications
  Future<void> saveUserToken() async {
    try {
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final String? token = await _firebaseMessaging.getToken();
        if (token != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .update({
            'fcmToken': token,
            'tokenUpdatedAt': FieldValue.serverTimestamp(),
          });
          if (kDebugMode) {
            print('FCM Token saved for user: ${user.uid}');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving FCM token: $e');
      }
    }
  }

  // Send a notification when someone likes a user's profile
  Future<void> sendLikeNotification({
    required String toUserId,
    required String fromUserName,
    bool isMatch = false,
  }) async {
    try {
      // Get the user document to find their FCM token
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(toUserId)
          .get();
      
      if (!userDoc.exists) return;
      
      final userData = userDoc.data();
      final String? fcmToken = userData?['fcmToken'];
      
      if (fcmToken == null) {
        // If no FCM token, create a notification in Firestore for the user to see next time they log in
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': toUserId,
          'title': isMatch ? 'New Match!' : 'New Like!',
          'body': isMatch 
              ? 'You and $fromUserName liked each other!'
              : '$fromUserName liked your profile!',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'type': isMatch ? 'match' : 'like',
        });
      } else {
        // For a real app, you would use Firebase Cloud Functions or a server to send the actual FCM message
        // This is just a placeholder for the server-side code
        if (kDebugMode) {
          print('Would send FCM notification to token: $fcmToken');
        }
        
        // For now, we'll just create a notification in Firestore
        await FirebaseFirestore.instance.collection('notifications').add({
          'to': toUserId,
          'title': isMatch ? 'New Match!' : 'New Like!',
          'body': isMatch 
              ? 'You and $fromUserName liked each other!'
              : '$fromUserName liked your profile!',
          'read': false,
          'timestamp': FieldValue.serverTimestamp(),
          'type': isMatch ? 'match' : 'like',
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error sending like notification: $e');
      }
    }
  }
} 