import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    const settings = InitializationSettings(android: android, iOS: ios);
    await _plugin.initialize(settings);
  }

  // جدولة تنبيه انتهاء المحلول
  Future<void> scheduleInfusionEnd({
    required int id,
    required String patientName,
    required String salineType,
    required Duration after,
  }) async {
    final scheduledDate = tz.TZDateTime.now(tz.local).add(after);

    const androidDetails = AndroidNotificationDetails(
      'infusion_channel',
      'تنبيهات المحاليل الوريدية',
      channelDescription: 'تنبيه عند انتهاء وقت المحلول',
      importance: Importance.max,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('infusion_alarm'),
      playSound: true,
      enableVibration: true,
      color: Color(0xFF0E7490),
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: 'infusion_alarm.aiff',
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      'انتهى وقت المحلول 💧',
      'المريض: $patientName | المحلول: $salineType - يرجى المتابعة',
      scheduledDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: 
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelInfusion(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  // إشعار فوري للاختبار
  Future<void> showInstantTest() async {
    const androidDetails = AndroidNotificationDetails(
      'test_channel',
      'اختبار',
      importance: Importance.high,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _plugin.show(999, 'اختبار الإشعارات ✅', 'الإشعارات تعمل بشكل صحيح', details);
  }
}

