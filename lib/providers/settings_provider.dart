import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/fcm_service.dart';
import '../services/auth_service.dart';

class SettingsProvider with ChangeNotifier {
  bool _notificationsEnabled = true;
  bool _eventRemindersEnabled = true;
  bool _paymentRemindersEnabled = true;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get eventRemindersEnabled => _eventRemindersEnabled;
  bool get paymentRemindersEnabled => _paymentRemindersEnabled;

  SettingsProvider() {
    _loadFromPrefs();
  }

  void toggleNotifications(bool isOn) {
    _notificationsEnabled = isOn;
    _saveToPrefs('notificationsEnabled', isOn);
    
    if (isOn) {
      FcmService.updateToken();
    } else {
      FcmService.clearTokenOnServer();
    }
    
    notifyListeners();
  }

  void toggleEventReminders(bool isOn) {
    _eventRemindersEnabled = isOn;
    _saveToPrefs('eventRemindersEnabled', isOn);
    _syncPreferencesWithServer();
    notifyListeners();
  }

  void togglePaymentReminders(bool isOn) {
    _paymentRemindersEnabled = isOn;
    _saveToPrefs('paymentRemindersEnabled', isOn);
    _syncPreferencesWithServer();
    notifyListeners();
  }

  Future<void> _syncPreferencesWithServer() async {
    final AuthService authService = AuthService();
    final result = await authService.updateNotificationPreferences(
      eventNotifications: _eventRemindersEnabled,
      paymentNotifications: _paymentRemindersEnabled,
    );

    if (result['success'] == true) {
      debugPrint('FCM: Notification preferences successfully synced with Laravel');
    } else {
      debugPrint('FCM: Failed to sync preferences: ${result['message']}');
    }
  }

  Future<void> _loadFromPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    _eventRemindersEnabled = prefs.getBool('eventRemindersEnabled') ?? true;
    _paymentRemindersEnabled = prefs.getBool('paymentRemindersEnabled') ?? true;
    notifyListeners();
  }

  Future<void> _saveToPrefs(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }
}
