import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static const String _userIdKey = 'user_id';
  static const String _emailKey = 'user_email';
  static const String _usernameKey = 'username';
  static const String _phoneKey = 'phone';
  static const String _configDoneKey = 'config_done';
  static const String _settingsDoneKey = 'settings_done';

  final DatabaseReference _databaseRef = FirebaseDatabase.instanceFor(app: Firebase.app('fireAlarmApp')).ref();
  
  // Simpan session login ke local storage
  Future<void> saveLoginSession({
    required String userId,
    required String email,
    required String username,
    required String phone,
    bool configDone = false,
    bool settingsDone = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userIdKey, userId);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_phoneKey, phone);
    await prefs.setBool(_configDoneKey, configDone);
    await prefs.setBool(_settingsDoneKey, settingsDone);
  }
  
  // Update status config dan settings
  Future<void> updateConfigStatus({
    bool? configDone,
    bool? settingsDone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (configDone != null) {
      await prefs.setBool(_configDoneKey, configDone);
    }
    if (settingsDone != null) {
      await prefs.setBool(_settingsDoneKey, settingsDone);
    }
  }
  
  // Cek apakah user sudah login sebelumnya
  Future<Map<String, dynamic>?> checkExistingSession() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return null;
    }

    // Validasi dengan Firebase Database - cek apakah user masih ada dan aktif
    try {
      final userSnapshot = await _databaseRef.child('users/${user.uid}').get();

      if (!userSnapshot.exists) {
        // User tidak ditemukan di Firebase, sign out
        await FirebaseAuth.instance.signOut();
        return null;
      }

      final userData = userSnapshot.value as Map<dynamic, dynamic>;

      // Cek apakah akun masih aktif
      if (userData['isActive'] != true) {
        // Akun tidak aktif, sign out
        await FirebaseAuth.instance.signOut();
        return null;
      }

      // Update last login time di Firebase
      await _databaseRef.child('users/${user.uid}/lastLogin')
          .set(DateTime.now().toIso8601String());

      // Save to prefs
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userIdKey, user.uid);
      await prefs.setString(_emailKey, user.email ?? '');
      await prefs.setString(_usernameKey, userData['username'] ?? '');
      await prefs.setString(_phoneKey, userData['phone'] ?? '');
      await prefs.setBool(_configDoneKey, userData['configDone'] ?? false);
      await prefs.setBool(_settingsDoneKey, userData['settingsDone'] ?? false);

      // Return session data
      return {
        'userId': user.uid,
        'email': user.email ?? '',
        'username': userData['username'] ?? '',
        'phone': userData['phone'] ?? '',
        'configDone': userData['configDone'] ?? false,
        'settingsDone': userData['settingsDone'] ?? false,
        'userData': userData,
      };
    } catch (e) {
      // Jika ada error, sign out
      await FirebaseAuth.instance.signOut();
      return null;
    }
  }
  
  // Hapus session (untuk logout)
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_phoneKey);
    await prefs.remove(_configDoneKey);
    await prefs.remove(_settingsDoneKey);
  }
  
  // Get current user ID
  Future<String?> getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }
  
  // Get current username
  Future<String?> getCurrentUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_usernameKey);
  }

  // Get current phone
  Future<String?> getCurrentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneKey);
  }

  // Get current user photo URL from Firebase Auth
  Future<String?> getCurrentUserPhotoUrl() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;
      
      // First try to get from Firebase Auth
      if (user.photoURL != null) {
        return user.photoURL;
      }
      
      // If not in Auth, try to get from Realtime Database
      final userSnapshot = await _databaseRef.child('users/${user.uid}').get();
      if (userSnapshot.exists) {
        final userData = userSnapshot.value as Map<dynamic, dynamic>;
        return userData['photoUrl'];
      }
      return null;
    } catch (e) {
      debugPrint('Error getting photo URL: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String username,
    required String phone,
    String? photoUrl,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update Firebase Auth
    await user.updateDisplayName(username);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Update Firebase Realtime Database
    await _databaseRef.child('users/${user.uid}').update({
      'username': username,
      'phone': phone,
      'photoUrl': photoUrl,
    });

    // Update local storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, username);
    await prefs.setString(_phoneKey, phone);
  }

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
  }

  // Create user with email and password
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
  }

  // Sign out
  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await clearSession();
  }

  // Save user data to database after registration (SECURE - no password storage)
  Future<void> saveUserDataToDatabase({
    required String uid,
    required String email,
    required String username,
    required String phone,
  }) async {
    await _databaseRef.child('users/$uid').set({
      'email': email,
      'username': username,
      'phone': phone,
      // Password NOT stored - handled securely by Firebase Auth
      'isActive': true,
      'createdAt': DateTime.now().toIso8601String(),
      'configDone': false,
      'settingsDone': false,
      'fcmToken': '', // Will be updated after login/registration
    });
  }

  // Update FCM token for current user
  Future<void> updateFCMToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      String? token = await FirebaseMessaging.instance.getToken();
      if (token != null) {
        await _databaseRef.child('users/${user.uid}/fcmToken').set(token);
        debugPrint('FCM token updated for user ${user.uid}: $token');
      }
    } catch (e) {
      debugPrint('Failed to update FCM token: $e');
    }
  }

  // DEPRECATED: Migration function removed for security reasons
  // This function previously handled plain text passwords which is insecure
  // All users should now register through the secure Firebase Auth flow
  // Future<void> migrateUsers() async {
  //   // Function removed - see documentation for secure user migration
  // }
}
