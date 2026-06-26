import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/utils/navigation_service.dart';
import 'api_service.dart';

const _channelId = 'clinic_high';
const _channelName = 'ການແຈ້ງເຕືອນຄລີນິກ';

final _localNotif = FlutterLocalNotificationsPlugin();

/// Background message handler — ຕ້ອງເປັນ top-level function
@pragma('vm:entry-point')
Future<void> _bgHandler(RemoteMessage message) async {
  debugPrint('[FCM] background: ${message.notification?.title}');
}

class FcmService {
  FcmService._();

  static final _fcm = FirebaseMessaging.instance;

  /// ເອີ້ນ 1 ຄັ້ງຫຼັງ Firebase.initializeApp() ໃນ main()
  static Future<void> init() async {
    FirebaseMessaging.onBackgroundMessage(_bgHandler);

    // ສ້າງ notification channel priority HIGH ສຳລັບ Android 8+
    const androidChannel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _localNotif.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );

    await _localNotif
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);

    // ບອກ FCM ໃຊ້ channel ນີ້ສຳລັບ foreground notifications
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true, badge: true, sound: true,
    );

    FirebaseMessaging.onMessage.listen(_onForeground);
    FirebaseMessaging.onMessageOpenedApp.listen(_onTap);
  }

  /// ເອີ້ນຫຼັງ login ສຳເລັດ
  static Future<void> register() async {
    try {
      final settings = await _fcm.requestPermission(
        alert: true, badge: true, sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;

      final token = await _fcm.getToken();
      if (token == null) return;

      await ApiService.put('/api/me/device-token', {
        'token': token,
        'platform': 'android',
      });
      debugPrint('[FCM] token registered ✅');

      _fcm.onTokenRefresh.listen((newToken) async {
        await ApiService.put('/api/me/device-token', {
          'token': newToken,
          'platform': 'android',
        });
      });
    } catch (e) {
      debugPrint('[FCM] register error: $e');
    }
  }

  /// ເອີ້ນຫຼັງ logout
  static Future<void> unregister() async {
    try {
      await ApiService.delete('/api/me/device-token');
      await _fcm.deleteToken();
      debugPrint('[FCM] token removed ✅');
    } catch (_) {}
  }

  // ── Foreground notification (app ເປີດຢູ່) ──────────────────────────
  static void _onForeground(RemoteMessage message) {
    final n = message.notification;
    if (n == null) return;

    // ສະແດງ system notification ເມື່ອ app ເປີດ (Android ປົກກະຕິຈະບໍ່ສະແດງ)
    _localNotif.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
      ),
    );

    // ສະແດງ SnackBar ໃນ app ດ້ວຍ
    final ctx = NavigationService.navigatorKey.currentContext;
    if (ctx == null) return;
    ScaffoldMessenger.of(ctx).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(n.title ?? '',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            if (n.body != null)
              Text(n.body!,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13)),
          ],
        ),
        backgroundColor: const Color(0xFF1B4332),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  // ── User tap notification (background → open) ────────────────────────
  static void _onTap(RemoteMessage message) {
    final bookingId = message.data['booking_id'];
    if (bookingId == null) return;
    debugPrint('[FCM] tapped → booking_id=$bookingId');
  }
}
