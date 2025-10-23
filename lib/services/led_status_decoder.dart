import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

/// LED Status model for decoded LED data
class LEDStatus {
  final String rawData;
  final int firstByte;
  final int ledByte;
  final String ledBinary;
  final LEDStatusData ledStatus;
  final SystemContext systemContext;
  final DateTime timestamp;

  LEDStatus({
    required this.rawData,
    required this.firstByte,
    required this.ledByte,
    required this.ledBinary,
    required this.ledStatus,
    required this.systemContext,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory LEDStatus.fromJson(Map<String, dynamic> json) {
    return LEDStatus(
      rawData: json['rawData'] ?? '',
      firstByte: json['firstByte'] ?? 0,
      ledByte: json['ledByte'] ?? 0,
      ledBinary: json['ledBinary'] ?? '',
      ledStatus: LEDStatusData.fromJson(json['ledStatus'] ?? {}),
      systemContext: SystemContext.values.firstWhere(
        (e) => e.toString() == json['systemContext'],
        orElse: () => SystemContext.systemNormal,
      ),
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rawData': rawData,
      'firstByte': firstByte,
      'ledByte': ledByte,
      'ledBinary': ledBinary,
      'ledStatus': ledStatus.toJson(),
      'systemContext': systemContext.toString(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'LEDStatus(rawData: $rawData, context: $systemContext, timestamp: $timestamp)';
  }
}

/// Individual LED status data
class LEDStatusData {
  final bool acPowerOn;      // Bit 6 - Green when ON
  final bool dcPowerOn;      // Bit 5 - Green when ON
  final bool alarmOn;        // Bit 4 - Red when ON
  final bool troubleOn;      // Bit 3 - Yellow when ON
  final bool supervisoryOn;  // Bit 2 - Red when ON
  final bool silencedOn;     // Bit 1 - Yellow when ON
  final bool disabledOn;     // Bit 0 - Yellow when ON

  LEDStatusData({
    required this.acPowerOn,
    required this.dcPowerOn,
    required this.alarmOn,
    required this.troubleOn,
    required this.supervisoryOn,
    required this.silencedOn,
    required this.disabledOn,
  });

  factory LEDStatusData.fromJson(Map<String, dynamic> json) {
    return LEDStatusData(
      acPowerOn: json['AC_POWER'] ?? false,
      dcPowerOn: json['DC_POWER'] ?? false,
      alarmOn: json['ALARM'] ?? false,
      troubleOn: json['TROUBLE'] ?? false,
      supervisoryOn: json['SUPERVISORY'] ?? false,
      silencedOn: json['SILENCED'] ?? false,
      disabledOn: json['DISABLED'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'AC_POWER': acPowerOn,
      'DC_POWER': dcPowerOn,
      'ALARM': alarmOn,
      'TROUBLE': troubleOn,
      'SUPERVISORY': supervisoryOn,
      'SILENCED': silencedOn,
      'DISABLED': disabledOn,
    };
  }

  /// Get LED color based on status
  Color getLEDColor(LEDType type) {
    bool isOn = getLEDStatus(type);
    if (!isOn) return Colors.grey.shade300; // OFF color (White/Grey)

    switch (type) {
      case LEDType.acPower:
        return Colors.green;    // AC Power ON - Green
      case LEDType.dcPower:
        return Colors.green;    // DC Power ON - Green
      case LEDType.alarm:
        return Colors.red;      // Alarm ON - Red
      case LEDType.trouble:
        return Colors.yellow;   // Trouble ON - Yellow
      case LEDType.supervisory:
        return Colors.red;      // Supervisory ON - Red
      case LEDType.silenced:
        return Colors.yellow;   // Silenced ON - Yellow
      case LEDType.disabled:
        return Colors.yellow;   // Disabled ON - Yellow
    }
  }

  /// Get individual LED status
  bool getLEDStatus(LEDType type) {
    switch (type) {
      case LEDType.acPower:
        return acPowerOn;
      case LEDType.dcPower:
        return dcPowerOn;
      case LEDType.alarm:
        return alarmOn;
      case LEDType.trouble:
        return troubleOn;
      case LEDType.supervisory:
        return supervisoryOn;
      case LEDType.silenced:
        return silencedOn;
      case LEDType.disabled:
        return disabledOn;
    }
  }

  @override
  String toString() {
    return 'LEDStatus(AC: $acPowerOn, DC: $dcPowerOn, ALARM: $alarmOn, TROUBLE: $troubleOn, SUPER: $supervisoryOn, SILENCE: $silencedOn, DISABLE: $disabledOn)';
  }
}

/// LED Types enumeration
enum LEDType {
  acPower,      // Bit 6
  dcPower,      // Bit 5
  alarm,        // Bit 4
  trouble,      // Bit 3
  supervisory,  // Bit 2
  silenced,     // Bit 1
  disabled,     // Bit 0
}

/// System Context enumeration
enum SystemContext {
  systemDisabledMaintenance,  // DISABLED = true
  systemSilencedManual,      // SILENCED = true
  alarmWithTroubleCondition, // ALARM + TROUBLE = true
  supervisoryAlarmActive,    // ALARM + SUPERVISORY = true
  fullAlarmActive,           // ALARM = true only
  troubleConditionOnly,      // TROUBLE = true only
  supervisoryPreAlarm,       // SUPERVISORY = true only
  systemNormal,              // All LEDs OFF
}

/// LED Status Decoder Service
class LEDStatusDecoder {
  static const String _tag = 'LED_DECODER';
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  
  // Stream controllers for real-time updates
  final StreamController<LEDStatus?> _ledStatusController = 
      StreamController<LEDStatus?>.broadcast();
  final StreamController<String?> _rawLEDDataController = 
      StreamController<String?>.broadcast();

  LEDStatus? _currentLEDStatus;
  String? _lastRawData;

  /// Stream untuk mendapatkan update status LED real-time
  Stream<LEDStatus?> get ledStatusStream => _ledStatusController.stream;

  /// Stream untuk mendapatkan data mentah LED
  Stream<String?> get rawLEDDataStream => _rawLEDDataController.stream;

  /// Get current LED status
  LEDStatus? get currentLEDStatus => _currentLEDStatus;

  /// Start monitoring LED data from Firebase
  void startMonitoring() {
    debugPrint('🚀 $_tag: Starting LED Status monitoring...');
    
    // Listen untuk LED status data dari Firebase
    _databaseRef.child('system_status/led_status').onValue.listen((event) {
      String? ledData = event.snapshot.value?.toString();
      if (ledData != null && ledData != _lastRawData) {
        _lastRawData = ledData;
        debugPrint('🎯 $_tag: Processing LED data: $ledData');
        _processLEDData(ledData);

        // Broadcast raw data
        _rawLEDDataController.add(ledData);
      } else if (event.snapshot.value == null) {
        debugPrint('⚠️ $_tag: LED data deleted from Firebase');
        _handleNoLEDDataCondition();
      }
    });

    // Alternative: Listen for LED data in system_status/data field
    _databaseRef.child('system_status/data').onValue.listen((event) {
      final snapshotValue = event.snapshot.value;

      if (snapshotValue == null) {
        debugPrint('⚠️ $_tag: System status data is null');
        return;
      }

      if (snapshotValue is! Map) {
        debugPrint('⚠️ $_tag: System status data is not a Map');
        return;
      }

      final data = Map<String, dynamic>.from(snapshotValue);

      // Check for led_status field
      String? ledData = data['led_status']?.toString();

      if (ledData != null && ledData != _lastRawData) {
        _lastRawData = ledData;
        debugPrint('🔄 $_tag: Processing LED data from system_status/data: $ledData');
        _processLEDData(ledData);

        _rawLEDDataController.add(ledData);
      }
    });
  }

  /// Process LED data using the specification algorithm
  void _processLEDData(String rawData) {
    try {
      debugPrint('🔍 $_tag: Decoding LED data: $rawData');
      
      // Step 1: Validate hex data length
      String hexData = rawData.toUpperCase().replaceAll(RegExp(r'[^0-9A-F]'), '');
      if (hexData.length != 4) {
        debugPrint('❌ $_tag: Invalid LED data length: $hexData (expected 4 characters)');
        return;
      }

      // Step 2: Extract bytes
      String firstByteHex = hexData.substring(0, 2);    // "03"
      String secondByteHex = hexData.substring(2, 4);   // "BD"
      
      debugPrint('📋 $_tag: First byte: $firstByteHex, Second byte: $secondByteHex');

      // Step 3: Convert to numerical values
      int firstByteValue = int.parse(firstByteHex, radix: 16);
      int ledByteValue = int.parse(secondByteHex, radix: 16);
      
      debugPrint('🔢 $_tag: First byte decimal: $firstByteValue, LED byte decimal: $ledByteValue');

      // Step 4: Convert to binary for bit analysis
      String ledBinary = ledByteValue.toRadixString(2).padLeft(8, '0');
      debugPrint('🔢 $_tag: LED byte binary: $ledBinary');

      // Step 5: Bitwise decoding (0=ON, 1=OFF)
      LEDStatusData ledStatusData = LEDStatusData(
        acPowerOn: (ledByteValue & (1 << 6)) == 0,      // Bit 6
        dcPowerOn: (ledByteValue & (1 << 5)) == 0,      // Bit 5
        alarmOn: (ledByteValue & (1 << 4)) == 0,        // Bit 4
        troubleOn: (ledByteValue & (1 << 3)) == 0,      // Bit 3
        supervisoryOn: (ledByteValue & (1 << 2)) == 0,  // Bit 2
        silencedOn: (ledByteValue & (1 << 1)) == 0,     // Bit 1
        disabledOn: (ledByteValue & (1 << 0)) == 0,     // Bit 0
      );

      debugPrint('💡 $_tag: Decoded LED status: $ledStatusData');

      // Step 6: Determine system context
      SystemContext systemContext = _determineSystemContext(ledStatusData);
      debugPrint('🎯 $_tag: System context: $systemContext');

      // Step 7: Create LED status object
      LEDStatus ledStatus = LEDStatus(
        rawData: hexData,
        firstByte: firstByteValue,
        ledByte: ledByteValue,
        ledBinary: ledBinary,
        ledStatus: ledStatusData,
        systemContext: systemContext,
      );

      // Step 8: Update current status
      _currentLEDStatus = ledStatus;

      // Step 9: Update Firebase system status based on LED data
      _updateFirebaseSystemStatus(ledStatus);

      // Step 10: Broadcast update
      _ledStatusController.add(ledStatus);

      // Step 11: Log to history
      _logLEDStatusToHistory(ledStatus);

      debugPrint('✅ $_tag: LED data processed successfully');

    } catch (e, stackTrace) {
      debugPrint('❌ $_tag: Error processing LED data: $e');
      debugPrint('🔍 $_tag: Stack trace: $stackTrace');
    }
  }

  /// Determine system context based on LED status combination
  SystemContext _determineSystemContext(LEDStatusData ledStatus) {
    // Priority-based context determination
    
    if (ledStatus.disabledOn) {
      return SystemContext.systemDisabledMaintenance;
    }
    
    if (ledStatus.silencedOn) {
      return SystemContext.systemSilencedManual;
    }
    
    if (ledStatus.alarmOn && ledStatus.troubleOn) {
      return SystemContext.alarmWithTroubleCondition;
    }
    
    if (ledStatus.alarmOn && ledStatus.supervisoryOn) {
      return SystemContext.supervisoryAlarmActive;
    }
    
    if (ledStatus.alarmOn) {
      return SystemContext.fullAlarmActive;
    }
    
    if (ledStatus.troubleOn) {
      return SystemContext.troubleConditionOnly;
    }
    
    if (ledStatus.supervisoryOn) {
      return SystemContext.supervisoryPreAlarm;
    }
    
    return SystemContext.systemNormal;
  }

  /// Update Firebase system status based on LED data
  void _updateFirebaseSystemStatus(LEDStatus ledStatus) {
    try {
      LEDStatusData led = ledStatus.ledStatus;
      
      // Update system status in Firebase
      _databaseRef.child('systemStatus/AC Power/status').set(led.acPowerOn);
      _databaseRef.child('systemStatus/DC Power/status').set(led.dcPowerOn);
      _databaseRef.child('systemStatus/Alarm/status').set(led.alarmOn);
      _databaseRef.child('systemStatus/Trouble/status').set(led.troubleOn);
      _databaseRef.child('systemStatus/Supervisory/status').set(led.supervisoryOn);
      _databaseRef.child('systemStatus/Silenced/status').set(led.silencedOn);
      _databaseRef.child('systemStatus/Disabled/status').set(led.disabledOn);

      // Update recent activity
      String activity = _getActivityDescription(ledStatus.systemContext);
      _databaseRef.child('recentActivity').set('[$activity] | [LED_DECODER]');

      debugPrint('📊 $_tag: Firebase system status updated based on LED data');
      debugPrint('📊 $_tag: Activity: $activity');

    } catch (e) {
      debugPrint('❌ $_tag: Error updating Firebase system status: $e');
    }
  }

  /// Get human-readable activity description
  String _getActivityDescription(SystemContext context) {
    switch (context) {
      case SystemContext.systemDisabledMaintenance:
        return 'SYSTEM DISABLED - MAINTENANCE MODE';
      case SystemContext.systemSilencedManual:
        return 'SYSTEM SILENCED - MANUAL INTERVENTION';
      case SystemContext.alarmWithTroubleCondition:
        return 'ALARM ACTIVE WITH TROUBLE CONDITION';
      case SystemContext.supervisoryAlarmActive:
        return 'SUPERVISORY ALARM ACTIVE';
      case SystemContext.fullAlarmActive:
        return 'FULL ALARM ACTIVE';
      case SystemContext.troubleConditionOnly:
        return 'TROUBLE CONDITION DETECTED';
      case SystemContext.supervisoryPreAlarm:
        return 'SUPERVISORY PRE-ALARM CONDITION';
      case SystemContext.systemNormal:
        return 'SYSTEM NORMAL';
    }
  }

  /// Log LED status to history
  void _logLEDStatusToHistory(LEDStatus ledStatus) {
    try {
      final now = DateTime.now();
      final date = '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';
      final time = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
      
      _databaseRef.child('history/ledStatusLogs').push().set({
        'date': date,
        'time': time,
        'rawData': ledStatus.rawData,
        'systemContext': ledStatus.systemContext.toString(),
        'ledStatus': ledStatus.ledStatus.toJson(),
        'timestamp': now.toIso8601String(),
        'source': 'LED_DECODER',
      });
      
      debugPrint('📋 $_tag: LED status logged to history at $time');
    } catch (e) {
      debugPrint('❌ $_tag: Error logging LED status to history: $e');
    }
  }

  /// Handle no LED data condition
  void _handleNoLEDDataCondition() {
    try {
      debugPrint('⚠️ $_tag: Handling no LED data condition');
      
      // Clear current LED status
      _currentLEDStatus = null;
      _lastRawData = null;
      
      // Update Firebase system status to clear all LED-based statuses
      _databaseRef.child('systemStatus/AC Power/status').set(false);
      _databaseRef.child('systemStatus/DC Power/status').set(false);
      _databaseRef.child('systemStatus/Alarm/status').set(false);
      _databaseRef.child('systemStatus/Trouble/status').set(false);
      _databaseRef.child('systemStatus/Supervisory/status').set(false);
      _databaseRef.child('systemStatus/Silenced/status').set(false);
      _databaseRef.child('systemStatus/Disabled/status').set(false);
      
      // Update recent activity
      _databaseRef.child('recentActivity').set('[NO LED DATA] | [LED_DECODER]');
      
      // Broadcast null to indicate no data
      if (!_ledStatusController.isClosed) {
        _ledStatusController.add(null);
      }
      
      if (!_rawLEDDataController.isClosed) {
        _rawLEDDataController.add(null);
      }
      
      debugPrint('✅ $_tag: No LED data condition handled');
      
    } catch (e) {
      debugPrint('❌ $_tag: Error handling no LED data condition: $e');
    }
  }

  /// Manual LED data processing (for testing)
  LEDStatus? processManualLEDData(String rawData) {
    _processLEDData(rawData);
    return _currentLEDStatus;
  }

  /// Get LED color for specific LED type
  Color? getLEDColor(LEDType ledType) {
    if (_currentLEDStatus == null) return null;
    return _currentLEDStatus!.ledStatus.getLEDColor(ledType);
  }

  /// Get LED status for specific LED type
  bool? getLEDStatus(LEDType ledType) {
    if (_currentLEDStatus == null) return null;
    return _currentLEDStatus!.ledStatus.getLEDStatus(ledType);
  }

  /// Get current system context
  SystemContext? get currentSystemContext => _currentLEDStatus?.systemContext;

  /// Check if system is in alarm state
  bool get isSystemInAlarm => _currentLEDStatus?.ledStatus.alarmOn ?? false;

  /// Check if system is in trouble state
  bool get isSystemInTrouble => _currentLEDStatus?.ledStatus.troubleOn ?? false;

  /// Check if system is silenced
  bool get isSystemSilenced => _currentLEDStatus?.ledStatus.silencedOn ?? false;

  /// Check if system is disabled
  bool get isSystemDisabled => _currentLEDStatus?.ledStatus.disabledOn ?? false;

  /// Get power status summary
  PowerStatus get powerStatus {
    if (_currentLEDStatus == null) {
      return PowerStatus.unknown;
    }
    
    bool acOn = _currentLEDStatus!.ledStatus.acPowerOn;
    bool dcOn = _currentLEDStatus!.ledStatus.dcPowerOn;
    
    if (acOn && dcOn) {
      return PowerStatus.bothOn;
    } else if (acOn && !dcOn) {
      return PowerStatus.acOnly;
    } else if (!acOn && dcOn) {
      return PowerStatus.dcOnly;
    } else {
      return PowerStatus.bothOff;
    }
  }

  /// Stop monitoring
  void stopMonitoring() {
    _ledStatusController.close();
    _rawLEDDataController.close();
    debugPrint('🛑 $_tag: LED Status monitoring stopped');
  }

  /// Dispose resources
  void dispose() {
    stopMonitoring();
  }
}

/// Power status enumeration
enum PowerStatus {
  bothOn,    // AC and DC both ON
  acOnly,    // Only AC ON
  dcOnly,    // Only DC ON (running on battery)
  bothOff,   // Both OFF
  unknown,   // Status unknown
}

/// Extension methods for LED status
extension LEDStatusExtensions on LEDStatus {
  /// Get human readable status summary
  String get statusSummary {
    switch (systemContext) {
      case SystemContext.systemDisabledMaintenance:
        return 'System Disabled - Maintenance';
      case SystemContext.systemSilencedManual:
        return 'System Silenced - Manual';
      case SystemContext.alarmWithTroubleCondition:
        return 'Alarm with Trouble';
      case SystemContext.supervisoryAlarmActive:
        return 'Supervisory Alarm';
      case SystemContext.fullAlarmActive:
        return 'Full Alarm Active';
      case SystemContext.troubleConditionOnly:
        return 'Trouble Condition';
      case SystemContext.supervisoryPreAlarm:
        return 'Supervisory Pre-Alarm';
      case SystemContext.systemNormal:
        return 'System Normal';
    }
  }

  /// Get priority level for notifications
  int get priorityLevel {
    switch (systemContext) {
      case SystemContext.fullAlarmActive:
      case SystemContext.alarmWithTroubleCondition:
        return 4; // Highest priority
      case SystemContext.supervisoryAlarmActive:
        return 3;
      case SystemContext.troubleConditionOnly:
      case SystemContext.supervisoryPreAlarm:
        return 2;
      case SystemContext.systemSilencedManual:
        return 1;
      case SystemContext.systemDisabledMaintenance:
      case SystemContext.systemNormal:
        return 0; // Lowest priority
    }
  }
}
