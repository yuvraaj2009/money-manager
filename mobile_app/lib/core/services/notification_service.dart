import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../models/budget_model.dart';
import '../../models/transaction_model.dart';
import '../utils/formatters.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  static const int _weeklyReminderId = 7001;
  static const int _largeTransactionThresholdPaise = 200000;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  SharedPreferences? _preferences;
  bool _initialized = false;

  bool get _supportsNotifications =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (!_supportsNotifications) {
      _initialized = true;
      return;
    }

    _preferences = await SharedPreferences.getInstance();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _notifications.initialize(settings: initializationSettings);

    tz_data.initializeTimeZones();
    try {
      final timezoneInfo = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezoneInfo.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    _initialized = true;
    await _scheduleWeeklyReminderInternal();
  }

  Future<void> showBudgetThresholdNotifications(
    BudgetUtilizationModel utilization,
  ) async {
    if (!_supportsNotifications) {
      return;
    }

    await initialize();
    for (final alert in utilization.alerts) {
      if (alert.utilizationPercentage < 80) {
        continue;
      }
      final key =
          'budget_${utilization.year}_${utilization.month}_${alert.categoryId}';
      if (_preferences?.getBool(key) ?? false) {
        continue;
      }

      await _notifications.show(
        id: _stableId(key, 1100),
        title: 'Budget Alert',
        body:
            '${alert.categoryName} budget ${alert.utilizationPercentage.toStringAsFixed(0)}% used this month',
        notificationDetails: _budgetNotificationDetails,
      );
      await _preferences?.setBool(key, true);
    }
  }

  Future<void> showLargeTransactionNotification(
    TransactionModel transaction,
  ) async {
    if (!_supportsNotifications ||
        !transaction.isExpense ||
        transaction.amount.abs() < _largeTransactionThresholdPaise) {
      return;
    }

    await initialize();
    final key = 'transaction_${transaction.id}';
    if (_preferences?.getBool(key) ?? false) {
      return;
    }

    final now = DateTime.now();
    final sameDay = transaction.date.year == now.year &&
        transaction.date.month == now.month &&
        transaction.date.day == now.day;
    final amountText =
        AppFormatters.currencyFromPaise(transaction.amount.abs());
    final body = sameDay
        ? 'You spent $amountText today'
        : 'Large transaction recorded for ${AppFormatters.shortDate(transaction.date)}';

    await _notifications.show(
      id: _stableId(key, 2200),
      title: 'Spending Alert',
      body: body,
      notificationDetails: _spendingNotificationDetails,
    );
    await _preferences?.setBool(key, true);
  }

  Future<void> scheduleWeeklyReminder() async {
    if (!_supportsNotifications) {
      return;
    }
    await initialize();
    await _scheduleWeeklyReminderInternal();
  }

  Future<void> _scheduleWeeklyReminderInternal() async {
    await _notifications.cancel(id: _weeklyReminderId);
    await _notifications.zonedSchedule(
      id: _weeklyReminderId,
      title: 'Money Manager',
      body: 'Weekly spending summary available',
      scheduledDate: _nextSundayEvening(),
      notificationDetails: _reminderNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  tz.TZDateTime _nextSundayEvening() {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      19,
    );

    while (scheduled.weekday != DateTime.sunday || !scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  int _stableId(String value, int offset) {
    var hash = 0;
    for (final codeUnit in value.codeUnits) {
      hash = ((hash * 31) + codeUnit) & 0x7fffffff;
    }
    return offset + (hash % 100000);
  }

  NotificationDetails get _budgetNotificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget_alerts',
          'Budget Alerts',
          channelDescription:
              'Alerts when a household budget reaches 80% usage.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

  NotificationDetails get _spendingNotificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'spending_alerts',
          'Spending Alerts',
          channelDescription: 'Alerts for large spending activity.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      );

  NotificationDetails get _reminderNotificationDetails =>
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'weekly_reminders',
          'Weekly Reminders',
          channelDescription: 'Weekly reminders to review household spending.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
      );
}
