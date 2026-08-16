import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:sakan_app/core/api/dio_client.dart';

final pushNotificationServiceProvider = Provider((ref) => PushNotificationService(ref));

class PushNotificationService {
  final Ref _ref;
  PushNotificationService(this._ref);

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // 2. Initialize Local Notifications for Foreground
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
        // Handle notification tap in foreground
        if (details.payload != null) {
          _handleNotificationClick(details.payload!);
        }
      },
    );

    // 3. Register Token
    if (settings.authorizationStatus == AuthorizationStatus.authorized ||
        settings.authorizationStatus == AuthorizationStatus.provisional) {
      await registerDevice();
    }

    // 4. Listeners
    FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      registerDevice(token);
    });

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Got a message whilst in the foreground!');
      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // Background/Terminated listeners
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationClickFromMessage(message);
    });

    // Check if the app was opened from a terminated state
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationClickFromMessage(initialMessage);
    }
  }

  Future<void> registerDevice([String? token]) async {
    try {
      token ??= await _messaging.getToken();
      if (token == null) return;

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

      await _ref.read(dioProvider).delete('/users/me/fcm-token', data: {
        'token': token,
      });
      debugPrint('FCM Token unregistered successfully');
    } catch (e) {
      debugPrint('Failed to unregister FCM token: $e');
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
      largeIcon: DrawableResourceAndroidBitmap('@mipmap/ic_launcher'), // ده اللي هيخلي اللوجو الملون يظهر
      color: Color(0xFFC6FF3D), // لون عقارو الفسفوري/الأخضر من اللوجو
      enableLights: true,
      showWhen: true,
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
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
    try {
      final Map<String, dynamic> data = jsonDecode(payload);
      debugPrint('Notification clicked with data: $data');

      final String? type = data['type'];
      final String? id = data['id'];

      // TODO: Handle navigation based on type and id
      // Example: if (type == 'property') navigate to details(id)
    } catch (e) {
      debugPrint('Error parsing notification payload: $e');
    }
  }
}
