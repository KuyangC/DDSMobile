import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_database/firebase_database.dart';
import '../fire_alarm_data.dart';
import 'auth_service.dart';

/// Service terpusat untuk mengelola aksi button pada Control Page dan Full Monitoring Page
/// Mengirim data ke Firebase path: system_status/user_input/data
class ButtonActionService {
  static final ButtonActionService _instance = ButtonActionService._internal();
  factory ButtonActionService() => _instance;
  ButtonActionService._internal();

  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  final AuthService _authService = AuthService();

  // Button action codes
  static const String drillCode = 'd';
  static const String systemResetCode = 'r';
  static const String acknowledgeCode = 'a';
  static const String silenceCode = 's';

  // Track last sent data to prevent duplicates
  String? _lastSentData;
  DateTime? _lastSentTime;

  /// Mengirim data button action ke Firebase path system_status/user_input/data
  /// Data hanya dikirim 1x untuk mencegah pengiriman berulang
  Future<bool> sendButtonAction(String actionCode, {required BuildContext context}) async {
    try {
      // Cek koneksi Firebase
      final fireAlarmData = context.read<FireAlarmData>();
      if (!fireAlarmData.isFirebaseConnected) {
        if (context.mounted) {
          _showDisconnectedNotification(context);
        }
        return false;
      }

      // Cegah pengiriman data yang sama dalam waktu 1 detik
      if (_lastSentData == actionCode && _lastSentTime != null) {
        final timeDiff = DateTime.now().difference(_lastSentTime!);
        if (timeDiff.inMilliseconds < 1000) {
          debugPrint('ButtonActionService: Preventing duplicate send for $actionCode');
          return false;
        }
      }

      // Kirim data ke Firebase
      final userInputRef = _databaseRef.child('system_status/user_input/data/');
      
      await userInputRef.set({
        'DATA_UNTUK_SISTEM': actionCode,
        'timestamp': ServerValue.timestamp,
        'user': await _authService.getCurrentUsername() ?? 'Unknown',
        'action': _getActionName(actionCode),
      });

      // Update tracking
      _lastSentData = actionCode;
      _lastSentTime = DateTime.now();

      debugPrint('ButtonActionService: Sent $actionCode to Firebase');
      return true;
    } catch (e) {
      debugPrint('ButtonActionService: Error sending $actionCode: $e');
      if (context.mounted) {
        _showErrorNotification(context, 'Failed to send command');
      }
      return false;
    }
  }

  /// Handler untuk System Reset
  Future<bool> handleSystemReset({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      context,
      'SYSTEM RESET',
      'Are you sure you want to reset the entire fire alarm system?',
      'RESET',
    );

    if (!confirmed) return false;

    // Send to Firebase
    // ignore: use_build_context_synchronously
    final success = await sendButtonAction(systemResetCode, context: context);
    
    if (success && context.mounted) {
      // Update local state - ONLY LOG THE RESET, DON'TE CHANGE STATUSES
      final String? currentUser = await _authService.getCurrentUsername();

      fireAlarmData.isResetting = true;
      
      // ONLY update activity log - DON'TE RESET SYSTEM STATUSES
      // Let system naturally update the system status based on actual hardware conditions
      fireAlarmData.updateRecentActivity('SYSTEM RESET', user: currentUser ?? 'Unknown');
      
      // Send notification for the reset action
      fireAlarmData.sendNotification();

      // Clear Firebase data to ensure clean state and wait for latest system data
      await _clearFirebaseDataForReset();
      
      // Clear resetting flag after delay to allow UI updates
      Future.delayed(const Duration(seconds: 3), () {
        if (fireAlarmData.isResetting) {
          fireAlarmData.isResetting = false;
          debugPrint('🔄 System reset completed - Firebase cleared, waiting for latest system hardware readings');
        }
      });
    }

    return success;
  }

  /// Clear Firebase data paths to ensure clean state after reset
  Future<void> _clearFirebaseDataForReset() async {
    try {
      debugPrint('🧹 Clearing Firebase data for clean reset state...');
      
      // Clear system bridge data to force fresh read from master
      await _databaseRef.child('system_status/data').remove();
      debugPrint('🧹 Cleared system_status/data');

      await _databaseRef.child('system_status/parsed_packet').remove();
      debugPrint('🧹 Cleared system_status/parsed_packet');

      // Clear user input data to prevent duplicate processing
      await _databaseRef.child('system_status/user_input/data').remove();
      debugPrint('🧹 Cleared system_status/user_input/data');
      
      // Clear system status to prevent stale status
      await _databaseRef.child('systemStatus').remove();
      debugPrint('🧹 Cleared systemStatus');
      
      // Clear recent activity to prevent stale activity
      await _databaseRef.child('recentActivity').remove();
      debugPrint('🧹 Cleared recentActivity');
      
      // Clear zone status cache if exists
      await _databaseRef.child('zoneStatus').remove();
      debugPrint('🧹 Cleared zoneStatus status cache');
      
      // Clear module bell trouble status if exists
      await _databaseRef.child('moduleBellTrouble').remove();
      debugPrint('🧹 Cleared moduleBellTrouble status');
      
      debugPrint('🧹 Firebase data cleared successfully - waiting for fresh system data');
      
    } catch (e) {
      debugPrint('❌ Error clearing Firebase data for reset: $e');
      // Continue even if clearing fails - the reset should still work
    }
  }

  /// Handler untuk Drill (toggle)
  Future<bool> handleDrill({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Show confirmation dialog
    final confirmed = await _showConfirmationDialog(
      context,
      'DRILL MODE',
      'Are you sure you want to activate drill mode?',
      'ACTIVATE',
    );

    if (!confirmed) return false;

    // Send to Firebase
    // ignore: use_build_context_synchronously
    final success = await sendButtonAction(drillCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      final currentStatus = fireAlarmData.getSystemStatus('Drill');
      final newStatus = !currentStatus;
      
      fireAlarmData.updateSystemStatus('Drill', newStatus);
      fireAlarmData.updateRecentActivity('DRILL : ${newStatus ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Handler untuk Acknowledge (toggle)
  Future<bool> handleAcknowledge({required BuildContext context, bool? currentState}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Send to Firebase
    final success = await sendButtonAction(acknowledgeCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      // Determine new state
      bool newState;
      if (currentState != null) {
        newState = !currentState;
      } else {
        // Fallback: check from FireAlarmData
        newState = !fireAlarmData.getSystemStatus('Silenced'); // Using Silenced as fallback
      }

      fireAlarmData.updateRecentActivity('ACKNOWLEDGE : ${newState ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Handler untuk Silence (toggle)
  Future<bool> handleSilence({required BuildContext context}) async {
    // Capture FireAlarmData before async gap
    final fireAlarmData = context.read<FireAlarmData>();
    
    // Send to Firebase
    final success = await sendButtonAction(silenceCode, context: context);
    
    if (success && context.mounted) {
      // Update local state
      final String? currentUser = await _authService.getCurrentUsername();

      final currentStatus = fireAlarmData.getSystemStatus('Silenced');
      final newStatus = !currentStatus;
      
      fireAlarmData.updateSystemStatus('Silenced', newStatus);
      fireAlarmData.updateRecentActivity('SILENCED : ${newStatus ? 'ON' : 'OFF'}', user: currentUser ?? 'Unknown');
      fireAlarmData.sendNotification();
    }

    return success;
  }

  /// Mendapatkan nama action dari code
  String _getActionName(String actionCode) {
    switch (actionCode) {
      case drillCode:
        return 'DRILL';
      case systemResetCode:
        return 'SYSTEM_RESET';
      case acknowledgeCode:
        return 'ACKNOWLEDGE';
      case silenceCode:
        return 'SILENCE';
      default:
        return 'UNKNOWN';
    }
  }

  /// Menampilkan dialog konfirmasi
  Future<bool> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    String action,
  ) async {
    return await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text(title),
              content: Text(message),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('CANCEL'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: Text(action),
                ),
              ],
            );
          },
        ) ??
        false;
  }

  /// Menampilkan notifikasi disconnected
  void _showDisconnectedNotification(BuildContext context) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You are not connected',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  /// Menampilkan notifikasi error
  void _showErrorNotification(BuildContext context, String message) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Reset tracking data (untuk testing purposes)
  void resetTracking() {
    _lastSentData = null;
    _lastSentTime = null;
  }
}
