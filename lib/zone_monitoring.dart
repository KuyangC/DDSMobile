import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:math';
import 'fire_alarm_data.dart';

class ZoneMonitoringPage extends StatefulWidget {
  const ZoneMonitoringPage({super.key});

  @override
  State<ZoneMonitoringPage> createState() => _ZoneMonitoringPageState();
}

class _ZoneMonitoringPageState extends State<ZoneMonitoringPage> with AutomaticKeepAliveClientMixin {
  // State untuk zona yang dipilih
  int? _selectedZoneNumber;

  // State untuk visibility container
  final bool _showZoneNameContainer = true;

  // Module names cache
  final Map<String, String> _moduleNames = {};  // Cache for module names

  // Firebase reference
  late final DatabaseReference _moduleNamesRef;
  late final Future<DataSnapshot> _moduleNamesFuture;

  @override
  void initState() {
    super.initState();
    // Initialize Firebase reference
    try {
      _moduleNamesRef = FirebaseDatabase.instanceFor(
        app: Firebase.app('fireAlarmApp'),
      ).ref('moduleNames');
    } catch (e) {
      debugPrint('Failed to get named Firebase app, using default: $e');
      _moduleNamesRef = FirebaseDatabase.instance.ref('moduleNames');
    }

    // Assign the future for the FutureBuilder
    _moduleNamesFuture = _moduleNamesRef.get();

    // Start listening for real-time updates
    _listenToModuleNames();
  }

  
  @override
  void dispose() {
    // Cleanup Firebase listeners if needed
    super.dispose();
  }

  // Listen to module names from Firebase
  void _listenToModuleNames() {
    _moduleNamesRef.onValue.listen((DatabaseEvent event) {
      debugPrint('Firebase listener triggered');
      if (event.snapshot.value != null) {
        final Map<dynamic, dynamic> data = event.snapshot.value as Map;
        debugPrint('Firebase listener data: ${data.toString()}');

        // Update module names cache
        bool hasChanges = false;
        for (var entry in data.entries) {
          final moduleKey = entry.key.toString();
          final moduleValue = entry.value.toString();

          // Only update if value actually changed
          if (_moduleNames[moduleKey] != moduleValue) {
            _moduleNames[moduleKey] = moduleValue;
            hasChanges = true;
            debugPrint('Updated module $moduleKey from Firebase: "$moduleValue"');
          }
        }

        // Trigger rebuild to update UI if there are changes
        if (hasChanges && mounted) {
          setState(() {});
        }
      } else {
        debugPrint('Firebase listener: No data found');
      }
    });
  }

  // Save module name to Firebase
  Future<void> _saveModuleName(String moduleKey, String moduleName) async {
    // Store previous name for potential rollback
    String previousName = _moduleNames[moduleKey] ?? '';

    try {
      // Update local cache immediately for better UX
      _moduleNames[moduleKey] = moduleName;

      // Save to Firebase
      await _moduleNamesRef.child(moduleKey).set(moduleName);
      debugPrint('✅ Saved module name: $moduleKey = "$moduleName"');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Module $moduleKey name updated'),
            duration: const Duration(seconds: 1),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving module name: $e');
      // Revert local change on error
      _moduleNames[moduleKey] = previousName;

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update module name'),
            duration: const Duration(seconds: 2),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }


  // Show dialog to edit module name
  Future<void> _showEditModuleDialog(int moduleNumber) async {
    final moduleKey = moduleNumber.toString();
    final TextEditingController dialogController = TextEditingController(
      text: _moduleNames[moduleKey] ?? 'Module $moduleNumber'
    );

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Module $moduleNumber Name'),
          content: TextField(
            controller: dialogController,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Module Name',
              hintText: 'Enter module name...',
            ),
            onSubmitted: (value) {
              Navigator.of(context).pop();
              _saveModuleName(moduleKey, value);
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save'),
              onPressed: () {
                Navigator.of(context).pop();
                _saveModuleName(moduleKey, dialogController.text);
              },
            ),
          ],
        );
      },
    );
  }

  // Get zone color based on system status
  Color _getZoneColorFromSystem(int zoneNumber, FireAlarmData fireAlarmData) {
    // Check if there's no data or disconnected
    if (!fireAlarmData.hasValidZoneData || fireAlarmData.isInitiallyLoading) {
      return Colors.grey;  // Grey for disconnect/no data
    }

    // Check individual zone status
    final zoneStatus = fireAlarmData.getZoneStatusByAbsoluteNumber(zoneNumber);

    // Check if this specific zone is in alarm
    if (zoneStatus?.toLowerCase().contains('alarm') == true ||
        zoneStatus?.toLowerCase().contains('fire') == true) {
      return Colors.red;
    }

    // Check if this specific zone is in trouble
    if (zoneStatus?.toLowerCase().contains('trouble') == true ||
        zoneStatus?.toLowerCase().contains('fault') == true) {
      return Colors.orange;
    }

    // Check if system is in alarm
    if (fireAlarmData.getSystemStatus('Alarm')) {
      return Colors.red;
    }

    // Check if system is in trouble
    if (fireAlarmData.getSystemStatus('Trouble')) {
      return Colors.orange;
    }

    // Check if system is in drill mode
    if (fireAlarmData.getSystemStatus('Drill')) {
      return Colors.red;
    }

    // Check if system is silenced
    if (fireAlarmData.getSystemStatus('Silenced')) {
      return Colors.yellow.shade700;
    }

    // Default white for normal status
    return Colors.white;
  }

  // Get zone border color
  Color _getZoneBorderColor(int zoneNumber) {
    return Colors.grey.shade300;
  }

  // Build selected zone info container with back button
  Widget _buildSelectedZoneInfoContainer(FireAlarmData fireAlarmData) {
    Color containerColor;
    Color borderColor;
    Color textColor;

    if (_selectedZoneNumber == null) {
      containerColor = Colors.white;  // Changed to white
      borderColor = Colors.grey.shade300;
      textColor = Colors.black87;
    } else {
      // Get zone color based on system status
      containerColor = _getZoneColorFromSystem(_selectedZoneNumber!, fireAlarmData);

      // Set border and text color based on container color
      if (containerColor == Colors.red) {
        borderColor = Colors.red.shade300;
        textColor = Colors.white;
      } else if (containerColor == Colors.orange) {
        borderColor = Colors.orange.shade300;
        textColor = Colors.white;
      } else if (containerColor == Colors.yellow.shade700) {
        borderColor = Colors.yellow.shade600;
        textColor = Colors.black;
      } else if (containerColor == Colors.grey) {
        borderColor = Colors.grey.shade400;
        textColor = Colors.black;
      } else {
        borderColor = Colors.grey.shade300;
        textColor = Colors.black87;
      }
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 8.0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Back Button
          InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: textColor,
                size: 20,
              ),
            ),
          ),

          // Spacer
          const SizedBox(width: 15),

          // Project and Zone Info - Centered
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Project Name
                Text(
                  fireAlarmData.projectName,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                ),

                // Zone Info
                if (_selectedZoneNumber != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'SELECTED: ZONA ${_selectedZoneNumber.toString().padLeft(3, '0')} - ${fireAlarmData.getZoneNameByAbsoluteNumber(_selectedZoneNumber!)}',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ] else ...[
                  const SizedBox(height: 2),
                  Text(
                    'Total: ${fireAlarmData.numberOfModules} Modules | ${fireAlarmData.numberOfZones} Zones',
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Connection Status Indicator
          _buildConnectionStatusIndicator(fireAlarmData.isFirebaseConnected, textColor),
        ],
      ),
    );
  }

  Widget _buildConnectionStatusIndicator(bool isConnected, Color textColor) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isConnected ? Colors.green : Colors.grey,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          isConnected ? 'CONNECTED' : 'DISCONNECTED',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: textColor,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Column(
            children: [

              // Selected Zone Info Container - Wrapped in Consumer for real-time updates
              if (_showZoneNameContainer) ...[
                Consumer<FireAlarmData>(
                  builder: (context, fireAlarmData, child) {
                    return _buildSelectedZoneInfoContainer(fireAlarmData);
                  },
                ),
                const SizedBox(height: 10),
              ],

              // Content
              Expanded(
                child: FutureBuilder<DataSnapshot>(
                  future: _moduleNamesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(child: Text('Error loading data: ${snapshot.error}'));
                    }

                    if (snapshot.hasData && snapshot.data!.exists) {
                      final dynamic snapshotValue = snapshot.data!.value;
                      if (snapshotValue is Map) {
                        final Map<dynamic, dynamic> data = snapshotValue;
                        data.forEach((key, value) {
                          _moduleNames[key.toString()] = value.toString();
                        });
                      } else if (snapshotValue is List) {
                        final List<dynamic> data = snapshotValue;
                        for (int i = 0; i < data.length; i++) {
                          if (data[i] != null) {
                            _moduleNames[i.toString()] = data[i].toString();
                          }
                        }
                      }
                      debugPrint('✅ Initial module names loaded via FutureBuilder: ${_moduleNames.length}');
                    }

                    // Build the main UI now that data is ready
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final double screenWidth = constraints.maxWidth;
                        final double screenHeight = constraints.maxHeight;

                        // Responsive breakpoints
                        if (screenWidth < 360) {
                          // Small phones
                          return _buildCompactLayout(screenWidth, screenHeight);
                        } else if (screenWidth < 600) {
                          // Normal phones
                          return _buildPhoneLayout(screenWidth, screenHeight);
                        } else if (screenWidth < 900) {
                          // Tablets
                          return _buildTabletLayout(screenWidth, screenHeight);
                        } else {
                          // Desktop
                          return _buildDesktopLayout(screenWidth, screenHeight);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Compact layout for small phones (< 360px)
  Widget _buildCompactLayout(double screenWidth, double screenHeight) {
    const double spacing = 4.0;
    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return _buildModuleTable(tableIndex, screenWidth, spacing, compact: true);
        }),
      ),
    );
  }

  // Phone layout (360px - 600px)
  Widget _buildPhoneLayout(double screenWidth, double screenHeight) {
    const double spacing = 8.0;

    // For smaller screens, force single column to prevent overflow
    if (screenWidth < 400) {
      return SingleChildScrollView(
        child: Column(
          children: List.generate(7, (tableIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: _buildModuleTable(tableIndex, screenWidth, spacing),
            );
          }),
        ),
      );
    }

    // For larger phones, try 2 columns if space permits
    const double minItemWidth = 350.0;
    int numColumns = (screenWidth - 16) ~/ minItemWidth;
    numColumns = max(1, min(2, numColumns)); // Max 2 columns for phones

    if (numColumns == 1) {
      // Single column layout
      return SingleChildScrollView(
        child: Column(
          children: List.generate(7, (tableIndex) {
            return Padding(
              padding: EdgeInsets.only(bottom: spacing),
              child: _buildModuleTable(tableIndex, screenWidth - 16, spacing),
            );
          }),
        ),
      );
    }

    // Two column layout
    final double itemWidth = (screenWidth - 16 - spacing) / 2;

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return SizedBox(
            width: itemWidth,
            child: _buildModuleTable(tableIndex, itemWidth, spacing),
          );
        }),
      ),
    );
  }

  // Tablet layout (600px - 900px)
  Widget _buildTabletLayout(double screenWidth, double screenHeight) {
    const double spacing = 12.0;

    // Check if in landscape mode (width > height)
    final bool isLandscape = screenWidth > screenHeight;

    // Force 2 columns in landscape mode
    if (isLandscape) {
      final double itemWidth = (screenWidth - 16 - spacing) / 2;
      return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return SizedBox(
              width: itemWidth,
              child: _buildModuleTable(tableIndex, itemWidth, spacing),
            );
          }),
        ),
      );
    }

    // Portrait mode - original logic
    const double minItemWidth = 380.0;
    int numColumns = (screenWidth - 16) ~/ minItemWidth;
    numColumns = max(2, min(3, numColumns)); // 2-3 columns for tablet

    if (numColumns == 2) {
      // Two column layout
      final double itemWidth = (screenWidth - 16 - spacing) / 2;
      return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return SizedBox(
              width: itemWidth,
              child: _buildModuleTable(tableIndex, itemWidth, spacing),
            );
          }),
        ),
      );
    }

    // Three column layout
    final double itemWidth = (screenWidth - 16 - spacing * 2) / 3;
    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return SizedBox(
            width: itemWidth,
            child: _buildModuleTable(tableIndex, itemWidth, spacing),
          );
        }),
      ),
    );
  }

  // Desktop layout (> 900px)
  Widget _buildDesktopLayout(double screenWidth, double screenHeight) {
    const double spacing = 16.0;

    // Check if in landscape mode (width > height)
    final bool isLandscape = screenWidth > screenHeight;

    // Force 2 columns in landscape mode
    if (isLandscape) {
      final double itemWidth = (screenWidth - 16 - spacing) / 2;
      return SingleChildScrollView(
        child: Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: List.generate(7, (tableIndex) {
            return SizedBox(
              width: itemWidth,
              child: _buildModuleTable(tableIndex, itemWidth, spacing),
            );
          }),
        ),
      );
    }

    // Portrait mode - original logic
    const double minItemWidth = 400.0;
    int numColumns = (screenWidth - 16) ~/ minItemWidth;
    numColumns = max(3, min(4, numColumns)); // 3-4 columns for desktop

    final double itemWidth = (screenWidth - 16 - spacing * (numColumns - 1)) / numColumns;

    return SingleChildScrollView(
      child: Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: List.generate(7, (tableIndex) {
          return SizedBox(
            width: itemWidth,
            child: _buildModuleTable(tableIndex, itemWidth, spacing),
          );
        }),
      ),
    );
  }

  // Build individual module table
  Widget _buildModuleTable(int tableIndex, double itemWidth, double spacing, {bool compact = false}) {
    // Adjust font sizes based on available width
    final double fontSize = itemWidth < 320 ? 10.0 : (compact ? 11.0 : 13.0);
    final double rowHeight = compact ? 40.0 : 48.0;
    final double zoneSize = compact ? 24.0 : 28.0;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: DataTable(
        headingRowHeight: rowHeight,
        dataRowMinHeight: rowHeight,
        dataRowMaxHeight: rowHeight,
        horizontalMargin: compact ? 2.0 : 4.0,
        columnSpacing: 2.0,
        headingTextStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
        dataTextStyle: TextStyle(fontSize: fontSize),
        columns: [
          DataColumn(
            label: Text('#', style: TextStyle(fontSize: fontSize)),
          ),
          DataColumn(
            label: Text('AREA', style: TextStyle(fontSize: fontSize)),
          ),
          ...List.generate(5, (i) => DataColumn(
            label: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Text('${i + 1}', style: TextStyle(fontSize: fontSize)),
            ),
            numeric: false,
          )),
          DataColumn(
            label: Container(
              alignment: Alignment.center,
              padding: EdgeInsets.zero,
              child: Text('B', style: TextStyle(fontSize: fontSize)),
            ),
            numeric: false,
          ),
        ],
        rows: List.generate(10, (rowIndex) {
          final index = tableIndex * 10 + rowIndex;
          final moduleNumber = index + 1;

          // Don't create rows beyond module 63
          if (moduleNumber > 63) {
            return null;
          }

          return DataRow(
            cells: [
              DataCell(
                Text(
                  '#$moduleNumber',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: fontSize,
                  ),
                ),
              ),
              DataCell(
                SizedBox(
                  width: itemWidth * 0.35,
                  child: GestureDetector(
                    onTap: () => _showEditModuleDialog(moduleNumber),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: compact ? 2.0 : 4.0,
                        vertical: 4.0,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _moduleNames[moduleNumber.toString()] ?? 'Module $moduleNumber',
                        style: TextStyle(fontSize: fontSize),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
              ...List.generate(6, (colIndex) {
                final bool isBellZone = colIndex == 5;

                if (isBellZone) {
                  return DataCell(
                    Center(
                      child: Container(
                        width: zoneSize,
                        height: zoneSize,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          border: Border.all(
                            color: Colors.grey[400]!,
                            width: 1.0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.notifications,
                          size: zoneSize * 0.6,
                          color: Colors.black54,
                        ),
                      ),
                    ),
                  );
                }

                final int zoneNumber = index * 5 + colIndex + 1;

                return DataCell(
                  Center(
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedZoneNumber = zoneNumber;
                        });
                      },
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: zoneSize,
                        height: zoneSize,
                        decoration: BoxDecoration(
                          color: _getZoneColorFromSystem(
                            zoneNumber,
                            Provider.of<FireAlarmData>(context, listen: false),
                          ),
                          border: Border.all(
                            color: _selectedZoneNumber == zoneNumber
                                ? Colors.blueAccent
                                : _getZoneBorderColor(zoneNumber),
                            width: _selectedZoneNumber == zoneNumber ? 2.5 : 1.0,
                          ),
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: _selectedZoneNumber == zoneNumber
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withAlpha(150),
                                    spreadRadius: 2,
                                    blurRadius: 4,
                                    offset: const Offset(0, 1),
                                  ),
                                ]
                              : null,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        }).where((row) => row != null).cast<DataRow>().toList(),
      ),
    );
  }
}