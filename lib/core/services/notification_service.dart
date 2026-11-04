import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as timezone_data;
import 'package:timezone/timezone.dart' as timezone;

class NotificationService {
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _budgetChannel =
      AndroidNotificationChannel(
        'budget_alerts',
        'Alertes budgétaires',
        description: 'Notifications concernant les budgets et dépenses.',
        importance: Importance.high,
      );
  static const int _renewalNotificationId = 1001;

  NotificationService._();

  static final NotificationService instance = NotificationService._();

  Future<void> initialize() async {
    timezone_data.initializeTimeZones();

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('ic_notification');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
    );

    await _notificationsPlugin.initialize(settings: settings);

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.createNotificationChannel(_budgetChannel);

    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_alerts',
          'Alertes budgétaires',
          channelDescription:
              'Notifications concernant les budgets et dépenses.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notificationsPlugin.show(
      id: 0,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> scheduleRenewal(DateTime renewalDate) async {
    await _notificationsPlugin.cancel(id: _renewalNotificationId);

    final localSchedule = DateTime(
      renewalDate.year,
      renewalDate.month,
      renewalDate.day,
      9,
    );
    final scheduledDate = timezone.TZDateTime.from(
      localSchedule,
      timezone.local,
    );
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'budget_alerts',
          'Alertes budgétaires',
          channelDescription:
              'Notifications concernant les budgets et dépenses.',
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        );

    await _notificationsPlugin.zonedSchedule(
      id: _renewalNotificationId,
      title: 'Renouvellement du salaire',
      body: 'Votre nouveau cycle budgétaire commence aujourd’hui.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }
}
