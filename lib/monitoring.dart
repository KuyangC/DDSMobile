import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'fire_alarm_data.dart';
import 'widgets/unified_status_bar.dart';

class MonitoringPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const MonitoringPage({super.key, this.scaffoldKey});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  // Variable untuk menyimpan status trouble bell
  final Map<int, bool> _moduleBellTroubleStatus = {};

  // Zone status list (placeholder untuk compatibility)
  final List<ZoneStatus> _currentZoneStatus = [];

  @override
  void initState() {
    super.initState();
      }

  @override
  void dispose() {
    super.dispose();
  }


  // Get zone color based on system status
  Color _getZoneColorFromSystem(int zoneNumber) {
    final fireAlarmData = Provider.of<FireAlarmData>(context, listen: false);

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

  // Get zone text color based on background color for better visibility
  Color _getZoneTextColor(int zoneNumber) {
    Color backgroundColor = _getZoneColorFromSystem(zoneNumber);

    // Return black text for light backgrounds, white for dark backgrounds
    if (backgroundColor == Colors.white) {
      return Colors.black; // White background = black text
    } else if (backgroundColor == Colors.yellow) {
      return Colors.black; // Yellow background = black text
    } else {
      return Colors.white; // Red/Grey backgrounds = white text
    }
  }

  // Fungsi untuk memisahkan teks menjadi dua baris (kata pertama dan sisanya)
  String _splitTextIntoTwoLines(String text) {
    final words = text.split(' ');
    if (words.length <= 1) return text;

    // Ambil kata pertama
    final firstWord = words[0];

    // Gabungkan kata-kata sisanya
    final remainingWords = words.sublist(1).join(' ');

    return '$firstWord\n$remainingWords';
  }

  // Fungsi untuk menghitung ukuran font berdasarkan rasio layar
  double _calculateFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );

    // Rasio berdasarkan diagonal layar
    final baseSize = diagonal / 100;

    // Batasi ukuran font antara 8.0 dan 15.0
    return baseSize.clamp(8.0, 15.0);
  }

  // Fungsi untuk menentukan apakah perangkat adalah desktop
  bool _isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }


  // Get module border color based on alarm status (any zone alarm or bell trouble)
  Color _getModuleBorderColor(int moduleNumber) {
    // Check if this module has bell trouble (kode 20)
    bool hasBellTrouble = _moduleBellTroubleStatus.containsKey(moduleNumber) &&
                         _moduleBellTroubleStatus[moduleNumber] == true;

    // Check if any zone in this module has alarm
    bool hasZoneAlarm = _checkModuleHasAlarm(moduleNumber);

    // Return red border if either bell trouble or zone alarm exists
    if (hasBellTrouble || hasZoneAlarm) {
      return Colors.red; // Border merah jika ada bell trouble atau alarm zona
    }
    return Colors.grey[300]!; // Border abu-abu default
  }

  // Check if any zone in the module has alarm
  bool _checkModuleHasAlarm(int moduleNumber) {
    if (_currentZoneStatus.isEmpty) {
      return false;
    }

    try {
      // System has 5 zones per module, but monitoring shows 6 zones (5 zones + BELL)
      // We need to check zones 0-4 for this module
      for (int zoneIndex = 0; zoneIndex < 5; zoneIndex++) {
        int globalZoneNumber = (moduleNumber - 1) * 5 + zoneIndex + 1;

        try {
          final zoneStatus = _currentZoneStatus.firstWhere((zone) => zone.zoneNumber == globalZoneNumber);
          if (zoneStatus.hasAlarm) {
            debugPrint('🔥 Module $moduleNumber has alarm in zone $globalZoneNumber');
            return true;
          }
        } catch (e) {
          // Zone not found, continue checking other zones
          continue;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Error checking module $moduleNumber alarm status: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hitung ukuran font dasar berdasarkan layar
    final baseFontSize = _calculateFontSize(context);
    final isDesktop = _isDesktop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // TOP CONTAINER with Back Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(13),
                    spreadRadius: 1,
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isDesktop ? 20 : 15,
                    vertical: isDesktop ? 12 : 10,
                  ),
                  child: Row(
                    children: [
                      // Back Button (seemless)
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          size: baseFontSize * 1.3,
                          color: Colors.black87,
                        ),
                        padding: EdgeInsets.all(isDesktop ? 10 : 8),
                        constraints: BoxConstraints(
                          minWidth: isDesktop ? 45 : 40,
                          minHeight: isDesktop ? 45 : 40,
                        ),
                      ),

                      // Spacer
                      const SizedBox(width: 15),

                      // Title
                      Expanded(
                        child: Text(
                          'MONITORED AREAS',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                            fontSize: baseFontSize * 1.3,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      // Spacer untuk balance dengan back button
                      SizedBox(width: isDesktop ? 55 : 50),
                    ],
                  ),
                ),
              ),
            ),

            // Unified Status Bar - Synchronized across all pages
            FullStatusBar(scaffoldKey: widget.scaffoldKey),

            // Spacing after status bar
            SizedBox(height: isDesktop ? 5 : 10),

            // Container untuk Zona dengan Scroll Terpisah
            Builder(
              builder: (context) {
                final fireAlarmData = context.watch<FireAlarmData>();
                final numModules = fireAlarmData.numberOfModules;
                final screenHeight = MediaQuery.of(context).size.height;
                final isDesktop = _isDesktop(context);

                // Calculate dynamic height based on number of modules
                const double moduleHeight = 140.0; // Estimated height per module including margins/padding
                final totalModuleHeight = numModules * moduleHeight;
                final maxHeight = screenHeight * 0.65; // 65% of screen height max
                final containerHeight = math.min(totalModuleHeight + 40, maxHeight); // + padding

                return Container(
                  height: containerHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border.all(color: Colors.grey[400]!, width: 1.5),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(13),
                        spreadRadius: 1,
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Area scrollable untuk modul
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            children: fireAlarmData.modules.map((module) {
                              final moduleNumber = int.tryParse(module['number'].toString()) ?? 1;
                              final moduleBorderColor = _getModuleBorderColor(moduleNumber);
                              final hasAlarmCondition = moduleBorderColor == Colors.red;

                              return Container(
                                margin: EdgeInsets.fromLTRB(
                                  4,
                                  isDesktop ? 4 : 4,
                                  4,
                                  isDesktop ? 8 : 12,
                                ),
                                padding: EdgeInsets.all(isDesktop ? 8 : 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                    color: moduleBorderColor,
                                    width: hasAlarmCondition ? 3.0 : 1.0, // Thick red border when alarm is active
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withAlpha(8),
                                      spreadRadius: 1,
                                      blurRadius: 2,
                                      offset: const Offset(0, 1),
                                    ),
                                    // Add red shadow when there's alarm condition (bell trouble or zone alarm)
                                    if (hasAlarmCondition)
                                      BoxShadow(
                                        color: Colors.red.withAlpha(77),
                                        spreadRadius: 2,
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    // Header Modul dengan garis dan nomor
                                    Container(
                                      width: double.infinity,
                                      padding: EdgeInsets.only(
                                        bottom: isDesktop ? 6 : 10,
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                            ),
                                            child: Text(
                                              '#${module['number']}',
                                              style: TextStyle(
                                                fontSize: baseFontSize * 1.4,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Container(
                                              height: 1,
                                              color: Colors.grey[400],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Grid 2x3 untuk zona
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 3,
                                            crossAxisSpacing: isDesktop
                                                ? 6.0
                                                : 8.0,
                                            mainAxisSpacing: isDesktop
                                                ? 6.0
                                                : 8.0,
                                            childAspectRatio: isDesktop
                                                ? 5.0
                                                : 2.4,
                                          ),
                                      itemCount: 6, // 6 zona per modul
                                      itemBuilder: (context, zoneIndex) {
                                        final zoneName =
                                            module['zones'][zoneIndex];
                                        final isBellZone = zoneName == 'BELL';

                                        // Calculate global zone number for system data
                                        // Note: System uses 5 zones per module, but monitoring shows 6 zones per module
                                        // Zone 6 in each module is BELL, so we map zones 0-4 to system zones
                                        final moduleNumber = int.tryParse(module['number'].toString()) ?? 1;
                                        int globalZoneNumber;
                                        if (zoneIndex < 5) {
                                          // Map zones 0-4 to system zones (5 zones per module)
                                          globalZoneNumber = (moduleNumber - 1) * 5 + zoneIndex + 1;
                                        } else {
                                          // Zone 5 is BELL, use a default zone number
                                          globalZoneNumber = (moduleNumber - 1) * 5 + 1;
                                        }

                                        // Get zone colors from system data
                                        final zoneColor = isBellZone
                                            ? (_moduleBellTroubleStatus.containsKey(moduleNumber) && _moduleBellTroubleStatus[moduleNumber] == true)
                                                ? Colors.red  // Red background when bell trouble is active
                                                : Colors.grey[300]  // Gray background when normal
                                            : _getZoneColorFromSystem(globalZoneNumber);
                                        final borderColor = isBellZone
                                            ? _getModuleBorderColor(moduleNumber)
                                            : _getZoneBorderColor(globalZoneNumber);
                                        final textColor = isBellZone
                                            ? (_moduleBellTroubleStatus.containsKey(moduleNumber) && _moduleBellTroubleStatus[moduleNumber] == true)
                                                ? Colors.white  // White text when red background
                                                : Colors.black87  // Black text when gray background
                                            : _getZoneTextColor(globalZoneNumber);

                                        return LayoutBuilder(
                                          builder: (context, constraints) {
                                            // Format teks untuk zona non-bell
                                            final formattedText = isBellZone
                                                ? zoneName
                                                : _splitTextIntoTwoLines(
                                                    zoneName,
                                                  );

                                            // Tentukan apakah teks memiliki 2 baris
                                            final hasTwoLines = formattedText
                                                .contains('\n');

                                            // Hitung ukuran font berdasarkan baseFontSize dan jumlah baris
                                            double fontSize = baseFontSize;
                                            if (hasTwoLines) {
                                              fontSize = baseFontSize * 0.9;
                                            }

                                            return Container(
                                              padding: EdgeInsets.symmetric(
                                                vertical: isDesktop ? 6 : 8,
                                                horizontal: isDesktop ? 3 : 4,
                                              ),
                                              decoration: BoxDecoration(
                                                color: zoneColor,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                                border: Border.all(
                                                  color: borderColor,
                                                  width: 1.0,
                                                ),
                                                // Add shadow for active zones (alarm/trouble) and bell trouble
                                                boxShadow: (zoneColor != null && (zoneColor == Colors.red || zoneColor == Colors.yellow)) ||
                                                           (isBellZone && _moduleBellTroubleStatus.containsKey(moduleNumber) && _moduleBellTroubleStatus[moduleNumber] == true)
                                                    ? [
                                                        BoxShadow(
                                                          color: isBellZone && _moduleBellTroubleStatus.containsKey(moduleNumber) && _moduleBellTroubleStatus[moduleNumber] == true
                                                                ? Colors.red.withValues(alpha: 0.4)
                                                                : zoneColor?.withValues(alpha: 0.3) ?? Colors.grey.withValues(alpha: 0.3),
                                                          spreadRadius: 1,
                                                          blurRadius: 2,
                                                          offset: const Offset(0, 1),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                              child: Center(
                                                child: isBellZone
                                                    ? Icon(
                                                        Icons.notifications,
                                                        size:
                                                            baseFontSize *
                                                            (isDesktop
                                                                ? 1.8
                                                                : 2.0),
                                                        color: (_moduleBellTroubleStatus.containsKey(moduleNumber) && _moduleBellTroubleStatus[moduleNumber] == true)
                                                            ? Colors.white  // White icon when red background
                                                            : Colors.black87,  // Black icon when gray background
                                                      )
                                                    : Text(
                                                        formattedText,
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: TextStyle(
                                                          fontSize: fontSize,
                                                          color: textColor,
                                                          fontWeight:
                                                              FontWeight.w500,
                                                        ),
                                                        maxLines: 2,
                                                        overflow:
                                                            TextOverflow.ellipsis,
                                                      ),
                                              ),
                                            );
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Tambahan spacing untuk memastikan scroll berfungsi
            const SizedBox(height: 10),

            // Footer info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '© 2025 DDS Fire Alarm System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: baseFontSize * 0.8,
                  color: Colors.grey[600],
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}