import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FCMService {
  static const String _fcmUrl = 'https://fcm.googleapis.com/fcm/send';
  static String get _serverKey => dotenv.env['FCM_SERVER_KEY'] ?? ''; // From environment variables
  static const String _functionsUrl = 'https://us-central1-testing1do.cloudfunctions.net';

  static Future<String> _getAccessToken() async {
    // Get server key from environment variables
    final serverKey = _serverKey;
    if (serverKey.isEmpty) {
      throw Exception('FCM server key not configured in environment variables');
    }
    return serverKey;
  }

  static Future<String?> getAccessToken() async {
    try {
      return await _getAccessToken();
    } catch (e) {
      debugPrint('Error getting access token: $e');
      return null;
    }
  }

  static Future<bool> sendFCMNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    try {
      final accessToken = await getAccessToken();
      if (accessToken == null) {
        debugPrint('FCM access token not available');
        return false;
      }

      final headers = {
        'Authorization': 'key=$accessToken',
        'Content-Type': 'application/json',
      };

      final message = {
        'to': '/topics/status_updates',
        'notification': {
          'title': title,
          'body': body,
        },
        'data': data.map((key, value) => MapEntry(key, value.toString())),
      };

      final response = await http.post(
        Uri.parse(_fcmUrl),
        headers: headers,
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM notification sent successfully');
        return true;
      } else {
        debugPrint('Failed to send FCM notification: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error sending FCM notification: $e');
      return false;
    }
  }

  // Enhanced FCM service for fire alarm events using Firebase Functions via HTTP
  static Future<bool> sendFireAlarmNotification({
    required String eventType,
    required String status,
    required String user,
    String? projectName,
    String? panelType,
    int maxRetries = 3,
  }) async {
    int retryCount = 0;
    
    while (retryCount <= maxRetries) {
      try {
        debugPrint('Sending fire alarm notification: $eventType - $status by $user (attempt ${retryCount + 1})');
        
        // Use Firebase Functions callable endpoint
        final response = await http.post(
          Uri.parse('$_functionsUrl/sendFireAlarmNotification'),
          headers: {
            'Content-Type': 'application/json',
            'User-Agent': 'Flutter-FCM-Service/1.0',
          },
          body: jsonEncode({
            'data': {
              'eventType': eventType,
              'status': status,
              'user': user,
              'projectName': projectName ?? 'Unknown Project',
              'panelType': panelType ?? 'Unknown Panel',
            }
          }),
        ).timeout(const Duration(seconds: 10));

        debugPrint('Response status: ${response.statusCode}');
        
        if (response.statusCode == 200) {
          try {
            final result = jsonDecode(response.body);
            debugPrint('Parsed result: $result');
            
            if (result['result'] != null && result['result']['success'] == true) {
              debugPrint('Fire alarm notification sent successfully: ${result['result']['message']}');
              return true;
            } else {
              debugPrint('Failed to send fire alarm notification: ${result['result']?['message'] ?? 'Unknown error'}');
              return false;
            }
          } catch (e) {
            debugPrint('Error parsing response: $e');
            debugPrint('Raw response: ${response.body}');
            return false;
          }
        } else if (response.statusCode == 404) {
          debugPrint('404 Error - Function might be cold starting or unavailable');
          if (retryCount < maxRetries) {
            retryCount++;
            debugPrint('Retrying in ${2 * retryCount} seconds...');
            await Future.delayed(Duration(seconds: 2 * retryCount));
            continue;
          } else {
            debugPrint('Max retries reached for 404 error');
            return false;
          }
        } else if (response.statusCode == 500) {
          debugPrint('500 Error - Server error, might be temporary');
          if (retryCount < maxRetries) {
            retryCount++;
            debugPrint('Retrying in ${3 * retryCount} seconds...');
            await Future.delayed(Duration(seconds: 3 * retryCount));
            continue;
          } else {
            debugPrint('Max retries reached for 500 error');
            return false;
          }
        } else {
          debugPrint('HTTP error: ${response.statusCode} ${response.body}');
          return false;
        }
      } catch (e) {
        debugPrint('Error sending fire alarm notification: $e');
        if (retryCount < maxRetries && e.toString().contains('TimeoutException')) {
          retryCount++;
          debugPrint('Retrying due to timeout in ${2 * retryCount} seconds...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        } else if (retryCount < maxRetries && e.toString().contains('SocketException')) {
          retryCount++;
          debugPrint('Retrying due to network error in ${2 * retryCount} seconds...');
          await Future.delayed(Duration(seconds: 2 * retryCount));
          continue;
        } else {
          debugPrint('Fatal error - no more retries: $e');
          return false;
        }
      }
    }
    
    debugPrint('Failed to send fire alarm notification after $maxRetries retries');
    return false;
  }

  // Subscribe to fire alarm events topic via HTTP
  static Future<bool> subscribeToFireAlarmEvents(String? fcmToken) async {
    try {
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM token is null or empty');
        return false;
      }

      debugPrint('Subscribing to fire alarm events with token: ${fcmToken.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('$_functionsUrl/subscribeToFireAlarmEvents'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'token': fcmToken,
          }
        }),
      );

      debugPrint('Subscribe response status: ${response.statusCode}');
      debugPrint('Subscribe response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          if (result['result'] != null && result['result']['success'] == true) {
            debugPrint('Successfully subscribed to fire alarm events');
            return true;
          } else {
            debugPrint('Failed to subscribe to fire alarm events: ${result['result']?['message'] ?? 'Unknown error'}');
            return false;
          }
        } catch (e) {
          debugPrint('Error parsing subscribe response: $e');
          return false;
        }
      } else {
        debugPrint('HTTP error subscribing: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error subscribing to fire alarm events: $e');
      return false;
    }
  }

  // Unsubscribe from fire alarm events topic via HTTP
  static Future<bool> unsubscribeFromFireAlarmEvents(String? fcmToken) async {
    try {
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('FCM token is null or empty');
        return false;
      }

      debugPrint('Unsubscribing from fire alarm events with token: ${fcmToken.substring(0, 10)}...');

      final response = await http.post(
        Uri.parse('$_functionsUrl/unsubscribeFromFireAlarmEvents'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'data': {
            'token': fcmToken,
          }
        }),
      );

      debugPrint('Unsubscribe response status: ${response.statusCode}');
      debugPrint('Unsubscribe response body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final result = jsonDecode(response.body);
          if (result['result'] != null && result['result']['success'] == true) {
            debugPrint('Successfully unsubscribed from fire alarm events');
            return true;
          } else {
            debugPrint('Failed to unsubscribe from fire alarm events: ${result['result']?['message'] ?? 'Unknown error'}');
            return false;
          }
        } catch (e) {
          debugPrint('Error parsing unsubscribe response: $e');
          return false;
        }
      } else {
        debugPrint('HTTP error unsubscribing: ${response.statusCode} ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error unsubscribing from fire alarm events: $e');
      return false;
    }
  }

  // Helper methods for specific event types
  static Future<bool> sendDrillNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'DRILL',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendSystemResetNotification({
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'SYSTEM RESET',
      status: 'COMPLETED',
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendSilenceNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'SILENCE',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendAcknowledgeNotification({
    required String status,
    required String user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'ACKNOWLEDGE',
      status: status,
      user: user,
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendAlarmNotification({
    required String status,
    String? user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'ALARM',
      status: status,
      user: user ?? 'System',
      projectName: projectName,
      panelType: panelType,
    );
  }

  static Future<bool> sendTroubleNotification({
    required String status,
    String? user,
    String? projectName,
    String? panelType,
  }) async {
    return await sendFireAlarmNotification(
      eventType: 'TROUBLE',
      status: status,
      user: user ?? 'System',
      projectName: projectName,
      panelType: panelType,
    );
  }
}
