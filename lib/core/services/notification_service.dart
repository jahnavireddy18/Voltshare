import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // If you're going to use other Firebase services in the background, such as Firestore,
  // make sure you call `initializeApp` before using other Firebase services.
  debugPrint("Handling a background message: ${message.messageId}");
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  GoRouter? _router;

  Future<void> initialize(GoRouter router) async {
    _router = router;

    // Request permissions (Apple & Web)
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    // Set background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Setup local notifications for Android foreground
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
    // Create Android channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel', // id
      'High Importance Notifications', // name
      description:
          'This channel is used for important notifications.', // description
      importance: Importance.max,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null && !kIsWeb) {
        _localNotifications.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id,
              channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
              color: Color(0xFF0DCA7A),
            ),
          ),
          payload: jsonEncode(message.data),
        );
      }
    });

    // Handle when app is opened from a notification (terminated or background)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpen);

    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpen(initialMessage);
    }
  }

  Future<void> _onNotificationTap(NotificationResponse response) async {
    if (response.payload != null) {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      _routeFromData(data);
    }
  }

  void _handleMessageOpen(RemoteMessage message) {
    _routeFromData(message.data);
  }

  void _routeFromData(Map<String, dynamic> data) {
    if (_router == null) return;

    final action = data['action'] as String?;
    if (action == 'view_booking') {
      _router!.go('/home'); // In a real app, go to specific booking
    } else if (action == 'open_session') {
      _router!.go('/active-session');
    } else if (action == 'open_dashboard') {
      _router!.go('/host-telemetry');
    }
  }

  Future<void> registerToken(String userId) async {
    try {
      final token = await _fcm.getToken();
      if (token != null) {
        await FirebaseFirestore.instance.collection('users').doc(userId).set({
          'fcmTokens': FieldValue.arrayUnion([token]),
        }, SetOptions(merge: true));

        // Listen for token refreshes
        _fcm.onTokenRefresh.listen((newToken) {
          FirebaseFirestore.instance.collection('users').doc(userId).set({
            'fcmTokens': FieldValue.arrayUnion([newToken]),
          }, SetOptions(merge: true));
        });
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }
}
