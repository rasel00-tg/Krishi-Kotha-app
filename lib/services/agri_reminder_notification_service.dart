import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/services/auth_service.dart';
import '../presentation/home/agri_reminder_alarm_screen.dart';

class AgriReminderNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  static const String channelId = 'krishi_kotha_agri_reminders';
  static const String channelName = 'কৃষি রিমাইন্ডার';
  static const String channelDescription =
      'সময়মতো কৃষি কাজের জরুরি সতর্কবার্তা ও পরামর্শ';

  static bool _isInitialized = false;

  /// Resolves active logged-in User ID from either FirebaseAuth or cached AuthService
  static Future<String?> getActiveUserId() async {
    try {
      final fbUser = FirebaseAuth.instance.currentUser;
      if (fbUser != null &&
          fbUser.uid.isNotEmpty &&
          !fbUser.uid.startsWith('guest_')) {
        return fbUser.uid;
      }
    } catch (_) {}

    try {
      final user = await AuthService().loadCachedUser();
      if (user != null &&
          user.uid.isNotEmpty &&
          !user.uid.startsWith('guest_')) {
        return user.uid;
      }
    } catch (_) {}

    return null;
  }

  /// Initialize local notification plugin, timezone and user reminder sync
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize timezone
      tz.initializeTimeZones();
      try {
        final dhaka = tz.getLocation('Asia/Dhaka');
        tz.setLocalLocation(dhaka);
      } catch (e) {
        debugPrint('Warning: Could not set Asia/Dhaka timezone, using local: $e');
      }

      // 2. Android Initialization Settings
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // 3. Darwin (iOS) Initialization Settings
      const DarwinInitializationSettings iosSettings =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notificationsPlugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
          _handleNotificationPayload(response.payload);
        },
      );

      // Check if application was launched via notification response
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null &&
          launchDetails.didNotificationLaunchApp &&
          launchDetails.notificationResponse != null) {
        _handleNotificationPayload(
            launchDetails.notificationResponse!.payload);
      }

      // 4. Create high-importance Android notification channel with Alarm attributes
      if (!kIsWeb && Platform.isAndroid) {
        final androidImplementation = _notificationsPlugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();

        if (androidImplementation != null) {
          const AndroidNotificationChannel channel = AndroidNotificationChannel(
            channelId,
            channelName,
            description: channelDescription,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
            audioAttributesUsage: AudioAttributesUsage.alarm,
          );
          await androidImplementation.createNotificationChannel(channel);

          // Request Android 13+ Notification Permissions
          await androidImplementation.requestNotificationsPermission();
          await androidImplementation.requestExactAlarmsPermission();
        }
      }

      _isInitialized = true;
      debugPrint('AgriReminderNotificationService initialized successfully.');

      // 5. Initial Sync: Check if an active logged-in user exists and sync reminders
      final activeUid = await getActiveUserId();
      if (activeUid != null) {
        debugPrint('Active user ($activeUid) detected on startup: Syncing agri reminders.');
        await syncUserReminders(activeUid);
      }

      // 6. Reactive FirebaseAuth state listener (with fallback check to avoid premature cancellation)
      FirebaseAuth.instance.authStateChanges().listen((User? user) async {
        if (user != null && !user.uid.startsWith('guest_')) {
          debugPrint('FirebaseAuth user logged in (${user.uid}): Syncing active agri reminders.');
          await syncUserReminders(user.uid);
        } else {
          // Verify with cached user before cancelling to protect custom/phone logins
          final cachedUid = await getActiveUserId();
          if (cachedUid == null) {
            debugPrint('No active user found: Cancelling all local agri reminders.');
            await cancelAllUserReminders();
          }
        }
      });
    } catch (e) {
      debugPrint('Error initializing AgriReminderNotificationService: $e');
    }
  }

  /// Handles notification response and navigates to Full-Screen Alarm Screen
  static void _handleNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    try {
      final data = json.decode(payload) as Map<String, dynamic>;
      openAlarmScreenDirectly(data);
    } catch (e) {
      debugPrint('Error handling reminder launch payload: $e');
    }
  }

  /// Directly opens the AgriReminderAlarmScreen using root navigator
  static void openAlarmScreenDirectly(Map<String, dynamic> reminderData) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (navigatorKey.currentState != null) {
        navigatorKey.currentState!.push(
          MaterialPageRoute(
            builder: (_) => AgriReminderAlarmScreen(reminderData: reminderData),
          ),
        );
      }
    });
  }

  /// Schedule a reminder notification locally on device
  static Future<bool> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
    required String reminderType, // 'temporary' | 'regular'
    required String repeatInterval, // 'none' | 'daily' | 'weekly'
    String category = 'সাধারণ',
    String timeText = '',
    String note = '',
  }) async {
    try {
      if (!_isInitialized) await initialize();

      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        audioAttributesUsage: AudioAttributesUsage.alarm,
        ongoing: true,
        autoCancel: false,
        playSound: true,
        enableVibration: true,
        icon: '@mipmap/ic_launcher',
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      const NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      final String payloadStr = json.encode({
        'notificationId': notificationId,
        'title': title,
        'category': category,
        'body': body,
        'reminderType': reminderType,
        'repeatInterval': repeatInterval,
        'scheduledDateTime': scheduledDateTime.toIso8601String(),
        'timeText': timeText,
        'note': note,
      });

      final tz.TZDateTime tzScheduledTime =
          tz.TZDateTime.from(scheduledDateTime, tz.local);

      if (reminderType == 'regular') {
        if (repeatInterval == 'daily') {
          // Daily repeated reminder
          DateTimeComponents matchComponent = DateTimeComponents.time;
          tz.TZDateTime firstTrigger = _nextInstanceOfTime(
              scheduledDateTime.hour, scheduledDateTime.minute);

          await _scheduleWithFallback(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: firstTrigger,
            notificationDetails: platformDetails,
            payload: payloadStr,
            matchDateTimeComponents: matchComponent,
          );
          debugPrint('Daily reminder scheduled: ID $notificationId at ${firstTrigger.toString()}');
          return true;
        } else if (repeatInterval == 'weekly') {
          // Weekly repeated reminder
          DateTimeComponents matchComponent =
              DateTimeComponents.dayOfWeekAndTime;
          tz.TZDateTime firstTrigger = _nextInstanceOfDayAndTime(
            scheduledDateTime.weekday,
            scheduledDateTime.hour,
            scheduledDateTime.minute,
          );

          await _scheduleWithFallback(
            id: notificationId,
            title: title,
            body: body,
            scheduledDate: firstTrigger,
            notificationDetails: platformDetails,
            payload: payloadStr,
            matchDateTimeComponents: matchComponent,
          );
          debugPrint('Weekly reminder scheduled: ID $notificationId at ${firstTrigger.toString()}');
          return true;
        }
      }

      // Temporary (Single event reminder)
      if (tzScheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
        debugPrint('Warning: Scheduled time is in the past ($tzScheduledTime). Not scheduling.');
        return false;
      }

      await _scheduleWithFallback(
        id: notificationId,
        title: title,
        body: body,
        scheduledDate: tzScheduledTime,
        notificationDetails: platformDetails,
        payload: payloadStr,
      );
      debugPrint('Temporary reminder scheduled: ID $notificationId at ${tzScheduledTime.toString()}');
      return true;
    } catch (e) {
      debugPrint('Error scheduling reminder $notificationId: $e');
      return false;
    }
  }

  /// Internal helper to schedule with exact or inexact fallback
  static Future<void> _scheduleWithFallback({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledDate,
    required NotificationDetails notificationDetails,
    String? payload,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      debugPrint('Exact alarm failed, falling back to inexactAllowWhileIdle: $e');
      await _notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    }
  }

  /// Helper for next instance of time for daily repetition
  static tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Helper for next instance of day & time for weekly repetition
  static tz.TZDateTime _nextInstanceOfDayAndTime(
      int weekday, int hour, int minute) {
    tz.TZDateTime scheduledDate = _nextInstanceOfTime(hour, minute);
    while (scheduledDate.weekday != weekday) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel a single scheduled reminder
  static Future<void> cancelReminder(int notificationId) async {
    try {
      await _notificationsPlugin.cancel(notificationId);
      debugPrint('Cancelled reminder ID: $notificationId');
    } catch (e) {
      debugPrint('Error cancelling reminder $notificationId: $e');
    }
  }

  /// Cancel all user reminders on logout or reset
  static Future<void> cancelAllUserReminders() async {
    try {
      await _notificationsPlugin.cancelAll();
      debugPrint('Cancelled all active scheduled reminders successfully.');
    } catch (e) {
      debugPrint('Error cancelling all reminders: $e');
    }
  }

  /// Resync active reminders from Firestore for the given user
  static Future<void> syncUserReminders(String userId) async {
    try {
      if (userId.trim().isEmpty) return;

      // Cancel local notifications first to prevent duplicates
      await cancelAllUserReminders();

      // Read max 5 active reminders from Firestore
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('agri_reminders')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('No active reminders to sync for user $userId.');
        return;
      }

      int scheduledCount = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final int notificationId = data['notificationId'] is int
            ? data['notificationId'] as int
            : (int.tryParse(data['notificationId']?.toString() ?? '') ??
                doc.id.hashCode.abs());

        final String title = data['title']?.toString() ?? 'কৃষি রিমাইন্ডার';
        final String category = data['category']?.toString() ?? 'সাধারণ';
        final String note = data['note']?.toString() ?? '';
        final String body = note.isNotEmpty ? '$category: $note' : category;
        final String reminderType =
            data['reminderType']?.toString() ?? 'temporary';
        final String repeatInterval =
            data['repeatInterval']?.toString() ?? 'none';

        DateTime? scheduledDate;
        if (data['scheduledDateTime'] != null) {
          if (data['scheduledDateTime'] is Timestamp) {
            scheduledDate = (data['scheduledDateTime'] as Timestamp).toDate();
          } else if (data['scheduledDateTime'] is String) {
            scheduledDate =
                DateTime.tryParse(data['scheduledDateTime'] as String);
          }
        }

        if (scheduledDate != null) {
          final ok = await scheduleReminder(
            notificationId: notificationId,
            title: title,
            body: body,
            scheduledDateTime: scheduledDate,
            reminderType: reminderType,
            repeatInterval: repeatInterval,
            category: category,
            timeText: data['timeText']?.toString() ?? '',
            note: note,
          );
          if (ok) scheduledCount++;
        }
      }

      debugPrint('Synced and scheduled $scheduledCount active reminders for user $userId.');
    } catch (e) {
      debugPrint('Error syncing user reminders: $e');
    }
  }
}
