import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'package:audioplayers/audioplayers.dart'; // Temporarily removed due to compilation issues
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

class BackgroundNotificationService {
  static final BackgroundNotificationService _instance = BackgroundNotificationService._internal();
  factory BackgroundNotificationService() => _instance;
  BackgroundNotificationService._internal();

  // final AudioPlayer _audioPlayer = AudioPlayer(); // Temporarily removed due to compilation issues
  bool _isInitialized = false;
  bool _isPlayingAlarm = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize local notifications
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      
      const InitializationSettings initializationSettings = InitializationSettings(
        android: initializationSettingsAndroid,
        iOS: initializationSettingsIOS,
      );

      await flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      // Create notification channels for Android
      await _createNotificationChannels();

      _isInitialized = true;
      debugPrint('Background notification service initialized');
    } catch (e) {
      debugPrint('Error initializing background notification service: $e');
    }
  }

  Future<void> _createNotificationChannels() async {
    final AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
      'fire_alarm_channel',
      'Fire Alarm Notifications',
      description: 'Critical fire alarm notifications with sound',
      importance: Importance.max,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('alarm_clock'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
    );

    final AndroidNotificationChannel drillChannel = AndroidNotificationChannel(
      'drill_channel',
      'Drill Notifications',
      description: 'Fire drill notifications',
      importance: Importance.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound('beep_short'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 500, 200, 500]),
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(alarmChannel);

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(drillChannel);
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap if needed
  }

  Future<void> showFireAlarmNotification({
    required String title,
    required String body,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    try {
      // Acquire wake lock to ensure device stays awake
      await WakelockPlus.enable();

      // Determine notification channel based on event type
      String channelId = eventType == 'DRILL' ? 'drill_channel' : 'fire_alarm_channel';

      AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
        channelId,
        eventType == 'DRILL' ? 'Drill Notifications' : 'Fire Alarm Notifications',
        channelDescription: eventType == 'DRILL' 
            ? 'Fire drill notifications' 
            : 'Critical fire alarm notifications',
        importance: Importance.max,
        priority: Priority.high,
        showWhen: true,
        autoCancel: false,
        ongoing: eventType != 'DRILL', // Keep alarm notifications ongoing
        fullScreenIntent: true,
        category: AndroidNotificationCategory.alarm,
        visibility: NotificationVisibility.public,
        sound: RawResourceAndroidNotificationSound(
            eventType == 'DRILL' ? 'beep_short' : 'alarm_clock'),
        playSound: true,
        enableVibration: true,
        vibrationPattern: Int64List.fromList(
            eventType == 'DRILL' ? [0, 500, 200, 500] : [0, 1000, 500, 1000]),
        color: const Color.fromARGB(255, 255, 0, 0), // Red color for urgency
        ledColor: const Color.fromARGB(255, 255, 0, 0),
        ledOnMs: 1000,
        ledOffMs: 500,
        ticker: 'Fire Alarm Alert - Immediate attention required!',
        additionalFlags: eventType != 'DRILL' 
            ? Int32List.fromList([4, 4]) // FLAG_INSISTENT + FLAG_NO_CLEAR for critical alarms
            : null,
        actions: eventType != 'DRILL' ? [
          AndroidNotificationAction(
            'stop_alarm', 
            'Stop Alarm',
            showsUserInterface: true,
          ),
          AndroidNotificationAction(
            'snooze', 
            'Snooze 5min',
            showsUserInterface: true,
          ),
        ] : null,
      );

      DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: eventType == 'DRILL' ? 'beep_short.caf' : 'alarm_clock.caf',
        badgeNumber: 1,
      );

      NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await flutterLocalNotificationsPlugin.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        platformChannelSpecifics,
        payload: data?.toString(),
      );

      // Play alarm sound in background
      if (!_isPlayingAlarm) {
        _playAlarmSound(eventType);
      }

      debugPrint('Fire alarm notification shown: $title');
    } catch (e) {
      debugPrint('Error showing fire alarm notification: $e');
    }
  }

  Future<void> _playAlarmSound(String eventType) async {
    try {
      _isPlayingAlarm = true;
      
      String soundFile = eventType == 'DRILL' ? 'beep_short.ogg' : 'alarm_clock.ogg';
      
      // Loop the alarm sound for critical events
      if (eventType != 'DRILL') {
        debugPrint('AUDIO: Would set loop mode (audio player disabled)');
        // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      } else {
        debugPrint('AUDIO: Would set stop mode (audio player disabled)');
        // await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      }

      debugPrint('AUDIO: Would play alarm sound: $soundFile (audio player disabled)');
      // await _audioPlayer.play(AssetSource(soundFile));
      
      debugPrint('Playing alarm sound: $soundFile');
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
      _isPlayingAlarm = false;
    }
  }

  Future<void> stopAlarm() async {
    try {
      debugPrint('AUDIO: Would stop alarm sound (audio player disabled)');
      // await _audioPlayer.stop();
      await WakelockPlus.disable();
      _isPlayingAlarm = false;

      // Cancel all fire alarm notifications
      await flutterLocalNotificationsPlugin.cancelAll();

      debugPrint('Alarm stopped and notifications cleared');
    } catch (e) {
      debugPrint('Error stopping alarm: $e');
    }
  }

  // Handle notification actions
  Future<void> handleNotificationAction(String action) async {
    switch (action) {
      case 'stop_alarm':
        await stopAlarm();
        break;
      default:
        debugPrint('Unknown notification action: $action');
    }
  }

  // Background message handler for FCM
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    debugPrint('Handling a background message: ${message.messageId}');
    
    try {
      // Initialize background service
      final service = BackgroundNotificationService();
      await service.initialize();
      
      // Extract message data
      final data = message.data;
      final eventType = data['eventType'] ?? 'UNKNOWN';
      final status = data['status'] ?? '';
      final user = data['user'] ?? 'System';
      
      // Show notification with sound
      await service.showFireAlarmNotification(
        title: 'Fire Alarm: $eventType',
        body: 'Status: $status - By: $user',
        eventType: eventType,
        data: data,
      );
      
      debugPrint('Background notification shown for: $eventType');
    } catch (e) {
      debugPrint('Error handling background FCM message: $e');
    }
  }

  void dispose() {
    // _audioPlayer.dispose(); // Temporarily removed due to compilation issues
  }
}
