import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sakan_app/core/api/dio_client.dart';

// معالج الرسائل في الخلفية
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}

final pushNotificationServiceProvider = Provider((ref) => PushNotificationService(ref));

class PushNotificationService {
  final Ref _ref;
  PushNotificationService(this._ref);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // إعداد معالج الخلفية
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // طلب الإذن
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // إعداد الإشعارات المحلية
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings();
    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          _handleNotificationClick(details.payload!);
        }
      },
    );

    // تسجيل الجهاز وجلب التوكن
    await registerDevice();

    // مستمع لتحديث التوكن
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      registerDevice(token);
    });

    // مستمع للرسائل أثناء فتح التطبيق
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // مستمع للضغط على الإشعار والتطبيق في الخلفية
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClickFromMessage(message);
    });

    // التحقق إذا تم فتح التطبيق من إشعار وهو مغلق تماماً
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClickFromMessage(initialMessage);
    }
  }

  Future<void> registerDevice([String? token]) async {
    try {
      token ??= await _messaging.getToken();
      if (token == null) {
        debugPrint('FCM Token is null');
        return;
      }

      debugPrint('---------------- FCM TOKEN START ----------------');
      debugPrint(token);
      debugPrint('---------------- FCM TOKEN END ------------------');

      final deviceId = await _getDeviceId();
      final platform = Platform.isAndroid ? 'android' : 'ios';

      await _ref.read(dioProvider).patch('/users/me/fcm-token', data: {
        'token': token,
        'platform': platform,
        'deviceId': deviceId,
      });
      debugPrint('FCM Token registered successfully');
    } catch (e) {
      debugPrint('Failed to register FCM token: $e');
    }
  }

  Future<void> unregisterDevice() async {
    try {
      String? token = await _messaging.getToken();
      if (token == null) return;
      await _ref.read(dioProvider).delete('/users/me/fcm-token', data: {'token': token});
    } catch (e) {
      debugPrint('Failed to unregister: $e');
    }
  }

  Future<String?> _getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor;
    }
    return null;
  }

  void _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFC6FF3D),
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: jsonEncode(message.data),
    );
  }

  void _handleNotificationClickFromMessage(RemoteMessage message) {
    _handleNotificationClick(jsonEncode(message.data));
  }

  void _handleNotificationClick(String payload) {
    debugPrint('Notification clicked: $payload');
  }
}
