import 'package:flutter/foundation.dart';

/// Application-wide constants and configuration values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// URL pour connexion directe par câble USB via "adb reverse tcp:8000 tcp:8000"
  static const String _usbUrl = "http://127.0.0.1:8000/api";

  /// URL pour connexion sans fil via le réseau Wi-Fi local
  static const String _wifiUrl = "http://192.168.100.99:8000/api";

  /// URL active dynamique
  static String _activeUrl = _usbUrl;

  /// Base URL pour le backend Laravel Classy-One
  static String get baseUrl => _activeUrl;

  /// URL de secours automatique (si USB échoue, essayer Wi-Fi et vice-versa)
  static String get fallbackUrl => _activeUrl == _usbUrl ? _wifiUrl : _usbUrl;

  /// Basculer automatiquement vers l'URL qui répond
  static void switchUrl() {
    _activeUrl = fallbackUrl;
    debugPrint('AppConstants: URL basculée automatiquement vers $_activeUrl');
  }

  static void setBaseUrl(String url) {
    _activeUrl = url;
  }

  /// Derives the Laravel public/storage base URL from the API baseUrl
  static String get storageUrl {
    final parts = baseUrl.split('/api');
    return '${parts[0]}/storage/';
  }

  /// Timeout duration for HTTP requests (in seconds)
  static const int requestTimeout = 30;

  /// App version
  static const String appVersion = "1.0.0";

  /// App name
  static const String appName = "Classy One";
}