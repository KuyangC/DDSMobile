import 'dart:async';
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart'; // Temporarily removed due to compilation issues
import 'package:shared_preferences/shared_preferences.dart';

class LocalAudioManager {
  static final LocalAudioManager _instance = LocalAudioManager._internal();
  factory LocalAudioManager() => _instance;
  LocalAudioManager._internal();

  // final AudioPlayer _audioPlayer = AudioPlayer(); // Temporarily removed due to compilation issues
  Timer? _troubleTimer;
  bool _isInitialized = false;
  
  // Local mute states yang disimpan per device
  bool _isNotificationMuted = false;
  bool _isSoundMuted = false;
  bool _isBellMuted = false;
  
  // Audio status tracking untuk sync dengan button
  bool _isDrillActive = false;
  bool _isAlarmActive = false;
  bool _isTroubleActive = false;
  bool _isSilencedActive = false;
  
  // Stream controllers untuk real-time updates
  final _audioStatusController = StreamController<Map<String, bool>>.broadcast();
  Stream<Map<String, bool>> get audioStatusStream => _audioStatusController.stream;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await _loadLocalSettings();
      _isInitialized = true;
      debugPrint('LocalAudioManager initialized');
    } catch (e) {
      debugPrint('Error initializing LocalAudioManager: $e');
    }
  }

  // Load local mute settings dari SharedPreferences
  Future<void> _loadLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isNotificationMuted = prefs.getBool('notification_muted') ?? false;
      _isSoundMuted = prefs.getBool('sound_muted') ?? false;
      _isBellMuted = prefs.getBool('bell_muted') ?? false;
      
      debugPrint('Loaded local settings: notification=$_isNotificationMuted, sound=$_isSoundMuted, bell=$_isBellMuted');
    } catch (e) {
      debugPrint('Error loading local settings: $e');
    }
  }

  // Save local mute settings ke SharedPreferences
  Future<void> _saveLocalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notification_muted', _isNotificationMuted);
      await prefs.setBool('sound_muted', _isSoundMuted);
      await prefs.setBool('bell_muted', _isBellMuted);
      
      debugPrint('Saved local settings: notification=$_isNotificationMuted, sound=$_isSoundMuted, bell=$_isBellMuted');
    } catch (e) {
      debugPrint('Error saving local settings: $e');
    }
  }

  // Update audio status based on button status from Firebase
  void updateAudioStatusFromButtons({
    required bool isDrillActive,
    required bool isAlarmActive,
    required bool isTroubleActive,
    required bool isSilencedActive,
  }) {
    debugPrint('=== AUDIO STATUS UPDATE ===');
    debugPrint('Drill: $isDrillActive -> $_isDrillActive');
    debugPrint('Alarm: $isAlarmActive -> $_isAlarmActive');
    debugPrint('Trouble: $isTroubleActive -> $_isTroubleActive');
    debugPrint('Silenced: $isSilencedActive -> $_isSilencedActive');
    debugPrint('Sound Muted: $_isSoundMuted');
    
    // Handle Drill
    if (isDrillActive != _isDrillActive) {
      _isDrillActive = isDrillActive;
      if (isDrillActive && !_isSoundMuted) {
        _playDrillSound();
      } else {
        _stopDrillSound();
      }
    }
    
    // Handle Alarm
    if (isAlarmActive != _isAlarmActive) {
      _isAlarmActive = isAlarmActive;
      if (isAlarmActive && !_isSilencedActive && !_isSoundMuted) {
        _playAlarmSound();
      } else {
        _stopAlarmSound();
      }
    }
    
    // Handle Trouble
    if (isTroubleActive != _isTroubleActive) {
      _isTroubleActive = isTroubleActive;
      if (isTroubleActive && !_isSoundMuted) {
        _startTroubleBeep();
      } else {
        _stopTroubleBeep();
      }
    }
    
    // Handle Silence (affects alarm sound)
    if (isSilencedActive != _isSilencedActive) {
      _isSilencedActive = isSilencedActive;
      if (isSilencedActive && _isAlarmActive) {
        _stopAlarmSound();
      } else if (!isSilencedActive && _isAlarmActive && !_isSoundMuted) {
        _playAlarmSound();
      }
    }
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  // Audio control methods (temporarily disabled due to audioplayers compilation issues)
  void _playDrillSound() async {
    try {
      debugPrint('AUDIO: DRILL SOUND WOULD PLAY (audio player disabled)');
      // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // await _audioPlayer.play(AssetSource('sounds/alarm_clock.ogg'));
    } catch (e) {
      debugPrint('Error playing drill sound: $e');
    }
  }

  void _stopDrillSound() async {
    try {
      debugPrint('AUDIO: DRILL SOUND WOULD STOP (audio player disabled)');
      // await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping drill sound: $e');
    }
  }

  void _playAlarmSound() async {
    try {
      debugPrint('AUDIO: ALARM SOUND WOULD PLAY (audio player disabled)');
      // await _audioPlayer.setReleaseMode(ReleaseMode.loop);
      // await _audioPlayer.play(AssetSource('sounds/alarm_clock.ogg'));
    } catch (e) {
      debugPrint('Error playing alarm sound: $e');
    }
  }

  void _stopAlarmSound() async {
    try {
      debugPrint('AUDIO: ALARM SOUND WOULD STOP (audio player disabled)');
      // await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping alarm sound: $e');
    }
  }

  void _startTroubleBeep() async {
    try {
      debugPrint('AUDIO: TROUBLE BEEP WOULD START (audio player disabled)');
      _troubleTimer?.cancel();
      _troubleTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
        debugPrint('AUDIO: TROUBLE BEEP (audio player disabled)');
        // _audioPlayer.play(AssetSource('sounds/beep_short.ogg'));
      });
    } catch (e) {
      debugPrint('Error starting trouble beep: $e');
    }
  }

  void _stopTroubleBeep() async {
    try {
      debugPrint('AUDIO: TROUBLE BEEP WOULD STOP (audio player disabled)');
      _troubleTimer?.cancel();
      _troubleTimer = null;
      // await _audioPlayer.stop();
    } catch (e) {
      debugPrint('Error stopping trouble beep: $e');
    }
  }

  // Local mute controls
  Future<void> toggleNotificationMute() async {
    _isNotificationMuted = !_isNotificationMuted;
    await _saveLocalSettings();
    
    debugPrint('Notification ${_isNotificationMuted ? 'MUTED' : 'UNMUTED'} (Local)');
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  Future<void> toggleSoundMute() async {
    _isSoundMuted = !_isSoundMuted;
    await _saveLocalSettings();
    
    debugPrint('Sound ${_isSoundMuted ? 'MUTED' : 'UNMUTED'} (Local)');
    
    // Stop all sounds if muted
    if (_isSoundMuted) {
      _stopAllSounds();
    } else {
      // Restart sounds based on current button status
      if (_isDrillActive) _playDrillSound();
      if (_isAlarmActive && !_isSilencedActive) _playAlarmSound();
      if (_isTroubleActive) _startTroubleBeep();
    }
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  Future<void> toggleBellMute() async {
    _isBellMuted = !_isBellMuted;
    await _saveLocalSettings();
    
    debugPrint('Bell ${_isBellMuted ? 'MUTED' : 'UNMUTED'} (Local - Coming Soon)');
    
    // Broadcast status update
    _audioStatusController.add({
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    });
  }

  void _stopAllSounds() {
    debugPrint('STOPPING ALL SOUNDS');
    _stopDrillSound();
    _stopAlarmSound();
    _stopTroubleBeep();
    
    // Reset all audio states
    _isDrillActive = false;
    _isAlarmActive = false;
    _isTroubleActive = false;
    _isSilencedActive = false;
    
    debugPrint('All audio states reset to default');
  }

  // Public method to stop all sounds immediately (used by system reset)
  void stopAllAudioImmediately() {
    debugPrint('EMERGENCY STOP ALL AUDIO');
    _stopAllSounds();
  }

  // Play specific sound effects (temporarily disabled due to audioplayers compilation issues)
  Future<void> playSystemResetSound() async {
    try {
      debugPrint('AUDIO: SYSTEM RESET SOUND WOULD PLAY (audio player disabled)');
      // await _audioPlayer.setReleaseMode(ReleaseMode.release);
      // await _audioPlayer.play(AssetSource('sounds/system reset.mp3'));
    } catch (e) {
      debugPrint('Error playing system reset sound: $e');
    }
  }

  Future<void> playSystemNormalSound() async {
    try {
      debugPrint('AUDIO: SYSTEM NORMAL SOUND WOULD PLAY (audio player disabled)');
      // await _audioPlayer.setReleaseMode(ReleaseMode.release);
      // await _audioPlayer.play(AssetSource('sounds/system normal.mp3'));
    } catch (e) {
      debugPrint('Error playing system normal sound: $e');
    }
  }

  // Getters untuk current status
  bool get isNotificationMuted => _isNotificationMuted;
  bool get isSoundMuted => _isSoundMuted;
  bool get isBellMuted => _isBellMuted;
  bool get isDrillActive => _isDrillActive;
  bool get isAlarmActive => _isAlarmActive;
  bool get isTroubleActive => _isTroubleActive;
  bool get isSilencedActive => _isSilencedActive;

  // Get current audio status map
  Map<String, bool> getCurrentAudioStatus() {
    return {
      'drill': _isDrillActive,
      'alarm': _isAlarmActive,
      'trouble': _isTroubleActive,
      'silenced': _isSilencedActive,
      'soundMuted': _isSoundMuted,
      'notificationMuted': _isNotificationMuted,
      'bellMuted': _isBellMuted,
    };
  }

  void dispose() {
    _troubleTimer?.cancel();
    // _audioPlayer.dispose(); // Temporarily removed due to compilation issues
    _audioStatusController.close();
  }
}
