import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'auth_service.dart';

class FcmService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final AuthService _authService = AuthService();

  static Future<void> initialize() async {
    // Request permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('FCM: User granted permission');
      await updateToken();
    } else {
      debugPrint('FCM: User declined or has not accepted permission');
    }

    // Handle token refresh
    _messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM Token Refreshed: $newToken');
      _sendTokenToBackend(newToken);
    });
  }

  static Future<void> updateToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        debugPrint('FCM Token: $token');
        await _sendTokenToBackend(token);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  static Future<void> clearTokenOnServer() async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;
    if (idStudent != 0) {
      debugPrint('FCM: Clearing token on server...');
      await _authService.updateFcmToken('');
      debugPrint('FCM: Token cleared on server');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;
    
    // Also check if notifications are enabled in settings
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    
    if (idStudent != 0 && notificationsEnabled) {
      debugPrint('FCM: Syncing token with Laravel...');
      final result = await _authService.updateFcmToken(token);
      if (result['success'] == true) {
        debugPrint('FCM: Token successfully synced with Laravel');
      } else {
        debugPrint('FCM: Failed to sync token: ${result['message']}');
      }
    }
  }
}
