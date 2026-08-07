import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../firebase_options.dart';
import '../network/api_client.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  developer.log("Handling background message: ${message.messageId}");
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'lumo_high_importance_channel',
    'LUMO Important Notifications',
    description: 'Used for booking updates, safety alerts, and important messages.',
    importance: Importance.max,
  );

  /// Initializes Firebase and FCM notification services
  static Future<void> initialize() async {
    // 1. Initialize Firebase Core
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // 2. Request User Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    developer.log('User notification permission status: ${settings.authorizationStatus}');

    // Enable foreground notification presentation for iOS & Android
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 3. Register Background Message Handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // 4. Initialize Local Notifications Plugin FIRST (required before any platform-specific calls)
    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        developer.log('Foreground notification tapped: ${response.payload}');
      },
    );

    // 5. Now request Android 13+ notification permission & create channel (after init)
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.createNotificationChannel(_channel);

    // 5. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log("Received foreground message: ${message.notification?.title}");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null) {
        _localNotifications.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android?.smallIcon ?? '@mipmap/ic_launcher',
              importance: Importance.max,
              priority: Priority.high,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
            ),
          ),
          payload: message.data.toString(),
        );
      }
    });

    // 6. Handle App Launch from Terminated State
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessageOpened(initialMessage);
    }

    // 7. Handle App Launch from Background State
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpened);

    // 8. Listen for Token Refresh (re-sync when token rotates)
    _messaging.onTokenRefresh.listen((newToken) {
      ApiClient.updateFcmToken(newToken);
    });
    // NOTE: Initial FCM token sync happens in syncFcmTokenAfterLogin() after user authenticates
  }

  /// Get device FCM token (does NOT upload — call syncFcmTokenAfterLogin() after auth)
  static Future<String?> getToken() async {
    try {
      String? token = await _messaging.getToken();
      developer.log("FCM Device Token: $token");
      return token;
    } catch (e) {
      developer.log("Error fetching FCM token: $e");
      return null;
    }
  }

  /// Call this immediately after the user successfully logs in / authenticates.
  /// Uploads the current FCM token to the backend so push notifications work.
  static Future<void> syncFcmTokenAfterLogin() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        developer.log("Syncing FCM token to backend after login: ${token.substring(0, 20)}...");
        await ApiClient.updateFcmToken(token);
      }
    } catch (e) {
      developer.log("Error syncing FCM token after login: $e");
    }
  }

  /// Route/Action handler when notification is tapped
  static void _handleMessageOpened(RemoteMessage message) {
    developer.log("Notification opened with payload data: ${message.data}");
    // Example: Navigate to booking or safety screen using payload data
  }
}
