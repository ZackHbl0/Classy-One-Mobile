import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    notifyListeners();
  }

  void toggleEventReminders(bool isOn) {
    _eventRemindersEnabled = isOn;
    _saveToPrefs('eventRemindersEnabled', isOn);
    notifyListeners();
  }

  void togglePaymentReminders(bool isOn) {
    _paymentRemindersEnabled = isOn;
    _saveToPrefs('paymentRemindersEnabled', isOn);
    notifyListeners();
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
