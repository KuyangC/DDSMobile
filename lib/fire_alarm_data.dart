import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:async';
import 'services/enhanced_notification_service.dart';
import 'services/led_status_decoder.dart';
import 'services/firebase_log_handler.dart';
import 'services/enhanced_zone_parser.dart';

// Simple Zone Status class for compatibility
class ZoneStatus {
  final int zoneNumber;
  final int moduleNumber;
  final int zoneInModule;
  final bool isOnline;
  final bool hasAlarm;
  final bool hasTrouble;
  final Color displayColor;
  final Color borderColor;
  final DateTime lastUpdate;

  ZoneStatus({
    required this.zoneNumber,
    required this.moduleNumber,
    required this.zoneInModule,
    this.isOnline = true,
    this.hasAlarm = false,
    this.hasTrouble = false,
    this.displayColor = Colors.white,
    this.borderColor = Colors.grey,
    required this.lastUpdate,
  });
}

// Data bersama untuk aplikasi Fire Alarm Monitoring
class FireAlarmData extends ChangeNotifier {
  bool _mounted = true;
  late FirebaseLogHandler _logHandler;

  @override
  void dispose() {
    _mounted = false;
    _logHandler.dispose();
    disposeResources();
    super.dispose();
  }
  // Firebase Database reference
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  DatabaseReference get databaseRef => _databaseRef;

  // Get log handler for external access
  FirebaseLogHandler get logHandler => _logHandler;

  // ============= UI CONFIGURATION SECTION =============
  // Centralized UI configuration for consistent design across all pages

  // Logo Configuration
  static const double logoWidth = 160.0;
  static const double logoHeight = 40.0;
  static const double logoLeftPadding = 50.0; // Space for hamburger menu
  static const double logoTopPadding = 10.0;
  static const double logoBottomPadding = 0.0;
  static const double logoContainerMaxHeight = 45.0;
  static const Alignment logoAlignment = Alignment.centerLeft;
  static const String logoAssetPath = 'assets/data/images/LOGO.png';

  // Hamburger Menu Configuration
  static const double hamburgerLeftPadding = 8.0;
  static const double hamburgerTopPadding = 15.0;
  static const double hamburgerIconSize = 28.0;
  static const Color hamburgerIconColor = Colors.black87;

  // Connection Status Configuration
  static const double connectionStatusRightPadding = 15.0;
  static const double connectionStatusTopPadding = 18.0;
  static const double connectionCircleSize = 8.0;
  static const double connectionMaxCircleSize = 10.0;
  static const double connectionFontSize = 8.0;
  static const double connectionMaxFontSize = 12.0;
  static const Color connectionActiveColor = Colors.green;
  static const Color connectionInactiveColor = Colors.grey;

  // Drawer Configuration
  static const double drawerWidth = 280.0;
  static const double drawerHeaderHeight = 180.0;
  static const Color drawerHeaderColor = Color.fromARGB(255, 18, 148, 42);
  static const double drawerLogoSize = 60.0;
  static const double drawerTitleFontSize = 20.0;
  static const double drawerSubtitleFontSize = 14.0;

  // Helper method to get logo container widget (reusable across all pages)
  static Widget getLogoContainer({Widget? child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(
        left: logoLeftPadding,
        top: logoTopPadding,
        bottom: logoBottomPadding,
      ),
      constraints: const BoxConstraints(maxHeight: logoContainerMaxHeight),
      child: Align(
        alignment: logoAlignment,
        child:
            child ??
            Image.asset(
              logoAssetPath,
              width: logoWidth,
              height: logoHeight,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: logoWidth,
                  height: logoHeight,
                  padding: const EdgeInsets.all(8),
                  child: const Text(
                    'DDS LOGO',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }

  // Helper method to get header with hamburger, logo, and connection status
  static Widget getCompleteHeader({
    required bool isConnected,
    GlobalKey<ScaffoldState>? scaffoldKey,
  }) {
    return Container(
      color: Colors.white,
      height: 60, // Fixed height for consistent layout
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calculate responsive sizes based on screen width
          final screenWidth = constraints.maxWidth;
          final isSmallScreen = screenWidth < 360;
          final isMediumScreen = screenWidth >= 360 && screenWidth < 600;

          // Responsive logo size
          final responsiveLogoWidth = isSmallScreen
              ? 120.0
              : isMediumScreen
              ? 140.0
              : logoWidth;
          final responsiveLogoHeight = isSmallScreen
              ? 30.0
              : isMediumScreen
              ? 35.0
              : logoHeight;

          // Responsive connection status text
          final showFullConnectionText = screenWidth > 320;

          return Stack(
            children: [
              // Logo in the center-left with responsive sizing
              Positioned(
                left: 50, // Space for hamburger menu
                top: 0,
                bottom: 0,
                child: Center(
                  child: Image.asset(
                    logoAssetPath,
                    width: responsiveLogoWidth,
                    height: responsiveLogoHeight,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: responsiveLogoWidth,
                        height: responsiveLogoHeight,
                        padding: const EdgeInsets.all(8),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Text(
                            'DDS LOGO',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              // Hamburger menu on the left
              Positioned(
                left: 8,
                top: 0,
                bottom: 0,
                child: Center(
                  child: IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: hamburgerIconColor,
                      size: hamburgerIconSize,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      // Use scaffoldKey if provided, otherwise try to find Scaffold
                      if (scaffoldKey != null &&
                          scaffoldKey.currentState != null) {
                        scaffoldKey.currentState!.openDrawer();
                      } else {
                        // Fallback: try to find Scaffold in context
                        final scaffold = Scaffold.of(context);
                        scaffold.openDrawer();
                      }
                    },
                  ),
                ),
              ),
              // Connection status on the right with responsive layout
              Positioned(
                right: 10,
                top: 0,
                bottom: 0,
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: isSmallScreen ? 6 : 8,
                        height: isSmallScreen ? 6 : 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected
                              ? connectionActiveColor
                              : connectionInactiveColor,
                        ),
                      ),
                      if (showFullConnectionText) ...[
                        const SizedBox(width: 4),
                        Text(
                          isConnected ? 'CONNECTED' : 'DISCONNECTED',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontSize: isSmallScreen ? 8 : 10,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ============= END UI CONFIGURATION =============

  // Informasi umum sistem
  String projectName = '---PROJECT ID---';
  String panelType = '--- PANEL TYPE ---';
  int numberOfModules = 0; // Start with 0 to indicate not loaded
  int numberOfZones = 0; // Start with 0 to indicate not loaded from Firebase
  String activeZone = '';
  static const String systemVersion = '1.0.0';

  // Fonnte API configuration
  static const String fonnteToken = 'uK4BivaM3UDZN89kkS6A';
  static const String defaultTarget = '6281295865655'; // Default admin number
  static const String fonnteApiUrl = 'https://api.fonnte.com/send';

  // Recent activity and last update time
  String recentActivity = '';
  DateTime lastUpdateTime = DateTime.now();
  DateTime? lastSendTime;

  List<Map<String, dynamic>> activityLogs = [];

  // Firebase connectivity status
  bool isFirebaseConnected = false;

  // Enhanced notification service instance
  final EnhancedNotificationService _notificationService = EnhancedNotificationService();

  // LED Status Decoder instance
  final LEDStatusDecoder _ledDecoder = LEDStatusDecoder();

  // Enhanced Zone Parser instance
  EnhancedZoneParser? enhancedParser;

  StreamSubscription<List<ZoneStatus>>? _zoneStatusSubscription;
  StreamSubscription<String?>? _rawDataSubscription;

  // Zone data status tracking
  bool _hasValidZoneData = false;
  final bool _hasNoParsedPacketData = true;
  bool _isInitiallyLoading = true;
  DateTime? _lastValidZoneDataTime;
  static const Duration _noZoneDataTimeout = Duration(seconds: 10);
  static const Duration _initialLoadingTimeout = Duration(seconds: 5);

  FireAlarmData() {
    debugPrint('FireAlarmData Constructor - Starting initialization');

    // Initialize log handler
    _logHandler = FirebaseLogHandler();

    // Don't initialize default modules here, wait for Firebase data
    _initializeFirebaseListeners();
    // Don't sync on startup, wait for Firebase data

    // After setting up listeners, try to fetch initial data
    _fetchInitialData();

    // Start LED monitoring
    _ledDecoder.startMonitoring();

  
    // Set timer to end initial loading state
    Timer(_initialLoadingTimeout, () {
      if (_mounted && _isInitiallyLoading) {
        _isInitiallyLoading = false;
        _updateCurrentStatus();
        notifyListeners();
        debugPrint('📱 Initial loading timeout completed');
      }
    });

    debugPrint('FireAlarmData Constructor - Initialization completed');
  }

  
  
  // Check for no zone data condition (called periodically)
  void checkNoZoneDataCondition() {
    try {
      if (_lastValidZoneDataTime == null) {
        // No valid zone data received since app start
        if (!_hasValidZoneData) {
          _hasValidZoneData = false;
          _updateCurrentStatus();
          notifyListeners();
          debugPrint('⚠️ NO ZONE DATA condition - No valid zone data since app start');
        }
      } else {
        final timeSinceLastData = DateTime.now().difference(_lastValidZoneDataTime!);
        if (timeSinceLastData > _noZoneDataTimeout) {
          // More than 10 seconds since last valid zone data
          if (_hasValidZoneData) {
            _hasValidZoneData = false;
            _updateCurrentStatus();
            notifyListeners();
            debugPrint('⚠️ NO ZONE DATA condition triggered - Last valid data: ${timeSinceLastData.inSeconds}s ago');
          }
        } else if (!_hasValidZoneData && timeSinceLastData <= _noZoneDataTimeout) {
          // We had no zone data but now data is within timeout
          _hasValidZoneData = true;
          _updateCurrentStatus();
          notifyListeners();
          debugPrint('📡 NO ZONE DATA condition cleared - Zone data received within timeout');
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking no zone data condition: $e');
    }
  }

  // Fetch initial data from Firebase
  void _fetchInitialData() async {
    try {
      // Try projectInfo
      final projectSnapshot = await _databaseRef.child('projectInfo').get();
      if (projectSnapshot.exists) {
        final data = projectSnapshot.value as Map<dynamic, dynamic>?;
        if (data != null) {
          // Update if projectInfo has values
          if (data.containsKey('numberOfModules')) {
            numberOfModules = data['numberOfModules'] as int;
          }
          if (data.containsKey('numberOfZones')) {
            numberOfZones = data['numberOfZones'] as int;
          }
          if (data.containsKey('projectName')) {
            projectName = data['projectName'] as String;
          }
          if (data.containsKey('panelType')) {
            panelType = data['panelType'] as String;
          }
          if (data.containsKey('activeZone')) {
            activeZone = data['activeZone'] as String? ?? '';
          }
          if (data.containsKey('lastUpdateTime')) {
            try {
              String updateTime = data['lastUpdateTime'] as String;
              if (updateTime.length > 20) {
                updateTime = '${updateTime.substring(0, 23)}Z';
              }
              lastUpdateTime = DateTime.parse(updateTime);
            } catch (e) {
              // Invalid date - use current time
              lastUpdateTime = DateTime.now();
            }
          }
        }
      }

      // Generate modules if we have numberOfModules
      if (numberOfModules > 0) {
        _parseActiveZoneToModules(activeZone);
      }

      // Check if we have activity logs, if not, create sample data
      await _fetchActivityLogs();

      notifyListeners();
    } catch (e) {
      // Error fetching initial data - silently handle the error
      // In production, you might want to use a logging service here
      // For now, we'll just ignore the error as the app can still function
    }
  }

  // Fetch activity logs and create sample data if needed
  Future<void> _fetchActivityLogs() async {
    try {
      final logsSnapshot = await _databaseRef.child('history/statusLogs').get();
      if (!logsSnapshot.exists || logsSnapshot.value == null) {
        debugPrint('📋 No activity logs found, creating sample data');
        await _createSampleActivityLogs();
      }
    } catch (e) {
      debugPrint('📋 Error fetching activity logs: $e');
      await _createSampleActivityLogs();
    }
  }

  // Create sample activity logs for testing
  Future<void> _createSampleActivityLogs() async {
    try {
      final now = DateTime.now();
      final sampleLogs = [
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 2))),
          'time': '10:30',
          'status': 'SYSTEM RESET',
          'user': 'Admin',
          'timestamp': now.subtract(const Duration(days: 2)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1))),
          'time': '14:15',
          'status': 'DRILL ON',
          'user': 'User1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now.subtract(const Duration(days: 1))),
          'time': '14:20',
          'status': 'DRILL OFF',
          'user': 'User1',
          'timestamp': now.subtract(const Duration(days: 1)).toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now),
          'time': '09:00',
          'status': 'ALARM ON',
          'user': 'System',
          'timestamp': now.toIso8601String(),
        },
        {
          'date': DateFormat('dd/MM/yyyy').format(now),
          'time': '09:05',
          'status': 'ACKNOWLEDGE ON',
          'user': 'User2',
          'timestamp': now.toIso8601String(),
        },
      ];

      // Write sample logs to Firebase
      for (var log in sampleLogs) {
        await _databaseRef.child('history/statusLogs').push().set(log);
      }
      
      debugPrint('📋 Created ${sampleLogs.length} sample activity logs');
    } catch (e) {
      debugPrint('📋 Error creating sample activity logs: $e');
    }
  }

  void _initializeFirebaseListeners() {

    // Listen for Firebase connection status
    _databaseRef.child('.info/connected').onValue.listen((event) {
      final connected = event.snapshot.value as bool? ?? false;
      if (isFirebaseConnected != connected) {
        isFirebaseConnected = connected;

        // Log connection status changes
        if (connected) {
          _logHandler.addConnectionLog(information: 'Firebase Connected');
          _logHandler.addStatusLog(status: 'SYSTEM ONLINE', user: 'SYSTEM');
        } else {
          _logHandler.addConnectionLog(information: 'Firebase Disconnected');
          _logHandler.addStatusLog(status: 'SYSTEM OFFLINE', user: 'SYSTEM');
        }

        notifyListeners();
      }
    });

    // Listen for system status changes from Firebase
    _databaseRef.child('systemStatus').onValue.listen((event) async {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        bool hasChange = false;
        List<String> changedKeys = [];
        data.forEach((key, value) {
          if (systemStatus.containsKey(key)) {
            bool oldStatus = systemStatus[key]!['status'] as bool;
            bool newStatus = value['status'] as bool;
            if (oldStatus != newStatus) {
              systemStatus[key]!['status'] = newStatus;
              hasChange = true;
              changedKeys.add(key);
            }
          }
        });
        if (hasChange) {
          _updateCurrentStatus();
          String activity = changedKeys.length == 1 ? '${changedKeys[0]} CHANGED' : 'MULTIPLE STATUS CHANGES';
          updateRecentActivity(activity);
          // No automatic send from listener
        }
      }
    });

    // Listen for recent activity changes from Firebase
    _databaseRef.child('recentActivity').onValue.listen((event) {
      final value = event.snapshot.value as String?;
      if (value != null && value != recentActivity) {
        recentActivity = value;
        notifyListeners();
      }
    });

    // Listen for projectInfo changes from Firebase (including activeZone, numberOfModules, numberOfZones, projectName, panelType, lastUpdateTime)
    _databaseRef.child('projectInfo').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        isFirebaseConnected = true;
        bool updated = false;
        bool modulesNeedUpdate = false;

        // Update projectName
        if (data.containsKey('projectName') &&
            projectName != data['projectName']) {
          projectName = data['projectName'];
          updated = true;
        }

        // Update panelType
        if (data.containsKey('panelType') && panelType != data['panelType']) {
          panelType = data['panelType'];
          updated = true;
        }

        // Update numberOfModules if present
        if (data.containsKey('numberOfModules')) {
          int newNumberOfModules = data['numberOfModules'] as int;
          if (numberOfModules != newNumberOfModules) {
            numberOfModules = newNumberOfModules;
            modulesNeedUpdate = true;
            updated = true;
          }
        }

        // Update numberOfZones if present
        if (data.containsKey('numberOfZones')) {
          int newNumberOfZones = data['numberOfZones'] as int;
          if (numberOfZones != newNumberOfZones) {
            numberOfZones = newNumberOfZones;
            updated = true;
          }
        }

        // Update lastUpdateTime if present
        if (data.containsKey('lastUpdateTime')) {
          try {
            String updateTime = data['lastUpdateTime'] as String;
            if (updateTime.length > 20) {
              updateTime = '${updateTime.substring(0, 23)}Z';
            }
            DateTime newLastUpdateTime = DateTime.parse(updateTime);
            if (lastUpdateTime != newLastUpdateTime) {
              lastUpdateTime = newLastUpdateTime;
              updated = true;
            }
          } catch (e) {
            // Invalid date - skip update
          }
        }

        // Update activeZone and parse modules
        if (data.containsKey('activeZone')) {
          String newActiveZone = data['activeZone'] as String? ?? '';
          if (activeZone != newActiveZone || modulesNeedUpdate) {
            activeZone = newActiveZone;
            _parseActiveZoneToModules(activeZone);
            updated = true;
          }
        } else {
          // No activeZone in Firebase, generate default modules if numberOfModules is set
          if (numberOfModules > 0 && (modules.isEmpty || modulesNeedUpdate)) {
            activeZone = '';
            _parseActiveZoneToModules('');
            updated = true;
          }
        }

        if (updated) {
          notifyListeners();
        }
      } else {
        isFirebaseConnected = false;
        // Reset to 0 when no Firebase data
        numberOfModules = 0;
        numberOfZones = 0;
        projectName = '---PROJECT ID---';
        panelType = '--- PANEL TYPE ---';
        activeZone = '';
        modules = [];
        notifyListeners();
      }
    });

      
    // Listen for history/statusLogs changes from Firebase - Optimized
    _databaseRef.child('history/statusLogs').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null) {
        // Optimized: Use map comprehension for faster processing
        final logs = <Map<String, dynamic>>[];

        data.forEach((key, value) {
          final action = value['status'] as String? ?? '';
          // Skip WhatsApp notification logs early
          if (action.contains('WhatsApp notification sent')) {
            return;
          }

          final user = value['user']?.toString() ?? '';
          var date = value['date'] as String? ?? '';
          var time = value['time'] as String? ?? '';

          // Optimized: Only parse timestamp if needed
          if (date.isEmpty || time.isEmpty) {
            final timestamp = value['timestamp'] as String?;
            if (timestamp?.isNotEmpty == true) {
              try {
                // Handle large timestamps from Firebase
                String ts = timestamp!;
                if (ts.length > 20) {
                  // If timestamp is too long, it might be microseconds, truncate it
                  ts = '${ts.substring(0, 23)}Z';
                }
                final dt = DateTime.parse(ts);
                date = DateFormat('dd/MM/yyyy').format(dt);
                time = DateFormat('HH:mm').format(dt);
              } catch (e) {
                // Use default values if parsing fails
                debugPrint('Timestamp parsing failed for $timestamp: $e');
                date = '';
                time = '';
              }
            }
          }

          if (action.isNotEmpty) {
            final timestampStr = (date.isNotEmpty && time.isNotEmpty)
                ? '$date | $time'
                : '';
            final fullActivity = user.isNotEmpty
                ? '[$timestampStr] $action | [ $user ]'
                : '[$timestampStr] $action';

            logs.add({
              'key': key,
              'activity': fullActivity,
              'time': time,
              'date': date,
              'timestamp': value['timestamp'] ?? '',
            });
          }
        });

        // Optimized: Sort only if we have logs
        if (logs.isNotEmpty) {
          logs.sort((a, b) {
            try {
              String tsA = a['timestamp'] as String;
              String tsB = b['timestamp'] as String;

              // Handle long timestamps
              if (tsA.length > 20) {
                tsA = '${tsA.substring(0, 23)}Z';
              }
              if (tsB.length > 20) {
                tsB = '${tsB.substring(0, 23)}Z';
              }

              return DateTime.parse(tsB).compareTo(DateTime.parse(tsA));
            } catch (e) {
              return 0;
            }
          });
        }

        activityLogs = logs;
        // Optimized: Minimal debug logging
        if (logs.length % 100 == 0) { // Log every 100 entries to reduce spam
          debugPrint('📋 Activity logs: ${logs.length} entries');
        }
        notifyListeners();
      } else {
        activityLogs = [];
        notifyListeners();
      }
    });
      // LISTENER BARU: Listen for all_slave_data changes from Firebase
    _databaseRef.child('all_slave_data').onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data != null && data.containsKey('raw_data')) {
        String rawData = data['raw_data'] as String;
        debugPrint('📡 Received all_slave_data: $rawData');

        _parseAllSlaveData(rawData);
      }
    });
    
  }

  // Status sistem dengan warna yang konsisten
  Map<String, Map<String, dynamic>> systemStatus = {
    'AC Power': {
      'status': true,
      'activeColor': Colors.green,
      'inactiveColor': Colors.grey.shade300,
    },

    'DC Power': {
      'status': false,
      'activeColor': Colors.green,
      'inactiveColor': Colors.grey.shade300,
    },

    'Alarm': {
      'status': false,
      'activeColor': Colors.red,
      'inactiveColor': Colors.grey.shade300,
    },
    'Trouble': {
      'status': false,
      'activeColor': Colors.orange,
      'inactiveColor': Colors.grey.shade300,
    },
    'Drill': {
      'status': false,
      'activeColor': Colors.red,
      'inactiveColor': Colors.grey.shade300,
    },
    'Silenced': {
      'status': false,
      'activeColor': Colors.yellow.shade700,
      'inactiveColor': Colors.grey.shade300,
    },
    'Disabled': {
      'status': false,
      'activeColor': Colors.grey.shade600,
      'inactiveColor': Colors.grey.shade300,
    },
  };

  // Data untuk daftar modul dengan 6 zona (5 zona biasa + 1 zona bell)
  List<Map<String, dynamic>> modules = [];

  // Parse activeZone string to modules list
  void _parseActiveZoneToModules(String activeZoneString) {
    // Only generate modules if numberOfModules is greater than 0
    if (numberOfModules <= 0) {
      modules = [];
      return;
    }

    if (activeZoneString.trim().isEmpty) {
      // Generate default modules with ZONA 01, ZONA 02, etc.
      List<Map<String, dynamic>> defaultModules = [];
      int zoneCode = 1;
      for (int i = 1; i <= numberOfModules; i++) {
        List<String> zones = [];
        for (int j = 0; j < 5; j++) {
          String code = zoneCode.toString().padLeft(2, '0');
          zones.add('ZONA $code');
          zoneCode++;
        }
        zones.add('BELL');
        defaultModules.add({
          'number': i.toString().padLeft(2, '0'),
          'zones': zones,
        });
      }
      modules = defaultModules;
      return;
    }

    // Parse activeZone string: "#001#AREA MAKAN, #002#AREA TIDUR, #003#AREA DAPUR, ..."
    List<String> zoneEntries = activeZoneString.split(',');
    Map<int, List<String>> moduleZonesMap = {};

    // First, organize zones by module number
    for (var entry in zoneEntries) {
      entry = entry.trim();
      if (entry.isEmpty) continue;

      // Extract zone code and name - support both 2 and 3 digit formats
      final match = RegExp(r'#(\d{2,3})#(.+)').firstMatch(entry);
      if (match != null) {
        final zoneCode = int.parse(match.group(1)!);
        final zoneName = match.group(2)!;

        // Calculate module number (5 zones per module)
        final moduleNumber = ((zoneCode - 1) ~/ 5 + 1);

        if (!moduleZonesMap.containsKey(moduleNumber)) {
          moduleZonesMap[moduleNumber] = [];
        }

        // Calculate position within module (0-4)
        final positionInModule = (zoneCode - 1) % 5;

        // Ensure list has enough space
        while (moduleZonesMap[moduleNumber]!.length <= positionInModule) {
          moduleZonesMap[moduleNumber]!.add('');
        }

        // Set zone name at correct position
        moduleZonesMap[moduleNumber]![positionInModule] = zoneName;
      }
    }

    // Build modules list with zones and add 'BELL' zone to each module
    List<Map<String, dynamic>> parsedModules = [];

    // Generate all modules from 1 to numberOfModules
    for (int i = 1; i <= numberOfModules; i++) {
      List<String> zones = moduleZonesMap[i] ?? [];

      // Fill empty positions with default zone names
      for (int j = 0; j < 5; j++) {
        if (j >= zones.length || zones[j].isEmpty) {
          if (j >= zones.length) {
            zones.add('');
          }
          int zoneNumber = (i - 1) * 5 + j + 1;
          zones[j] = 'Zone ${zoneNumber.toString().padLeft(2, '0')}';
        }
      }

      // Ensure exactly 5 zones
      zones = zones.take(5).toList();

      parsedModules.add({
        'number': i.toString().padLeft(2, '0'),
        'zones': [...zones, 'BELL'],
      });
    }

    if (parsedModules.isNotEmpty) {
      modules = parsedModules;
    }
  }

  // Metode untuk mengubah status sistem
  void updateSystemStatus(String statusName, bool newStatus) {
    if (systemStatus.containsKey(statusName)) {
      bool oldStatus = systemStatus[statusName]!['status'];

      systemStatus[statusName]!['status'] = newStatus;
      _updateCurrentStatus();
      lastUpdateTime = DateTime.now();
      notifyListeners();
      // Sync to Firebase
      _databaseRef.child('systemStatus/$statusName/status').set(newStatus);

      // Log status changes
      if (oldStatus != newStatus) {
        _logStatusChange(statusName, newStatus);
      }
    }
  }

  
  // Log status changes
  void _logStatusChange(String statusName, bool newStatus) {
    String statusText;
    switch (statusName) {
      case 'Alarm':
        statusText = newStatus ? 'SYSTEM IN ALARM' : 'ALARM CLEARED';
        break;
      case 'Trouble':
        statusText = newStatus ? 'SYSTEM IN TROUBLE' : 'TROUBLE CLEARED';
        break;
      case 'Drill':
        statusText = newStatus ? 'DRILL MODE ACTIVATED' : 'DRILL MODE DEACTIVATED';
        break;
      case 'Silenced':
        statusText = newStatus ? 'SYSTEM SILENCED' : 'SYSTEM UNSILENCED';
        break;
      case 'AC Power':
        statusText = newStatus ? 'AC POWER RESTORED' : 'AC POWER FAILURE';
        break;
      case 'DC Power':
        statusText = newStatus ? 'DC POWER RESTORED' : 'DC POWER FAILURE';
        break;
      default:
        statusText = newStatus ? '$statusName ACTIVATED' : '$statusName DEACTIVATED';
    }

    _logHandler.addStatusLog(status: statusText, user: 'SYSTEM');
  }

  // Log module connections
  void logModuleConnection(int moduleNumber, bool connected) {
    String information = connected
        ? 'Module #${moduleNumber.toString().padLeft(2, '0')} Connected'
        : 'Module #${moduleNumber.toString().padLeft(2, '0')} Disconnected';

    _logHandler.addConnectionLog(information: information);
  }

  // Metode untuk update recent activity
  void updateRecentActivity(String activity, {String? user}) {
    final now = DateTime.now();
    final formattedDateTime = DateFormat('dd/MM/yyyy | HH:mm').format(now);
    final fullActivity = user != null ? '[$formattedDateTime] $activity | ($user)' : '[$formattedDateTime] $activity';
    recentActivity = fullActivity;
    lastUpdateTime = now;
    notifyListeners();
    // Sync to Firebase
    _databaseRef.child('recentActivity').set(fullActivity);
    _databaseRef
        .child('projectInfo/lastUpdateTime')
        .set(lastUpdateTime.toIso8601String());
    // Log to history if user provided
    if (user != null) {
      logHistory(activity, user);
    }
  }

  // Method to log history to Firebase
  void logHistory(String status, String user) {
    final now = DateTime.now();
    final date = DateFormat('dd/MM/yyyy').format(now);
    final time = DateFormat('HH:mm').format(now);
    final timestamp = now.toIso8601String(); // For sorting
    _databaseRef.child('history/statusLogs').push().set({
      'date': date,
      'time': time,
      'status': status,
      'user': user,
      'timestamp': timestamp,
    });
  }

  // Metode untuk mendapatkan status sistem
  bool getSystemStatus(String statusName) {
    return systemStatus[statusName]!['status'] as bool;
  }

  // Metode untuk mendapatkan warna status aktif
  Color getActiveColor(String statusName) {
    return systemStatus[statusName]!['activeColor'] as Color;
  }

  // Metode untuk mendapatkan warna status tidak aktif
  Color getInactiveColor(String statusName) {
    return systemStatus[statusName]!['inactiveColor'] as Color;
  }

  // New properties for current status text and color
  String _currentStatusText = 'NO DATA';
  Color _currentStatusColor = Colors.grey;

  bool _isResetting = false;

  bool get isResetting => _isResetting;

  set isResetting(bool value) {
    _isResetting = value;
    _updateCurrentStatus();
    notifyListeners();
  }

  String get currentStatusText => _currentStatusText;
  Color get currentStatusColor => _currentStatusColor;

  // Getters for zone data status
  bool get hasValidZoneData => _hasValidZoneData;
  bool get hasNoParsedPacketData => _hasNoParsedPacketData;
  bool get isInitiallyLoading => _isInitiallyLoading;

  // Private method to update current status text and color based on systemStatus and zone data
  void _updateCurrentStatus() {
    // Check for system resetting first (highest priority)
    if (_isResetting) {
      _currentStatusText = 'SYSTEM RESETTING';
      _currentStatusColor = Colors.white;
      return;
    }

    // Check for initial loading state (highest priority for status)
    if (_isInitiallyLoading) {
      _currentStatusText = 'LOADING DATA';
      _currentStatusColor = Colors.blue;
      return;
    }

    // Check for no valid zone data (highest priority for status)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      _currentStatusText = 'NO DATA';
      _currentStatusColor = Colors.grey;
      return;
    }
    
    // Check if we have any modules/zones configured
    if (modules.isEmpty && numberOfModules > 0) {
      _currentStatusText = 'SYSTEM CONFIGURING';
      _currentStatusColor = Colors.orange;
      return;
    }
    
    // Check for system statuses from Firebase
    if (getSystemStatus('Alarm')) {
      _currentStatusText = 'SYSTEM ALARM';
      _currentStatusColor = getActiveColor('Alarm');
    } else if (getSystemStatus('Trouble')) {
      _currentStatusText = 'SYSTEM TROUBLE';
      _currentStatusColor = getActiveColor('Trouble');
    } else if (getSystemStatus('Drill')) {
      _currentStatusText = 'SYSTEM DRILL';
      _currentStatusColor = getActiveColor('Drill');
    } else if (getSystemStatus('Silenced')) {
      _currentStatusText = 'SYSTEM SILENCED';
      _currentStatusColor = getActiveColor('Silenced');
    } else if (getSystemStatus('Disabled')) {
      _currentStatusText = 'SYSTEM DISABLED';
      _currentStatusColor = getActiveColor('Disabled');
    } else {
      _currentStatusText = 'SYSTEM NORMAL';
      _currentStatusColor = Colors.green;
    }
  }

  // Bell trouble status tracking
  final Map<int, bool> _moduleBellTroubleStatus = {};

  // Method to check if there are any trouble zones in the system
  bool hasTroubleZones() {
    return getSystemStatus('Trouble') || hasBellTrouble();
  }

  // Method to check if there are any alarm zones in the system
  bool hasAlarmZones() {
    return getSystemStatus('Alarm') || hasBellTrouble(); // Bell trouble should trigger alarm
  }

  // Method to get list of active alarm zones
  List<Map<String, dynamic>> getActiveAlarmZones() {
    List<Map<String, dynamic>> alarmZones = [];

    // Get alarm zones using system status
    if (alarmZones.isEmpty) {
      // Check system status and create basic alarm zone entry
      if (getSystemStatus('Alarm')) {
        alarmZones.add({
          'zoneNumber': 0, // System-wide alarm
          'area': 'SYSTEM ALARM',
          'timestamp': DateFormat('HH:mm:ss').format(DateTime.now()),
          'moduleNumber': 0,
          'zoneInModule': 0,
        });
      }
    }

    return alarmZones;
  }

  // Method to check if there is bell trouble in any module
  bool hasBellTrouble() {
    return _moduleBellTroubleStatus.values.any((status) => status == true);
  }

  // Method to update bell trouble status for a specific module
  void updateBellTroubleStatus(int moduleNumber, bool hasTrouble) {
    _moduleBellTroubleStatus[moduleNumber] = hasTrouble;
    notifyListeners();
  }

  // Enhanced system status detection with zone data awareness
  String getSystemStatusWithTroubleDetection() {
    // Check if system is resetting
    if (_isResetting) {
      return 'SYSTEM RESETTING';
    }

    // Check for initial loading state first (highest priority)
    if (_isInitiallyLoading) {
      return 'LOADING DATA';
    }

    // Check for no valid zone data first (highest priority)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      return 'NO DATA';
    }
    
    // Check for drill mode first (highest priority)
    if (getSystemStatus('Drill')) {
      return 'SYSTEM DRILL';
    }
    
    // Check for alarm zones (bell trouble should trigger FIRE status)
    if (hasAlarmZones()) {
      return 'SYSTEM FIRE'; // Use FIRE instead of ALARM for bell trouble
    }
    
    // Check for trouble zones (excluding bell trouble)
    if (getSystemStatus('Trouble') && !hasBellTrouble()) {
      return 'SYSTEM TROUBLE';
    }
    
    // Check for silenced status
    if (getSystemStatus('Silenced')) {
      return 'SYSTEM SILENCED';
    }
    
    // Check for disabled status
    if (getSystemStatus('Disabled')) {
      return 'SYSTEM DISABLED';
    }
    
    return 'SYSTEM NORMAL';
  }

  // Enhanced system status color detection with zone data awareness
  Color getSystemStatusColorWithTroubleDetection() {
    // Check if system is resetting
    if (_isResetting) {
      return Colors.white;
    }

    // Check for initial loading state first (highest priority)
    if (_isInitiallyLoading) {
      return Colors.blue;
    }

    // Check for no valid zone data first (highest priority)
    if (!_hasValidZoneData || _hasNoParsedPacketData) {
      return Colors.grey;
    }
    
    // Check for drill mode first (highest priority)
    if (getSystemStatus('Drill')) {
      return getActiveColor('Drill'); // Red for drill
    }
    
    // Check for alarm zones (bell trouble should trigger FIRE status)
    if (hasAlarmZones()) {
      return Colors.red; // Red for FIRE status
    }
    
    // Check for trouble zones (excluding bell trouble)
    if (getSystemStatus('Trouble') && !hasBellTrouble()) {
      return getActiveColor('Trouble'); // Orange for trouble
    }
    
    // Check for silenced status
    if (getSystemStatus('Silenced')) {
      return getActiveColor('Silenced'); // Yellow for silenced
    }
    
    // Check for disabled status
    if (getSystemStatus('Disabled')) {
      return getActiveColor('Disabled'); // Grey for disabled
    }
    
    return Colors.green; // Green for normal
  }

  Future<void> _sendWhatsAppMessage() async {
    try {
      // Ensure at least 10 seconds between sends to avoid WhatsApp ban
      if (lastSendTime != null) {
        final diff = DateTime.now().difference(lastSendTime!).inSeconds;
        if (diff < 10) {
          await Future.delayed(Duration(seconds: 10 - diff));
        }
      }

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
      final formattedTime = dateFormat.format(lastUpdateTime);

      final message =
          '''
*(DDS FIRE ALARM MONITORING SYSTEM)*

*($projectName // $panelType)*
*(${modules.length} MODULES)*

*RECENT STATUS :*
*$recentActivity || $formattedTime*

*SYSTEM STATUS :*
*$_currentStatusText || $formattedTime*
''';

      // Get all user phone numbers from Firebase
      List<String> phoneNumbers = [
        defaultTarget,
      ]; // Always include default admin number

      try {
        final usersSnapshot = await _databaseRef.child('users').get();
        if (usersSnapshot.exists) {
          Map<dynamic, dynamic> users =
              usersSnapshot.value as Map<dynamic, dynamic>;
          for (var userData in users.values) {
            if (userData['phone'] != null && userData['isActive'] == true) {
              String phone = userData['phone'].toString().trim();
              // Convert phone to international format if needed
              if (phone.startsWith('0')) {
                phone = '62${phone.substring(1)}'; // Convert 08xxx to 628xxx
              } else if (phone.startsWith('+62')) {
                phone = phone.substring(1); // Remove + sign
              }
              // Avoid duplicates
              if (!phoneNumbers.contains(phone)) {
                phoneNumbers.add(phone);
              }
            }
          }
        }
      } catch (e) {
        // If error getting users, continue with default target only
        // Error getting user phones: $e
      }

      // Join all phone numbers with comma and set delay of 5 seconds
      String targets = phoneNumbers.join(',');

      final response = await http.post(
        Uri.parse(fonnteApiUrl),
        headers: {
          'Authorization': fonnteToken,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'target': targets,
          'message': message,
          'delay': '5', // 5 seconds delay between each message
          'countryCode': '62',
        },
      );

      if (response.statusCode == 200) {
        // Success
        lastSendTime = DateTime.now();
      } else {
        // Failed to send WhatsApp message
      }
    } catch (e) {
      // Error sending WhatsApp message
    }
  }

  Future<void> _sendFCMMessage() async {
    final dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss');
    final formattedTime = dateFormat.format(lastUpdateTime);

    // Initialize notification service if needed
    await _notificationService.initialize();

    // Determine event type from recent activity
    String eventType = 'UNKNOWN';
    if (recentActivity.contains('DRILL')) {
      eventType = 'DRILL';
    } else if (recentActivity.contains('SYSTEM RESET')) {
      eventType = 'SYSTEM RESET';
    } else if (recentActivity.contains('SILENCED')) {
      eventType = 'SILENCE';
    } else if (recentActivity.contains('ACKNOWLEDGE')) {
      eventType = 'ACKNOWLEDGE';
    } else if (recentActivity.contains('ALARM')) {
      eventType = 'ALARM';
    } else if (recentActivity.contains('TROUBLE')) {
      eventType = 'TROUBLE';
    }

    // Send notification using EnhancedNotificationService
    await _notificationService.showNotification(
      title: 'Fire Alarm: $eventType',
      body: 'Status: ${_extractStatusFromActivity(recentActivity)} - By: ${_extractUserFromActivity(recentActivity)}',
      eventType: eventType,
      data: {
        'status': _extractStatusFromActivity(recentActivity),
        'user': _extractUserFromActivity(recentActivity),
        'projectName': projectName,
        'panelType': panelType,
        'timestamp': formattedTime,
      },
    );
  }

  // Helper method to extract status from activity string
  String _extractStatusFromActivity(String activity) {
    try {
      final regex = RegExp(r':\s*(ON|OFF)');
      final match = regex.firstMatch(activity);
      if (match != null) {
        return match.group(1) ?? 'UNKNOWN';
      }
    } catch (e) {
      debugPrint('Error extracting status from activity: $e');
    }
    return 'UNKNOWN';
  }

  // Helper method to extract user from activity string
  String _extractUserFromActivity(String activity) {
    try {
      final regex = RegExp(r'\(([^)]+)\)$');
      final match = regex.firstMatch(activity);
      if (match != null) {
        return match.group(1) ?? 'Unknown User';
      }
    } catch (e) {
      debugPrint('Error extracting user from activity: $e');
    }
    return 'Unknown User';
  }

  // Public method to send notification manually
  Future<void> sendNotification() async {
    await _sendWhatsAppMessage();
    await _sendFCMMessage();
  }

  // Public method to manually refresh modules
  void refreshModules() {
    if (numberOfModules > 0) {
      _parseActiveZoneToModules(activeZone);
      notifyListeners();
    }
  }

  // Get zone name by its absolute number (e.g., 1 to 250)
  String getZoneNameByAbsoluteNumber(int zoneNumber) {
    if (modules.isEmpty || zoneNumber <= 0) {
      return 'Unknown Zone';
    }

    // Each module has 5 functional zones + 1 BELL zone.
    // The calculation is based on 5 functional zones per module.
    const int zonesPerModule = 5;

    // Calculate module index (0-based) and zone index within the module (0-based)
    final int moduleIndex = ((zoneNumber - 1) ~/ zonesPerModule);
    final int zoneIndexInModule = (zoneNumber - 1) % zonesPerModule;

    // Ensure the calculated module and zone indices are within bounds
    if (moduleIndex < modules.length) {
      final module = modules[moduleIndex];
      if (module['zones'] is List) {
        final zones = module['zones'] as List<dynamic>;
        if (zoneIndexInModule < zones.length) {
          // The 'zones' list contains 6 items (5 zones + 'BELL'). We only care about the first 5.
          return zones[zoneIndexInModule].toString();
        }
      }
    }

    return 'Zone $zoneNumber'; // Fallback if not found
  }

  // Get zone status by its absolute number (e.g., 1 to 250)
  String? getZoneStatusByAbsoluteNumber(int zoneNumber) {
    if (modules.isEmpty || zoneNumber <= 0) {
      return null;
    }

    // Check if system is in alarm
    if (getSystemStatus('Alarm')) {
      return 'Alarm';
    }

    // Check if system is in trouble
    if (getSystemStatus('Trouble')) {
      return 'Trouble';
    }

    // Check if system is in drill mode
    if (getSystemStatus('Drill')) {
      return 'Drill';
    }

    // Check if system is silenced
    if (getSystemStatus('Silenced')) {
      return 'Silenced';
    }

    // Return normal status if no issues
    return 'Normal';
  }

  // Clear all activity logs from local state and Firebase
  void clearAllActivityLogs() {
    activityLogs.clear();
    notifyListeners();
  }

  // Dispose resources
  void disposeResources() {
    _zoneStatusSubscription?.cancel();
    _rawDataSubscription?.cancel();
    _ledDecoder.dispose();
  }

  // ============= LED STATUS DECODER INTEGRATION =============
  
  /// Get current LED status from decoder
  LEDStatus? get currentLEDStatus => _ledDecoder.currentLEDStatus;
  
  /// Get LED status stream for real-time updates
  Stream<LEDStatus?> get ledStatusStream => _ledDecoder.ledStatusStream;
  
  /// Get raw LED data stream
  Stream<String?> get rawLEDDataStream => _ledDecoder.rawLEDDataStream;
  
  /// Get LED color for specific LED type
  Color? getLEDColorFromDecoder(LEDType ledType) => _ledDecoder.getLEDColor(ledType);
  
  /// Get LED status for specific LED type
  bool? getLEDStatusFromDecoder(LEDType ledType) => _ledDecoder.getLEDStatus(ledType);
  
  /// Get current system context from LED decoder
  SystemContext? get currentSystemContext => _ledDecoder.currentSystemContext;
  
  /// Check if system is in alarm state (from LED decoder)
  bool get isSystemInAlarmFromLED => _ledDecoder.isSystemInAlarm;
  
  /// Check if system is in trouble state (from LED decoder)
  bool get isSystemInTroubleFromLED => _ledDecoder.isSystemInTrouble;
  
  /// Check if system is silenced (from LED decoder)
  bool get isSystemSilencedFromLED => _ledDecoder.isSystemSilenced;
  
  /// Check if system is disabled (from LED decoder)
  bool get isSystemDisabledFromLED => _ledDecoder.isSystemDisabled;
  
  /// Get power status from LED decoder
  PowerStatus get powerStatusFromLED => _ledDecoder.powerStatus;
  
  /// Process manual LED data (for testing)
  LEDStatus? processManualLEDData(String rawData) => _ledDecoder.processManualLEDData(rawData);
  
  /// Enhanced system status detection using LED decoder data
  String getSystemStatusFromLED() {
    if (_ledDecoder.currentLEDStatus == null) {
      return 'NO LED DATA';
    }
    
    switch (_ledDecoder.currentSystemContext) {
      case SystemContext.systemDisabledMaintenance:
        return 'SYSTEM DISABLED - MAINTENANCE';
      case SystemContext.systemSilencedManual:
        return 'SYSTEM SILENCED - MANUAL';
      case SystemContext.alarmWithTroubleCondition:
        return 'ALARM WITH TROUBLE CONDITION';
      case SystemContext.supervisoryAlarmActive:
        return 'SUPERVISORY ALARM ACTIVE';
      case SystemContext.fullAlarmActive:
        return 'FULL ALARM ACTIVE';
      case SystemContext.troubleConditionOnly:
        return 'TROUBLE CONDITION DETECTED';
      case SystemContext.supervisoryPreAlarm:
        return 'SUPERVISORY PRE-ALARM';
      case SystemContext.systemNormal:
        return 'SYSTEM NORMAL';
      case null:
        return 'NO LED DATA';
    }
  }
  
  /// Get system status color based on LED decoder data
  Color getSystemStatusColorFromLED() {
    if (_ledDecoder.currentLEDStatus == null) {
      return Colors.grey;
    }
    
    switch (_ledDecoder.currentSystemContext) {
      case SystemContext.fullAlarmActive:
      case SystemContext.alarmWithTroubleCondition:
        return Colors.red;
      case SystemContext.supervisoryAlarmActive:
        return Colors.orange;
      case SystemContext.troubleConditionOnly:
      case SystemContext.supervisoryPreAlarm:
        return Colors.yellow;
      case SystemContext.systemSilencedManual:
        return Colors.amber;
      case SystemContext.systemDisabledMaintenance:
        return Colors.grey;
      case SystemContext.systemNormal:
        return Colors.green;
      case null:
        return Colors.grey;
    }
  }
  
  /// Enhanced LED color getter that uses decoder data when available
  Color getEnhancedLEDColor(String statusName) {
    // If LED decoder has data, use it
    if (_ledDecoder.currentLEDStatus != null) {
      switch (statusName) {
        case 'AC Power':
          return _ledDecoder.getLEDColor(LEDType.acPower) ?? Colors.grey.shade300;
        case 'DC Power':
          return _ledDecoder.getLEDColor(LEDType.dcPower) ?? Colors.grey.shade300;
        case 'Alarm':
          return _ledDecoder.getLEDColor(LEDType.alarm) ?? Colors.grey.shade300;
        case 'Trouble':
          return _ledDecoder.getLEDColor(LEDType.trouble) ?? Colors.grey.shade300;
        case 'Supervisory':
          return _ledDecoder.getLEDColor(LEDType.supervisory) ?? Colors.grey.shade300;
        case 'Silenced':
          return _ledDecoder.getLEDColor(LEDType.silenced) ?? Colors.grey.shade300;
        case 'Disabled':
          return _ledDecoder.getLEDColor(LEDType.disabled) ?? Colors.grey.shade300;
      }
    }
    
    // Fallback to original logic - use systemStatus colors
    if (getSystemStatus(statusName)) {
      return getActiveColor(statusName);
    } else {
      return getInactiveColor(statusName);
    }
  }
  
  /// Enhanced LED status getter that uses decoder data when available
  bool getEnhancedLEDStatus(String statusName) {
    // If LED decoder has data, use it
    if (_ledDecoder.currentLEDStatus != null) {
      switch (statusName) {
        case 'AC Power':
          return _ledDecoder.getLEDStatus(LEDType.acPower) ?? false;
        case 'DC Power':
          return _ledDecoder.getLEDStatus(LEDType.dcPower) ?? false;
        case 'Alarm':
          return _ledDecoder.getLEDStatus(LEDType.alarm) ?? false;
        case 'Trouble':
          return _ledDecoder.getLEDStatus(LEDType.trouble) ?? false;
        case 'Supervisory':
          return _ledDecoder.getLEDStatus(LEDType.supervisory) ?? false;
        case 'Silenced':
          return _ledDecoder.getLEDStatus(LEDType.silenced) ?? false;
        case 'Disabled':
          return _ledDecoder.getLEDStatus(LEDType.disabled) ?? false;
      }
    }
    
    // Fallback to original logic
    return getSystemStatus(statusName);
  }
}
