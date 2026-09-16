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
    final userRole = prefs.getString('user_role') ?? 'student';
    final idStudent = prefs.getInt('idStudent') ?? 0;
    
    if (userRole == 'parent') {
      debugPrint('FCM: Clearing parent token on server...');
      await _authService.updateParentFcmToken('');
      debugPrint('FCM: Parent token cleared on server');
    } else if (idStudent != 0) {
      debugPrint('FCM: Clearing student token on server...');
      await _authService.updateFcmToken('');
      debugPrint('FCM: Student token cleared on server');
    }
  }

  static Future<void> _sendTokenToBackend(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final userRole = prefs.getString('user_role') ?? 'student';
    final idStudent = prefs.getInt('idStudent') ?? 0;
    
    // Also check if notifications are enabled in settings
    final notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
    
    if (notificationsEnabled) {
      if (userRole == 'parent') {
        debugPrint('FCM: Syncing parent token with Laravel...');
        final result = await _authService.updateParentFcmToken(token);
        if (result['success'] == true) {
          debugPrint('FCM: Parent token successfully synced with Laravel');
        } else {
          debugPrint('FCM: Failed to sync parent token: ${result['message']}');
        }
      } else if (idStudent != 0) {
        debugPrint('FCM: Syncing student token with Laravel...');
        final result = await _authService.updateFcmToken(token);
        if (result['success'] == true) {
          debugPrint('FCM: Student token successfully synced with Laravel');
        } else {
          debugPrint('FCM: Failed to sync student token: ${result['message']}');
        }
      }
    }
  }
}
