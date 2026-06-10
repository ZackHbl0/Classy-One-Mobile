import 'package:flutter/foundation.dart';

/// Application-wide constants and configuration values
class AppConstants {
  // Private constructor to prevent instantiation
  AppConstants._();

  /// Base URL for the Laravel API backend
  /// Points to the Classy-One API server
  /// Dynamically uses localhost for Web/Desktop and local IP for physical devices
  static String get baseUrl {
    if (kIsWeb) {
      // Pour Google Chrome (Web) et Windows Desktop
      return "http://127.0.0.1:8000/api";
    }
    // Pour le téléphone Android physique
    return "http://192.168.100.99:8000/api";
  }

  /// Alternative local development URL (commented out)
  // static const String baseUrl = "http://classy-one.test/api";

  /// Derives the Laravel public/storage base URL from the API baseUrl
  /// Example: "http://192.168.100.99/Classy-One/public/api"
  ///       -> "http://192.168.100.99/Classy-One/public/storage/"
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
