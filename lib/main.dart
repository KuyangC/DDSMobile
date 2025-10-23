import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'home.dart';
import 'monitoring.dart';
import 'control.dart';
import 'history.dart';
import 'fire_alarm_data.dart';
import 'config.dart';
import 'auth_navigation.dart';
import 'full_monitoring_page.dart';
import 'zone_monitoring.dart';
import 'services/auth_service.dart';
import 'services/fcm_service.dart';
import 'services/background_notification_service.dart' as bg_notification;
import 'services/local_audio_manager.dart';
import 'profile_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize dotenv first
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('⚠️ Could not load .env file: $e');
  }

  // Initialize Firebase with custom configuration
  try {
    // Try to initialize with a custom name to avoid conflicts
    await Firebase.initializeApp(
      name: 'fireAlarmApp',
      options: FirebaseOptions(
        apiKey: 'rcy10oVwCVIhWRdTVk8ZBT7bLAUHZE7fPHKKOKpK',
        authDomain: 'testing1do.firebaseapp.com',
        databaseURL: 'https://testing1do-default-rtdb.asia-southeast1.firebasedatabase.app',
        projectId: 'testing1do',
        storageBucket: 'testing1do.appspot.com',
        messagingSenderId: '123456789',
        appId: '1:123456789:android:abcdef123456',
      ),
    );
    debugPrint('✅ Firebase initialized successfully with custom name');
    debugPrint('Database URL: https://testing1do-default-rtdb.asia-southeast1.firebasedatabase.app');
  } catch (e) {
    debugPrint('⚠️ Firebase initialization with custom name failed: $e');
    // Try to use the default app if it exists
    try {
      final app = Firebase.app();
      debugPrint('✅ Using existing Firebase app: ${app.name}');
      final dbURL = FirebaseDatabase.instanceFor(app: app).databaseURL;
      debugPrint('Database URL: $dbURL');
    } catch (e2) {
      debugPrint('❌ No Firebase app available: $e2');
      debugPrint('App will continue without Firebase functionality');
    }
  }

  // Initialize FCM with error handling
  try {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');

    // Get FCM token
    String? token = await messaging.getToken();
    debugPrint('FCM Token: $token');

    // Subscribe to topics for notifications
    await messaging.subscribeToTopic('status_updates');
    debugPrint('Subscribed to status_updates topic');
    
    // Subscribe to fire alarm events topic
    await FCMService.subscribeToFireAlarmEvents(token);
    debugPrint('Subscribed to fire_alarm_events topic');
  } catch (e) {
    debugPrint('FCM initialization failed: $e');
  }

  // Handle background messages
  FirebaseMessaging.onBackgroundMessage(bg_notification.BackgroundNotificationService.firebaseMessagingBackgroundHandler);

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    // Show notification with sound even when app is in foreground
    final data = message.data;
    final eventType = data['eventType'] ?? 'UNKNOWN';
    final status = data['status'] ?? '';
    final user = data['user'] ?? 'System';
    
    bg_notification.BackgroundNotificationService().showFireAlarmNotification(
      title: 'Fire Alarm: $eventType',
      body: 'Status: $status - By: $user',
      eventType: eventType,
      data: data,
    );

    if (message.notification != null) {
      debugPrint('Message also contained a notification: ${message.notification}');
    }
  });

  // Initialize background notification service for persistent operation
  await bg_notification.BackgroundNotificationService().initialize();

  // Initialize LocalAudioManager for background audio
  final audioManager = LocalAudioManager();
  await audioManager.initialize();

  debugPrint('Background services initialized successfully');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => FireAlarmData(),
      child: MaterialApp(
        title: 'Fire Alarm Monitoring',
        theme: ThemeData(primarySwatch: Colors.blue),
        debugShowCheckedModeBanner: false,
        home: const AuthNavigation(),
      ),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  String _username = '';
  String _phone = '';
  String? _photoUrl;
  bool _hasShownDisconnectedMessage = false;

  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Initialize pages with scaffold key
    _pages = [
      HomePage(scaffoldKey: _scaffoldKey),
      MonitoringPage(scaffoldKey: _scaffoldKey),
      ControlPage(scaffoldKey: _scaffoldKey),
      HistoryPage(scaffoldKey: _scaffoldKey),
      const ConfigPage(),
    ];
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final data = Provider.of<FireAlarmData>(context, listen: false);
      if (data.isFirebaseConnected) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Connected to Firebase server')),
        );
      }
    });

    // Listen for connectivity changes to show disconnection message
    final data = Provider.of<FireAlarmData>(context, listen: false);
    data.addListener(() {
      if (!data.isFirebaseConnected && !_hasShownDisconnectedMessage) {
        _hasShownDisconnectedMessage = true;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Check your internet connection..')),
          );
        }
      } else if (data.isFirebaseConnected) {
        _hasShownDisconnectedMessage = false;
      }
    });
  }

  Future<void> _loadUserData() async {
    final username = await _authService.getCurrentUsername();
    final phone = await _authService.getCurrentPhone();
    final photoUrl = await _authService.getCurrentUserPhotoUrl();
    if (mounted) {
      setState(() {
        _username = username ?? 'User';
        _phone = phone ?? '';
        _photoUrl = photoUrl;
      });
    }
  }

  Future<void> _handleLogout() async {
    // Tampilkan dialog konfirmasi
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      // Sign out from Firebase and clear session
      await _authService.signOut();
      
      // Navigate to login page
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthNavigation()),
          (route) => false,
        );
      }
    }
  }

Future<void> _navigateToProfile() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfilePage()),
    );

    if (result == true) {
      _loadUserData();
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() {
            _currentIndex = 0;
          });
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: Drawer(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    DrawerHeader(
                      decoration: const BoxDecoration(
                        color: Color.fromARGB(255, 27, 134, 47),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.white,
                            backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                            child: _photoUrl == null 
                                ? const Icon(
                                    Icons.person,
                                    size: 35,
                                    color: Color.fromARGB(255, 35, 141, 39),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _phone.isNotEmpty ? '$_username | $_phone' : _username,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Monitoring Control',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const Text(
                            'Fire Alarm System User',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.person),
                      title: const Text('My Profile'),
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToProfile();
                      },
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.question_answer),
                      title: const Text('WA Message Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Whats App Settings');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.domain_add),
                      title: const Text('Zone Name Settings'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullMonitoringPage(),
                          ),
                        );
                      },
                    ),
                      ListTile(
                      leading: const Icon(Icons.fullscreen),
                      title: const Text('Full Monitoring'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const FullMonitoringPage(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.grid_on),
                      title: const Text('Zone Monitoring'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ZoneMonitoringPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const Divider(),
              const SizedBox(height: 0.5),
              SafeArea(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Logout',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _handleLogout();
                  },
                ),
              ),
            ],
          ),
        ),
        body: IndexedStack(index: _currentIndex, children: _pages),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withAlpha(51),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            backgroundColor: Colors.white,
            selectedItemColor: const Color.fromARGB(255, 0, 180, 81),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.monitor_outlined),
                activeIcon: Icon(Icons.monitor),
                label: 'Monitoring',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings_outlined),
                activeIcon: Icon(Icons.settings),
                label: 'Control',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history_outlined),
                activeIcon: Icon(Icons.history),
                label: 'History',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
