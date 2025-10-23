import 'dart:async';
import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'login.dart';
import 'register.dart';
import 'config.dart';
import 'interface_settings.dart';
import 'main.dart';
import 'services/auth_service.dart';

class AuthNavigation extends StatefulWidget {
  const AuthNavigation({super.key});

  @override
  State<AuthNavigation> createState() => _AuthNavigationState();
}

class _AuthNavigationState extends State<AuthNavigation> {
  bool showLogin = true;
  bool loggedIn = false;
  bool configDone = false;
  bool settingsDone = false;
  bool cameFromRegister = false;
  bool isCheckingSession = true;  // Loading state untuk cek session
  bool hasError = false;
  String? errorMessage;
  
  Timer? _connectivityTimer;
  StreamSubscription? _connectivitySubscription;
  
  final AuthService _authService = AuthService();
  
  @override
  void initState() {
    super.initState();
    _checkExistingSession();
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
  
  // Cek apakah ada session yang tersimpan
  Future<void> _checkExistingSession() async {
    final startTime = DateTime.now();

    // Reset error state
    if (mounted) {
      setState(() {
        hasError = false;
        errorMessage = null;
        isCheckingSession = true;
      });
    }

    // Check initial connectivity
    var connectivityResults = await Connectivity().checkConnectivity();
    bool hasInternet = !connectivityResults.contains(ConnectivityResult.none);

    if (hasInternet) {
      _performSessionCheck(startTime);
    } else {
      // No internet, set up listener and timer
      _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
        if (!result.contains(ConnectivityResult.none) && mounted) {
          // Internet available, cancel timer and proceed
          _connectivityTimer?.cancel();
          _performSessionCheck(startTime);
        }
      });

      // Start 20 second timer for connection timeout
      _connectivityTimer = Timer(const Duration(seconds: 20), () {
        if (mounted) {
          setState(() {
            hasError = true;
            errorMessage = 'Check your internet connection..';
            isCheckingSession = false;
          });
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Check your internet connection..')),
              );
            }
          });
        }
      });
    }
  }

  Future<void> _performSessionCheck(DateTime startTime) async {
    // Cancel connectivity listener and timer when proceeding
    _connectivitySubscription?.cancel();
    _connectivityTimer?.cancel();

    try {
      final sessionData = await _authService.checkExistingSession().timeout(const Duration(seconds: 20));

      // Pastikan minimal loading 3 detik
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 3)) {
        await Future.delayed(const Duration(seconds: 3) - elapsed);
      }

      if (sessionData != null && mounted) {
        // Session valid, auto login
        setState(() {
          loggedIn = true;
          // If a session exists, the user should be considered fully set up.
          configDone = true;
          settingsDone = true;
          isCheckingSession = false;
          hasError = false;
        });

        // Tampilkan pesan selamat datang
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Welcome back, ${sessionData['username']}!'),
                  backgroundColor: Colors.green,
                  duration: const Duration(seconds: 2),
                ),
              );
            }
          });
        }
      } else {
        // Tidak ada session atau session tidak valid
        setState(() {
          isCheckingSession = false;
          hasError = false;
        });
      }
    } on TimeoutException {
      // Pastikan minimal loading 3 detik
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 3)) {
        await Future.delayed(const Duration(seconds: 3) - elapsed);
      }

      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'Check your internet connection..';
          isCheckingSession = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Check your internet connection..')),
            );
          }
        });
      }
    } catch (e) {
      // Pastikan minimal loading 3 detik
      final elapsed = DateTime.now().difference(startTime);
      if (elapsed < const Duration(seconds: 3)) {
        await Future.delayed(const Duration(seconds: 3) - elapsed);
      }

      if (mounted) {
        setState(() {
          hasError = true;
          errorMessage = 'An error occurred. Please try again.';
          isCheckingSession = false;
        });
      }
    }
  }

  void toggleView() {
    setState(() {
      showLogin = !showLogin;
    });
  }

  void onLoginSuccess() {
    setState(() {
      loggedIn = true;
      cameFromRegister = false;
      configDone = false;
      settingsDone = false;
    });
  }

  void onRegisterSuccess() {
    setState(() {
      // After successful registration, redirect to login page
      showLogin = true;
      loggedIn = false;
      cameFromRegister = true;
    });
  }

  void onConfigDone() {
    setState(() {
      configDone = true;
      settingsDone = true; // Skip interface settings after config save
    });
  }

  void onSettingsDone() {
    setState(() {
      settingsDone = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Tampilkan loading screen saat mengecek session
    if (isCheckingSession) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/data/images/LOGO TEXT.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              const CircularProgressIndicator(
                color: Color.fromARGB(255, 35, 141, 39),
              ),
              const SizedBox(height: 20),
              const Text(
                'Loading...',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Error screen with retry
    if (hasError && errorMessage != null && !loggedIn) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/data/images/LOGO TEXT.png',
                height: 120,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 30),
              Icon(
                Icons.wifi_off,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  errorMessage!,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color.fromARGB(255, 115, 115, 115),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () {
                  _checkExistingSession();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 35, 141, 39),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    if (!loggedIn) {
      if (showLogin) {
        return LoginPage(
          onRegisterClicked: toggleView,
          onLoginSuccess: onLoginSuccess,
        );
      } else {
        return RegisterPage(
          onLoginClicked: toggleView,
          onRegisterSuccess: onRegisterSuccess,
        );
      }
    } else {
      if (!configDone) {
        return ConfigPage(
          key: UniqueKey(),
          onConfigDone: onConfigDone,
          onBackPressed: () {
            setState(() {
              loggedIn = false;
              showLogin = true;
              configDone = false;
              settingsDone = false;
            });
          },
        );
      } else if (!settingsDone) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) {
              setState(() {
                configDone = false;
                settingsDone = false;
              });
            }
          },
          child: InterfaceSettingsPage(
            key: UniqueKey(),
            onSettingsDone: onSettingsDone,
            onBackPressed: () {
              setState(() {
                configDone = false;
                settingsDone = false;
              });
            },
          ),
        );
      } else {
        return const MainNavigation();
      }
    }
  }
}
