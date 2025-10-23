import 'package:flutter/material.dart';

/// Enhanced model untuk 63 devices dengan 5 zones per device
class EnhancedDevice {
  final String address;
  final bool isConnected;
  final List<ZoneStatus> zones; // 5 zones per device
  final DeviceStatus deviceStatus;
  final DateTime timestamp;

  EnhancedDevice({
    required this.address,
    required this.isConnected,
    required this.zones,
    required this.deviceStatus,
    required this.timestamp,
  });

  factory EnhancedDevice.fromJson(Map<String, dynamic> json) {
    return EnhancedDevice(
      address: json['address'] ?? '',
      isConnected: json['isConnected'] ?? false,
      zones: (json['zones'] as List<dynamic>?)
          ?.map((zone) => ZoneStatus.fromJson(zone))
          .toList() ?? [],
      deviceStatus: DeviceStatus.fromJson(json['deviceStatus'] ?? {}),
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'isConnected': isConnected,
      'zones': zones.map((zone) => zone.toJson()).toList(),
      'deviceStatus': deviceStatus.toJson(),
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Get total active zones across all devices
  int get totalActiveZones {
    return zones.where((zone) => zone.isActive).length;
  }

  /// Get trouble zones
  List<ZoneStatus> get troubleZones {
    return zones.where((zone) => zone.hasTrouble).toList();
  }

  /// Get alarm zones
  List<ZoneStatus> get alarmZones {
    return zones.where((zone) => zone.hasAlarm).toList();
  }
}

/// Status untuk 5 zona dalam satu device
class ZoneStatus {
  final int zoneNumber; // 1-5 within device
  final bool isActive;
  final bool hasTrouble;
  final bool hasAlarm;
  final String? description;

  ZoneStatus({
    required this.zoneNumber,
    required this.isActive,
    this.hasTrouble = false,
    this.hasAlarm = false,
    this.description,
  });

  factory ZoneStatus.fromJson(Map<String, dynamic> json) {
    return ZoneStatus(
      zoneNumber: json['zoneNumber'] ?? 1,
      isActive: json['isActive'] ?? false,
      hasTrouble: json['hasTrouble'] ?? false,
      hasAlarm: json['hasAlarm'] ?? false,
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneNumber': zoneNumber,
      'isActive': isActive,
      'hasTrouble': hasTrouble,
      'hasAlarm': hasAlarm,
      'description': description,
    };
  }
}

/// Device status overall
class DeviceStatus {
  final bool hasPower;
  final bool hasTrouble;
  final bool hasAlarm;
  final bool outputBellActive;
  final String? lastError;

  DeviceStatus({
    required this.hasPower,
    required this.hasTrouble,
    required this.hasAlarm,
    this.outputBellActive = false,
    this.lastError,
  });

  factory DeviceStatus.fromJson(Map<String, dynamic> json) {
    return DeviceStatus(
      hasPower: json['hasPower'] ?? false,
      hasTrouble: json['hasTrouble'] ?? false,
      hasAlarm: json['hasAlarm'] ?? false,
      outputBellActive: json['outputBellActive'] ?? false,
      lastError: json['lastError'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hasPower': hasPower,
      'hasTrouble': hasTrouble,
      'hasAlarm': hasAlarm,
      'outputBellActive': outputBellActive,
      'lastError': lastError,
    };
  }
}

/// Master control signal data
class MasterControlSignal {
  final String signal;
  final String checksum;
  final DateTime timestamp;
  final ControlSignalType type;

  MasterControlSignal({
    required this.signal,
    required this.checksum,
    required this.timestamp,
    this.type = ControlSignalType.unknown,
  });

  factory MasterControlSignal.fromJson(Map<String, dynamic> json) {
    return MasterControlSignal(
      signal: json['signal'] ?? '',
      checksum: json['checksum'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      type: MasterControlSignal._parseControlType(json['signal']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'signal': signal,
      'checksum': checksum,
      'timestamp': timestamp.toIso8601String(),
      'type': type.toString(),
    };
  }

  static ControlSignalType _parseControlType(String? signal) {
    if (signal == null) return ControlSignalType.unknown;

    switch (signal) {
      case '4037':
        return ControlSignalType.buzzerControl;
      case '4038':
        return ControlSignalType.backlightControl;
      case '4039':
        return ControlSignalType.lcdControl;
      case '403A':
        return ControlSignalType.systemReset;
      default:
        return ControlSignalType.unknown;
    }
  }
}

/// Control signal types
enum ControlSignalType {
  buzzerControl,
  backlightControl,
  lcdControl,
  systemReset,
  unknown,
}

/// Enhanced parsing result untuk 63 devices
class EnhancedParsingResult {
  final String cycleType;
  final String checksum;
  final String status;
  final int totalDevices;
  final int connectedDevices;
  final int disconnectedDevices;
  final List<EnhancedDevice> devices;
  final MasterControlSignal? masterSignal;
  final Map<String, dynamic> rawData;
  final DateTime timestamp;

  EnhancedParsingResult({
    required this.cycleType,
    required this.checksum,
    required this.status,
    required this.totalDevices,
    required this.connectedDevices,
    required this.disconnectedDevices,
    required this.devices,
    this.masterSignal,
    required this.rawData,
    required this.timestamp,
  });

  /// Get total active zones across all devices
  int get totalActiveZones {
    return devices.fold(0, (total, device) => total + device.totalActiveZones);
  }

  /// Get total trouble zones
  int get totalTroubleZones {
    return devices.fold(0, (total, device) => total + device.troubleZones.length);
  }

  /// Get total alarm zones
  int get totalAlarmZones {
    return devices.fold(0, (total, device) => total + device.alarmZones.length);
  }

  /// Get severity level
  int get severityLevel {
    switch (status.toLowerCase()) {
      case 'all_slaves_connected_normal':
        return 0; // Normal
      case 'partial_connection_with_alarm':
        return 3; // High
      case 'partial_connection_disconnected':
        return 2; // Medium
      case 'all_slaves_disconnected':
        return 4; // Critical
      default:
        return 1; // Low
    }
  }
}

/// Enhanced Zone Parser untuk 63 devices dengan 5 zones
class EnhancedZoneParser {
  static const String _tag = 'ENHANCED_ZONE_PARSER';
  static const int stx = 0x02;
  static const int etx = 0x03;

  /// Parse complete data stream for 63 devices
  static EnhancedParsingResult parseCompleteDataStream(String rawData) {
    try {
      debugPrint('🔍 $_tag: Starting enhanced parsing: ${rawData.length} chars');
      debugPrint('🔍 $_tag: Raw data: "$rawData"');

      // Step 1: Validate basic structure
      if (!_validateBasicStructure(rawData)) {
        debugPrint('❌ $_tag: Basic structure validation failed');
        return _createErrorResult('INVALID_STRUCTURE', 'Invalid data structure');
      }

      // Step 2: Extract messages
      final messages = _extractMessages(rawData);

      if (messages.isEmpty) {
        debugPrint('❌ $_tag: No valid messages found');
        return _createErrorResult('NO_MESSAGES', 'No valid messages found');
      }

      // Step 3: Process all messages
      EnhancedParsingResult? lastResult;
      List<EnhancedDevice> allDevices = [];

      for (String message in messages) {
        final result = _parseSingleMessage(message);
        if (result.devices.isNotEmpty) {
          allDevices.addAll(result.devices);
          lastResult = result;
        }
      }

      if (lastResult == null) {
        debugPrint('❌ $_tag: No valid device data found');
        return _createErrorResult('NO_DEVICE_DATA', 'No valid device data found');
      }

      debugPrint('✅ $_tag: Enhanced parsing successful: ${lastResult.devices.length} devices');
      return lastResult;

    } catch (e, stackTrace) {
      debugPrint('❌ $_tag: Parsing error: $e');
      debugPrint('🔍 $_tag: Stack trace: $stackTrace');
      return _createErrorResult('PARSING_ERROR', 'Parsing failed: $e');
    }
  }

  /// Validate basic structure
  static bool _validateBasicStructure(String rawData) {
    // For testing: accept short data (6 chars) without STX/ETX
    if (rawData.length == 6 && RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(rawData)) {
      debugPrint('🧪 $_tag: Accepting test data format: $rawData');
      return true;
    }

    // Must start with STX and end with ETX
    if (!rawData.contains(String.fromCharCode(stx)) ||
        !rawData.contains(String.fromCharCode(etx))) {
      return false;
    }

    // Must have at least checksum + one message
    final cleanData = rawData.replaceAll(RegExp(r'[^\x02\x03]'), '');
    final parts = cleanData.split(String.fromCharCode(etx));

    return parts.length >= 2; // At least checksum + one message
  }

  /// Extract individual messages
  static List<String> _extractMessages(String rawData) {
    final List<String> messages = [];

    // Handle 6-char device data (AA BB CC format)
    if (rawData.length == 6 && RegExp(r'^[0-9A-Fa-f]{6}$').hasMatch(rawData)) {
      debugPrint('🧪 $_tag: Processing 6-char device data: $rawData');
      final stx = String.fromCharCode(0x02);
      final etx = String.fromCharCode(0x03);
      messages.add(stx + rawData + etx);
      return messages;
    }

    // Handle 2-char device data (AA format - slave offline)
    if (rawData.length == 2 && RegExp(r'^[0-9A-Fa-f]{2}$').hasMatch(rawData)) {
      debugPrint('🧪 $_tag: Processing 2-char offline device: $rawData');
      final stx = String.fromCharCode(0x02);
      final etx = String.fromCharCode(0x03);
      messages.add(stx + rawData + etx);
      return messages;
    }

    // Remove STX and ETX markers, then split by STX
    String cleanData = rawData.replaceAll(String.fromCharCode(stx), '');
    final parts = cleanData.split(String.fromCharCode(etx));

    for (String part in parts) {
      if (part.isNotEmpty && part.length >= 4) { // Minimum checksum + data
        messages.add(String.fromCharCode(stx) + part + String.fromCharCode(etx));
      }
    }

    return messages;
  }

  /// Parse single message
  static EnhancedParsingResult _parseSingleMessage(String message) {
    try {
      debugPrint('📊 $_tag: Parsing message: ${message.length} chars');

      // Handle 6-char device data (STX + 6 chars + ETX = 8 chars total)
      if (message.length == 8) {
        final deviceData = message.substring(1, 7); // Extract 6 chars between STX and ETX
        debugPrint('🧪 $_tag: Parsing 6-char device data: $deviceData');
        return _parseSingleDeviceFrom6Char(deviceData);
      }

      // Handle 2-char device data (STX + 2 chars + ETX = 4 chars total)
      if (message.length == 4) {
        final addressData = message.substring(1, 3); // Extract 2 chars between STX and ETX
        debugPrint('🧪 $_tag: Parsing 2-char offline device: $addressData');
        return _parseOfflineDevice(addressData);
      }

      // Step 1: Extract checksum (first 4 chars after stx)
      final checksum = message.substring(1, 5).toUpperCase();

      // Step 2: Extract and validate message data
      final messageData = message.substring(6, message.length - 1); // Remove STX, checksum, ETX
      final calculatedChecksum = _calculateChecksum(messageData);

      if (checksum != calculatedChecksum) {
        debugPrint('❌ $_tag: Checksum mismatch: $checksum vs $calculatedChecksum');
        return _createErrorResult('CHECKSUM_MISMATCH', 'Checksum validation failed');
      }

      // Step 3: Determine message type and parse
      if (messageData.length == 4 && RegExp(r'^[0-9A-Fa-f]{4}$').hasMatch(messageData)) {
        // Master control signal (4 digits)
        return _parseMasterControlSignal(messageData, checksum);
      } else {
        // Slave pooling data (63 devices × 5 zones = 315 chars minimum)
        return _parseSlavePoolingData(messageData, checksum);
      }

    } catch (e) {
      debugPrint('❌ $_tag: Single message parsing error: $e');
      return _createErrorResult('SINGLE_MESSAGE_ERROR', 'Single message parsing failed: $e');
    }
  }

  /// Parse single device from 6-char format (AA BB CC)
  static EnhancedParsingResult _parseSingleDeviceFrom6Char(String testData) {
    try {
      debugPrint('🧪 $_tag: Parsing single device from 6-char: $testData');

      final address = testData.substring(0, 2);
      final troubleStatus = testData.substring(2, 4); // BB - Trouble status
      final alarmBellStatus = testData.substring(4, 6); // CC - Alarm + Bell status

      // Parse trouble zones (BB byte)
      final troubleByte = int.parse(troubleStatus, radix: 16);

      // Parse alarm zones + bell (CC byte)
      final alarmBellByte = int.parse(alarmBellStatus, radix: 16);
      final bellActive = (alarmBellByte & 0x20) != 0; // Bit 5 = Bell status
      final alarmZones = alarmBellByte & 0x1F; // Lower 5 bits = alarm zones

      final List<ZoneStatus> zones = [];

      for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
        final zoneBit = 1 << zoneIndex;

        final hasTrouble = (troubleByte & zoneBit) != 0;
        final hasAlarm = (alarmZones & zoneBit) != 0;
        final isActive = hasAlarm || hasTrouble;

        String description = '';
        if (hasAlarm && hasTrouble) {
          description = 'Zone ${zoneIndex + 1} - ALARM & TROUBLE';
        } else if (hasAlarm) {
          description = 'Zone ${zoneIndex + 1} - ALARM ACTIVE';
        } else if (hasTrouble) {
          description = 'Zone ${zoneIndex + 1} - TROUBLE DETECTED';
        } else {
          description = 'Zone ${zoneIndex + 1} - Normal';
        }

        zones.add(ZoneStatus(
          zoneNumber: zoneIndex + 1,
          isActive: isActive,
          hasTrouble: hasTrouble,
          hasAlarm: hasAlarm,
          description: description,
        ));
      }

      // Determine device status
      final isConnected = true; // 6-digit format means online
      final hasTrouble = troubleByte != 0x00;
      final hasAlarm = alarmZones != 0x00;

      final deviceStatus = DeviceStatus(
        hasPower: isConnected,
        hasTrouble: hasTrouble,
        hasAlarm: hasAlarm,
        outputBellActive: bellActive,
      );

      final device = EnhancedDevice(
        address: address,
        isConnected: isConnected,
        zones: zones,
        deviceStatus: deviceStatus,
        timestamp: DateTime.now(),
      );

      debugPrint('✅ $_tag: Single device parsed: Address $address, Connected $isConnected');
      debugPrint('🔍 $_tag: Zone 1 - Alarm: ${zones[0].hasAlarm}, Trouble: ${zones[0].hasTrouble}, Bell: $bellActive');

      return EnhancedParsingResult(
        cycleType: 'single_device',
        checksum: '',
        status: _getDeviceStatus(hasAlarm, hasTrouble, bellActive),
        totalDevices: 1,
        connectedDevices: 1,
        disconnectedDevices: 0,
        devices: [device],
        rawData: {
          'device_data': testData,
          'address': address,
          'trouble_status': troubleStatus,
          'alarm_bell_status': alarmBellStatus,
          'bell_active': bellActive,
        },
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ $_tag: Single device parsing error: $e');
      return _createErrorResult('SINGLE_DEVICE_ERROR', 'Single device parsing failed: $e');
    }
  }

  /// Parse offline device from 2-char address
  static EnhancedParsingResult _parseOfflineDevice(String addressData) {
    try {
      debugPrint('🧪 $_tag: Parsing offline device: $addressData');

      final address = addressData.toUpperCase();

      // Create 5 zones, all inactive
      final List<ZoneStatus> zones = [];
      for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
        zones.add(ZoneStatus(
          zoneNumber: zoneIndex + 1,
          isActive: false,
          hasTrouble: false,
          hasAlarm: false,
          description: 'Zone ${zoneIndex + 1} - Device Offline',
        ));
      }

      // Device is offline
      final deviceStatus = DeviceStatus(
        hasPower: false,
        hasTrouble: false,
        hasAlarm: false,
        outputBellActive: false,
      );

      final device = EnhancedDevice(
        address: address,
        isConnected: false,
        zones: zones,
        deviceStatus: deviceStatus,
        timestamp: DateTime.now(),
      );

      debugPrint('✅ $_tag: Offline device parsed: Address $address, Status: OFFLINE');

      return EnhancedParsingResult(
        cycleType: 'offline_device',
        checksum: '',
        status: 'offline',
        totalDevices: 1,
        connectedDevices: 0,
        disconnectedDevices: 1,
        devices: [device],
        rawData: {
          'address_data': addressData,
          'address': address,
          'status': 'offline',
        },
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ $_tag: Offline device parsing error: $e');
      return _createErrorResult('OFFLINE_DEVICE_ERROR', 'Offline device parsing failed: $e');
    }
  }

  /// Get device status string based on conditions
  static String _getDeviceStatus(bool hasAlarm, bool hasTrouble, bool bellActive) {
    if (hasAlarm && bellActive) {
      return 'alarm_with_bell';
    } else if (hasAlarm) {
      return 'alarm_silent';
    } else if (hasTrouble) {
      return 'trouble';
    } else {
      return 'normal';
    }
  }

  /// Parse master control signal
  static EnhancedParsingResult _parseMasterControlSignal(String signalData, String checksum) {
    final controlType = MasterControlSignal._parseControlType(signalData);

    final result = EnhancedParsingResult(
      cycleType: 'master_control',
      checksum: checksum,
      status: 'master_signal_received',
      totalDevices: 0,
      connectedDevices: 0,
      disconnectedDevices: 0,
      devices: [],
      masterSignal: MasterControlSignal(
        signal: signalData,
        checksum: checksum,
        timestamp: DateTime.now(),
        type: controlType,
      ),
      rawData: {
        'signal_data': signalData,
        'checksum': checksum,
        'type': 'master_control',
      },
      timestamp: DateTime.now(),
    );

    debugPrint('🎛 $_tag: Master control signal: ${controlType.toString()}');
    return result;
  }

  /// Parse slave pooling data (63 devices)
  static EnhancedParsingResult _parseSlavePoolingData(String deviceData, String checksum) {
    try {
      debugPrint('📱 $_tag: Parsing slave data: ${deviceData.length} chars');

      // Expected format: 63 devices × 6 chars = 378 chars minimum
      if (deviceData.length < 378) {
        debugPrint('⚠️ $_tag: Incomplete slave data: ${deviceData.length} chars (expected 378+)');
        return _createErrorResult('INCOMPLETE_SLAVE_DATA', 'Incomplete slave data');
      }

      final List<EnhancedDevice> devices = [];
      int connectedCount = 0;
      int disconnectedCount = 0;

      // Parse each device (6 chars per device)
      for (int i = 0; i < 63 && i * 6 < deviceData.length; i++) {
        final deviceStart = i * 6;
        if (deviceStart + 6 > deviceData.length) break;

        final deviceDataPart = deviceData.substring(deviceStart, deviceStart + 6);
        final device = _parseSingleEnhancedDevice(deviceDataPart, i + 1);

        devices.add(device);
        if (device.isConnected) {
          connectedCount++;
        } else {
          disconnectedCount++;
        }
      }

      final status = _determineSystemStatus(connectedCount, disconnectedCount);

      final result = EnhancedParsingResult(
        cycleType: 'slave_pooling',
        checksum: checksum,
        status: status,
        totalDevices: 63,
        connectedDevices: connectedCount,
        disconnectedDevices: disconnectedCount,
        devices: devices,
        rawData: {
          'slave_data': deviceData,
          'checksum': checksum,
          'device_count': devices.length,
        },
        timestamp: DateTime.now(),
      );

      debugPrint('✅ $_tag: Slave parsing successful: $connectedCount/63 connected');
      return result;

    } catch (e) {
      debugPrint('❌ $_tag: Slave pooling parsing error: $e');
      return _createErrorResult('SLAVE_PARSING_ERROR', 'Slave parsing failed: $e');
    }
  }

  /// Parse single enhanced device with 5 zones
  static EnhancedDevice _parseSingleEnhancedDevice(String deviceData, int deviceNumber) {
    try {
      if (deviceData.length != 6) {
        throw Exception('Invalid device data length: ${deviceData.length}');
      }

      final address = deviceData.substring(0, 2).toUpperCase();
      final statusHex = deviceData.substring(2);

      // Parse 5 zone statuses from single byte (hex)
      final statusByte = int.parse(statusHex, radix: 16);
      final List<ZoneStatus> zones = [];

      for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
        // Map zone bits to specific statuses (customize based on your system)
        final zoneStatus = _mapZoneStatus(statusByte, zoneIndex);

        zones.add(ZoneStatus(
          zoneNumber: zoneIndex + 1,
          isActive: zoneStatus.isActive, // Use isActive from _mapZoneStatus for consistency
          hasTrouble: zoneStatus.hasTrouble,
          hasAlarm: zoneStatus.hasAlarm,
          description: zoneStatus.description,
        ));
      }

      // Determine device connection status
      final isConnected = zones.any((zone) => zone.isActive);

      // Parse device overall status
      final deviceStatus = DeviceStatus(
        hasPower: isConnected,
        hasTrouble: zones.any((zone) => zone.hasTrouble),
        hasAlarm: zones.any((zone) => zone.hasAlarm),
        outputBellActive: zones.any((zone) => zone.hasAlarm), // Bell follows alarm
      );

      return EnhancedDevice(
        address: address,
        isConnected: isConnected,
        zones: zones,
        deviceStatus: deviceStatus,
        timestamp: DateTime.now(),
      );

    } catch (e) {
      debugPrint('❌ $_tag: Enhanced device parsing error: $e');
      // Return default disconnected device
      return EnhancedDevice(
        address: deviceNumber.toString().padLeft(2, '0').toUpperCase(),
        isConnected: false,
        zones: List.generate(5, (index) => ZoneStatus(
          zoneNumber: index + 1,
          isActive: false,
          description: 'Parsing error: $e',
        )),
        deviceStatus: DeviceStatus(
          hasPower: false,
          hasTrouble: false,
          hasAlarm: false,
        ),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Map zone status based on system byte (customize this)
  static ZoneStatus _mapZoneStatus(int statusByte, int zoneIndex) {
    // This is where you customize the zone mapping based on your system
    // Example mapping - adjust according to your actual zone definitions
    bool isActive = false;
    bool hasAlarm = false;
    bool hasTrouble = false;
    String description = '';

    switch (zoneIndex) {
      case 0: // Zone 1
        isActive = (statusByte & 0x01) != 0 || (statusByte & 0x02) != 0;
        hasAlarm = (statusByte & 0x01) != 0;
        hasTrouble = (statusByte & 0x02) != 0;
        description = hasAlarm ? 'Zone 1 - Alarm Active' :
                    hasTrouble ? 'Zone 1 - Trouble Detected' : 'Zone 1 - Normal';
        break;

      case 1: // Zone 2
        isActive = (statusByte & 0x04) != 0 || (statusByte & 0x08) != 0;
        hasAlarm = (statusByte & 0x04) != 0;
        hasTrouble = (statusByte & 0x08) != 0;
        description = hasAlarm ? 'Zone 2 - Alarm Active' :
                    hasTrouble ? 'Zone 2 - Trouble Detected' : 'Zone 2 - Normal';
        break;

      case 2: // Zone 3
        isActive = (statusByte & 0x10) != 0 || (statusByte & 0x20) != 0;
        hasAlarm = (statusByte & 0x10) != 0;
        hasTrouble = (statusByte & 0x20) != 0;
        description = hasAlarm ? 'Zone 3 - Alarm Active' :
                    hasTrouble ? 'Zone 3 - Trouble Detected' : 'Zone 3 - Normal';
        break;

      case 3: // Zone 4
        isActive = (statusByte & 0x40) != 0 || (statusByte & 0x80) != 0;
        hasAlarm = (statusByte & 0x40) != 0;
        hasTrouble = (statusByte & 0x80) != 0;
        description = hasAlarm ? 'Zone 4 - Alarm Active' :
                    hasTrouble ? 'Zone 4 - Trouble Detected' : 'Zone 4 - Normal';
        break;

      case 4: // Zone 5
        // For devices with more complex mapping, you might need additional bytes
        // This is a simplified example - adjust based on your system
        isActive = false;
        hasAlarm = false;
        hasTrouble = false;
        description = 'Zone 5 - Needs additional mapping';
        break;

      default:
        isActive = false;
        hasAlarm = false;
        hasTrouble = false;
        description = 'Zone $zoneIndex - Unknown';
    }

    return ZoneStatus(
      zoneNumber: zoneIndex + 1,
      isActive: isActive,
      hasTrouble: hasTrouble,
      hasAlarm: hasAlarm,
      description: description,
    );
  }

  /// Determine overall system status
  static String _determineSystemStatus(int connectedCount, int disconnectedCount) {
    if (connectedCount == 63 && disconnectedCount == 0) {
      return 'all_slaves_connected_normal';
    } else if (connectedCount > 0 && disconnectedCount > 0) {
      return 'partial_connection_disconnected';
    } else if (connectedCount > 0 && disconnectedCount == 0) {
      return 'partial_connection_with_alarm';
    } else if (connectedCount == 0 && disconnectedCount == 63) {
      return 'all_slaves_disconnected';
    } else {
      return 'unknown_status';
    }
  }

  /// Calculate checksum for validation
  static String _calculateChecksum(String data) {
    int checksum = 0;
    for (int i = 0; i < data.length; i++) {
      checksum ^= data.codeUnitAt(i);
    }
    return checksum.toRadixString(16).toUpperCase().padLeft(4, '0');
  }

  /// Create error result
  static EnhancedParsingResult _createErrorResult(String cycleType, String status) {
    return EnhancedParsingResult(
      cycleType: cycleType,
      checksum: 'ERROR',
      status: status,
      totalDevices: 0,
      connectedDevices: 0,
      disconnectedDevices: 0,
      devices: [],
      rawData: {
        'error': true,
        'error_type': cycleType,
        'error_message': status,
      },
      timestamp: DateTime.now(),
    );
  }

  /// Generate training examples
  static String generateTrainingExample(EnhancedParsingResult result) {
    final buffer = StringBuffer();

    // Add STX start
    buffer.write(String.fromCharCode(stx));

    // Add example checksum (40DF for 63 devices)
    buffer.write('40DF');

    // Add STX for device data start
    buffer.write(String.fromCharCode(stx));

    // Generate slave pooling data based on result
    if (result.devices.isNotEmpty) {
      for (int i = 0; i < result.devices.length; i++) {
        if (i > 0) buffer.write(String.fromCharCode(stx)); // Separator

        final device = result.devices[i];
        final address = device.address;

        // Generate 5-zone status byte
        int statusByte = 0;
        for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
          if (zoneIndex < device.zones.length) {
            final zone = device.zones[zoneIndex];
            if (zone.hasAlarm) {
              statusByte |= (1 << zoneIndex); // Set bit for alarm
            }
            // Add other status mappings as needed
          }
        }

        // Format: Address (2) + Status (4) = 6 chars
        final statusHex = statusByte.toRadixString(16).toUpperCase().padLeft(4, '0');
        buffer.write('$address$statusHex');
      }
    }

    // Add ETX end
    buffer.write(String.fromCharCode(etx));

    return buffer.toString();
  }

  /// Get system summary
  static String getSystemSummary(EnhancedParsingResult result) {
    final buffer = StringBuffer();

    buffer.writeln('=== ENHANCED ZONE PARSER SUMMARY ===');
    buffer.writeln('Cycle Type: ${result.cycleType}');
    buffer.writeln('System Status: ${result.status}');
    buffer.writeln('Total Devices: ${result.totalDevices}');
    buffer.writeln('Connected: ${result.connectedDevices}');
    buffer.writeln('Disconnected: ${result.disconnectedDevices}');
    buffer.writeln('Active Zones: ${result.totalActiveZones}');
    buffer.writeln('Trouble Zones: ${result.totalTroubleZones}');
    buffer.writeln('Alarm Zones: ${result.totalAlarmZones}');

    if (result.masterSignal != null) {
      buffer.writeln('Master Signal: ${result.masterSignal!.signal} (${result.masterSignal!.type})');
    }

    return buffer.toString();
  }
}