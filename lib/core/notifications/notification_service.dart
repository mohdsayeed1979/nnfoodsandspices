import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Local notifications always work (no external account needed) and back
/// order-update / offer notifications shown from within the app. Firebase
/// Cloud Messaging (for push notifications while the app is closed) only
/// activates when a real Firebase project has been wired up — this build
/// ships without `google-services.json` / `GoogleService-Info.plist`, so
/// [FirebaseMessaging] initialization is attempted and safely skipped on
/// failure rather than crashing the app.
class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final _localPlugin = FlutterLocalNotificationsPlugin();
  bool _firebaseReady = false;

  bool get isFirebaseReady => _firebaseReady;

  Future<void> init() async {
    await _initLocalNotifications();
    await _initFirebaseIfConfigured();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: iosInit, macOS: iosInit);
    await _localPlugin.initialize(settings);
  }

  Future<void> _initFirebaseIfConfigured() async {
    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
      await FirebaseMessaging.instance.requestPermission();
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      _firebaseReady = false;
      if (kDebugMode) {
        debugPrint(
          'Firebase not configured — push notifications disabled. '
          'Add google-services.json / GoogleService-Info.plist to enable FCM. ($e)',
        );
      }
    }
  }

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;
    showLocalNotification(title: notification.title ?? 'NN Food & Spices', body: notification.body ?? '');
  }

  Future<void> showLocalNotification({required String title, required String body}) async {
    const androidDetails = AndroidNotificationDetails(
      'nn_general_channel',
      'General Notifications',
      channelDescription: 'Order updates, offers and promotions',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails, iOS: DarwinNotificationDetails());
    await _localPlugin.show(DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body, details);
  }
}
