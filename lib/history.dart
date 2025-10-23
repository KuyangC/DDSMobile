import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'fire_alarm_data.dart';


class HistoryPage extends StatefulWidget {
  final GlobalKey<ScaffoldState>? scaffoldKey;
  const HistoryPage({super.key, this.scaffoldKey});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Function to calculate font size based on screen diagonal
  double calculateFontSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final diagonal = math.sqrt(
      math.pow(size.width, 2) + math.pow(size.height, 2),
    );
    final baseSize = diagonal / 100;
    return baseSize.clamp(8.0, 15.0);
  }

  // Function to get responsive multiplier
  double getResponsiveMultiplier(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 1.0;
    if (screenWidth <= 600) return 1.3;
    if (screenWidth <= 900) return 1.5;
    return 1.8;
  }



  // Function to get table header font size
  double getTableHeaderFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 12.0;
    if (screenWidth <= 600) return 14.0;
    if (screenWidth <= 900) return 16.0;
    return 18.0;
  }

  // Function to get table data font size
  double getTableDataFontSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 11.0;
    if (screenWidth <= 600) return 13.0;
    if (screenWidth <= 900) return 15.0;
    return 17.0;
  }

  // Function to get table padding
  double getTablePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 8.0;
    if (screenWidth <= 600) return 10.0;
    if (screenWidth <= 900) return 12.0;
    return 14.0;
  }

  // Function to get table column width multiplier
  double getTableColumnMultiplier(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth <= 412) return 1.0;
    if (screenWidth <= 600) return 1.2;
    if (screenWidth <= 900) return 1.4;
    return 1.6;
  }

  @override
  Widget build(BuildContext context) {
    final baseFontSize = calculateFontSize(context);
    final fireAlarmData = context.watch<FireAlarmData>();

    double historyHeight;
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenWidth <= 412) {
      historyHeight = screenHeight * 0.35;
    } else if (screenWidth <= 600) {
      historyHeight = 300.0;
    } else if (screenWidth <= 900) {
      historyHeight = 350.0;
    } else {
      historyHeight = 400.0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: null,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Complete header with hamburger, logo, and connection status
              Consumer<FireAlarmData>(
                builder: (context, fireAlarmData, child) {
                  return FireAlarmData.getCompleteHeader(
                    isConnected: fireAlarmData.isFirebaseConnected,
                    scaffoldKey: widget.scaffoldKey,
                  );
                },
              ),

              // Hospital Name
              Container(
                width: double.infinity,
                padding: const EdgeInsets.only(top: 5, bottom: 15),
                color: Colors.white,
                child: Text(
                  fireAlarmData.projectName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                    fontSize: baseFontSize * 1.8,
                    letterSpacing: 1.5,
                  ),
                ),
              ),

              // System Info
              Container(
                color: Colors.white,
                padding: const EdgeInsets.only(bottom: 5),
                child: Column(
                  children: [
                    Text(
                      fireAlarmData.panelType,
                      style: TextStyle(
                        fontSize: baseFontSize * 1.6,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      (!fireAlarmData.isFirebaseConnected || 
                       fireAlarmData.numberOfModules == 0 || 
                       fireAlarmData.numberOfZones == 0)
                          ? 'XX MODULES • XX ZONES'
                          : '${fireAlarmData.numberOfModules} MODULES • ${fireAlarmData.numberOfZones} ZONES',
                      style: TextStyle(
                        fontSize: baseFontSize * 1.4,
                        color: Colors.black87,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Builder(
                      builder: (context) {
                        final fireAlarmData = context.watch<FireAlarmData>();
                        String statusText;
                        Color statusColor;
                        Color textColor;
                        if (fireAlarmData.isResetting) {
                          statusText = 'SYSTEM RESETTING';
                          statusColor = Colors.white;
                          textColor = Colors.black;
                        } else {
                          statusText = fireAlarmData.currentStatusText;
                          statusColor = fireAlarmData.currentStatusColor;
                          textColor = Colors.white;
                        }
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 15),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withAlpha(38),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              statusText,
                              style: TextStyle(
                                fontSize: baseFontSize * 2.0,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),

              // Status Indicators
              Container(
                padding: const EdgeInsets.fromLTRB(15, 5, 15, 15),
                color: Colors.white,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          buildStatusColumn(
                            'AC POWER',
                            'AC Power',
                            baseFontSize,
                          ),
                          buildStatusColumn(
                            'DC POWER',
                            'DC Power',
                            baseFontSize,
                          ),
                          buildStatusColumn('ALARM', 'Alarm', baseFontSize),
                          buildStatusColumn('TROUBLE', 'Trouble', baseFontSize),
                          buildStatusColumn('DRILL', 'Drill', baseFontSize),
                          buildStatusColumn(
                            'SILENCED',
                            'Silenced',
                            baseFontSize,
                          ),
                          buildStatusColumn(
                            'DISABLED',
                            'Disabled',
                            baseFontSize,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              // History Log Title
              Container(
                width: double.infinity,
                padding: EdgeInsets.only(top: 15, bottom: 8),
                child: Text(
                  'HISTORY LOG',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                    fontSize: baseFontSize * 1.4,
                    letterSpacing: 1,
                  ),
                ),
              ),

              // Tabs
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 15),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.center,
                  tabs: const [
                    Tab(text: 'STATUS'),
                    Tab(text: 'CONNECTION'),
                    Tab(text: 'TROUBLE'),
                    Tab(text: 'FIRE'),
                  ],
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: const Color.fromARGB(255, 18, 148, 42),
                  labelStyle: TextStyle(
                    fontSize: baseFontSize * 1.1,
                    fontWeight: FontWeight.bold,
                  ),
                  unselectedLabelStyle: TextStyle(
                    fontSize: baseFontSize * 1.0,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ),

              // History Log Container
              Container(
                width: MediaQuery.of(context).size.width,
                height: historyHeight,
                margin: const EdgeInsets.fromLTRB(15, 15, 15, 15),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Consumer<FireAlarmData>(
                  builder: (context, fireAlarmData, child) {
                    final logHandler = fireAlarmData.logHandler;

                    if (logHandler.isLoading) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    if (logHandler.errorMessage != null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.red[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading logs',
                              style: TextStyle(
                                fontSize: baseFontSize * 1.2,
                                color: Colors.red[400],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              logHandler.errorMessage!,
                              style: TextStyle(
                                fontSize: baseFontSize * 0.9,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => logHandler.refreshLogs(),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color.fromARGB(255, 18, 148, 42),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: Text(
                                'Retry',
                                style: TextStyle(fontSize: baseFontSize * 1.0),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return TabBarView(
                      controller: _tabController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        buildStatusTable(
                          logHandler.statusLogs,
                          historyHeight - 24,
                        ),
                        buildConnectionTable(
                          logHandler.connectionLogs,
                          historyHeight - 24,
                        ),
                        buildTroubleTable(
                          logHandler.troubleLogs,
                          historyHeight - 24,
                        ),
                        buildFireTable(
                          logHandler.fireLogs,
                          historyHeight - 24,
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Footer
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  '© 2025 DDS Fire Alarm System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: baseFontSize * 1,
                    color: Colors.grey[600],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // Method to build status column
  Widget buildStatusColumn(
    String label,
    String statusKey,
    double baseFontSize,
  ) {
    final fireAlarmData = context.watch<FireAlarmData>();
    final isActive = fireAlarmData.getSystemStatus(statusKey);
    final activeColor = fireAlarmData.getActiveColor(statusKey);
    final inactiveColor = fireAlarmData.getInactiveColor(statusKey);

    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: baseFontSize * 0.9,
            fontWeight: FontWeight.w500,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : inactiveColor,
            border: Border.all(
              color: isActive ? activeColor : inactiveColor,
              width: 1,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: activeColor.withAlpha(102),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }

  // Method to build status table
  Widget buildStatusTable(List<Map<String, dynamic>> logs, double height) {
    final multiplier = getTableColumnMultiplier(context);
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No status logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Status changes will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 310 * multiplier,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'TIME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 150 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final displayStatus = '${log['status']} | ${log['user']}';
                    return Row(
                      children: [
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['date'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            formatTimeWithSeconds(log['time']),
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 150 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            displayStatus,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  // Method to build connection table
  Widget buildConnectionTable(List<Map<String, dynamic>> logs, double height) {
    final multiplier = getTableColumnMultiplier(context);
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.wifi_off,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No connection logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Module connections will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 310 * multiplier,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'TIME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 150 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'INFORMATION',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Row(
                      children: [
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['date'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            formatTimeWithSeconds(log['time']),
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 150 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['information'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  // Method to build trouble table
  Widget buildTroubleTable(List<Map<String, dynamic>> logs, double height) {
    final multiplier = getTableColumnMultiplier(context);
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.warning_amber_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No trouble logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Trouble events will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 440 * multiplier,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'DATE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'TIME',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 80 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'ADDRESS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  Container(
                    width: 100 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'ZONE',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    width: 100 * multiplier,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'STATUS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Row(
                      children: [
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['date'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            formatTimeWithSeconds(log['time']),
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 80 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['address'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 100 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['zoneName'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 100 * multiplier,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['status'],
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
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

  // Method to build fire table
  Widget buildFireTable(List<Map<String, dynamic>> logs, double height) {
    final multiplier = getTableColumnMultiplier(context);
    final headerFontSize = getTableHeaderFontSize(context);
    final dataFontSize = getTableDataFontSize(context);
    final padding = getTablePadding(context);

    double dateWidth = 80 * multiplier;
    double timeWidth = 80 * multiplier;
    double addressWidth = 80 * multiplier;
    double zoneNameWidth = 100 * multiplier;
    double statusWidth = 100 * multiplier;

    if (logs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No fire logs available',
              style: TextStyle(
                fontSize: dataFontSize,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fire alarm events will appear here',
              style: TextStyle(
                fontSize: dataFontSize * 0.9,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width:
              dateWidth +
              timeWidth +
              addressWidth +
              zoneNameWidth +
              statusWidth,
          child: Column(
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: dateWidth,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'DATE',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: timeWidth,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'TIME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: addressWidth,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'ADDRESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: zoneNameWidth,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'ZONE NAME',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Container(
                    width: statusWidth,
                    padding: EdgeInsets.all(padding),
                    child: Text(
                      'STATUS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: headerFontSize,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // Rows
              Expanded(
                child: ListView.builder(
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Row(
                      children: [
                        Container(
                          width: dateWidth,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['date'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          width: timeWidth,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            formatTimeWithSeconds(log['time']),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          width: addressWidth,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['address'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          width: zoneNameWidth,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['zoneName'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          width: statusWidth,
                          padding: EdgeInsets.all(padding),
                          child: Text(
                            log['status'],
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: dataFontSize,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
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

  String formatTimeWithSeconds(String time) {
    // Assuming time is in HH:mm format, add ":00" seconds
    if (time.length == 5 && time[2] == ':') {
      return '$time:00';
    }
    return time;
  }
}
