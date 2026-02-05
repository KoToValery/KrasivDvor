import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../../../models/care_reminder.dart';
import '../../../models/plant_instance.dart';
import 'dart:convert';

class NotificationService {
  FirebaseMessaging? _firebaseMessaging;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _initialized = false;
  bool _firebaseAvailable = false;

  /// Initialize notification services
  Future<void> initialize() async {
    if (_initialized) return;
    
    // Initialize timezone data
    tz.initializeTimeZones();
    
    // Check if Firebase is available
    try {
      // Accessing instance will throw if Firebase is not initialized
      _firebaseMessaging = FirebaseMessaging.instance;
      _firebaseAvailable = true;
    } catch (e) {
      print('Firebase Messaging not available: $e');
      _firebaseAvailable = false;
    }

    if (_firebaseAvailable && _firebaseMessaging != null) {
      // Request permission for iOS
      await _requestPermission();
    }
    
    // Initialize local notifications
    await _initializeLocalNotifications();
    
    if (_firebaseAvailable && _firebaseMessaging != null) {
      // Configure Firebase messaging
      await _configureFCM();
    }
    
    _initialized = true;
  }

  /// Request notification permissions
  Future<void> _requestPermission() async {
    if (_firebaseMessaging == null) return;
    try {
      final settings = await _firebaseMessaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional notification permission');
      } else {
        print('User declined or has not accepted notification permission');
      }
    } catch (e) {
      print('Error requesting permission: $e');
    }
  }

  /// Initialize local notifications plugin
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  /// Configure Firebase Cloud Messaging
  Future<void> _configureFCM() async {
    if (_firebaseMessaging == null) return;

    // Get FCM token
    final token = await _firebaseMessaging!.getToken();
    print('FCM Token: $token');
    
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationOpened);
    
    // Check if app was opened from a notification
    final initialMessage = await _firebaseMessaging!.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationOpened(initialMessage);
    }
  }

  /// Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    // Show local notification when app is in foreground
    if (message.notification != null) {
      _showLocalNotification(
        title: message.notification!.title ?? 'Напомняне за грижи',
        body: message.notification!.body ?? '',
        payload: json.encode(message.data),
      );
    }
  }

  /// Handle notification opened
  void _handleNotificationOpened(RemoteMessage message) {
    print('Notification opened: ${message.messageId}');
    
    // Navigate to appropriate screen based on notification data
    final reminderId = message.data['reminderId'] as String?;
    if (reminderId != null) {
      // TODO: Navigate to reminder detail screen
      print('Navigate to reminder: $reminderId');
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Notification tapped: ${response.id}');
    
    if (response.payload != null) {
      final data = json.decode(response.payload!) as Map<String, dynamic>;
      final reminderId = data['reminderId'] as String?;
      
      if (reminderId != null) {
        // TODO: Navigate to reminder detail screen
        print('Navigate to reminder: $reminderId');
      }
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'care_reminders',
      'Напомняния за грижи',
      channelDescription: 'Напомняния за поливане, торене и други грижи за растенията',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Schedule a local notification for a care reminder
  Future<void> scheduleReminderNotification(CareReminder reminder) async {
    if (!_initialized) {
      await initialize();
    }
    
    final title = _getReminderTitle(reminder.careType);
    final body = reminder.instructions;
    
    const androidDetails = AndroidNotificationDetails(
      'care_reminders',
      'Напомняния за грижи',
      channelDescription: 'Напомняния за поливане, торене и други грижи за растенията',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.zonedSchedule(
      reminder.id.hashCode,
      title,
      body,
      _convertToTZDateTime(reminder.scheduledDate),
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: json.encode({
        'reminderId': reminder.id,
        'careType': reminder.careType.name,
      }),
    );
  }

  /// Cancel a scheduled notification
  Future<void> cancelReminderNotification(String reminderId) async {
    await _localNotifications.cancel(reminderId.hashCode);
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Get reminder title based on care type
  String _getReminderTitle(CareType careType) {
    switch (careType) {
      case CareType.watering:
        return 'Време за поливане 💧';
      case CareType.fertilizing:
        return 'Време за торене 🌱';
      case CareType.pruning:
        return 'Време за подрязване ✂️';
      case CareType.weeding:
        return 'Време за плевене 🌿';
      case CareType.mulching:
        return 'Време за мулчиране 🍂';
      case CareType.pestControl:
        return 'Контрол на вредители 🐛';
      case CareType.diseaseControl:
        return 'Контрол на болести 🔬';
      case CareType.other:
        return 'Напомняне за грижи 🌸';
    }
  }

  /// Convert DateTime to TZDateTime for scheduling
  tz.TZDateTime _convertToTZDateTime(DateTime dateTime) {
    final location = tz.getLocation('Europe/Sofia'); // Bulgarian timezone
    return tz.TZDateTime.from(dateTime, location);
  }

  /// Get FCM token for push notifications
  Future<String?> getFCMToken() async {
    if (_firebaseMessaging == null) return null;
    return await _firebaseMessaging!.getToken();
  }

  /// Subscribe to topic for broadcast notifications
  Future<void> subscribeToTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.subscribeToTopic(topic);
  }

  /// Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    if (_firebaseMessaging == null) return;
    await _firebaseMessaging!.unsubscribeFromTopic(topic);
  }
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');
  // Handle background message
}
