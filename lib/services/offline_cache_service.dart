import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized offline data caching service using SharedPreferences.
/// Caches API payloads with timestamp and supports automatic fallback when offline.
class OfflineCacheService {
  static const String _prefix = 'classy_cache_';
  static const String _timePrefix = 'classy_cache_time_';

  /// Saves JSON-encodable data into local cache.
  static Future<void> setCache(String key, dynamic data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String encoded = jsonEncode(data);
      await prefs.setString('$_prefix$key', encoded);
      await prefs.setString('$_timePrefix$key', DateTime.now().toIso8601String());
      debugPrint('OfflineCache: Cached "$key" (${encoded.length} bytes)');
    } catch (e) {
      debugPrint('OfflineCache: Error caching "$key": $e');
    }
  }

  /// Retrieves cached data if present.
  static Future<dynamic> getCache(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? encoded = prefs.getString('$_prefix$key');
      if (encoded != null && encoded.isNotEmpty) {
        return jsonDecode(encoded);
      }
    } catch (e) {
      debugPrint('OfflineCache: Error reading cache for "$key": $e');
    }
    return null;
  }

  /// Returns the DateTime when this key was cached, or null.
  static Future<DateTime?> getCacheTime(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? iso = prefs.getString('$_timePrefix$key');
      if (iso != null) {
        return DateTime.tryParse(iso);
      }
    } catch (_) {}
    return null;
  }

  /// Returns a human-friendly label (e.g. "Sauvegardé il y a 10 min")
  static Future<String?> getFormattedCacheTime(String key) async {
    final time = await getCacheTime(key);
    if (time == null) return null;
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'il y a ${diff.inHours} h';
    return '${time.day}/${time.month} à ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  /// Checks if cached data exists for this key.
  static Future<bool> hasCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('$_prefix$key');
  }

  /// Clears cache for a specific key.
  static Future<void> removeCache(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$key');
    await prefs.remove('$_timePrefix$key');
  }

  /// Clears all application caches (e.g. on logout).
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith(_prefix) || k.startsWith(_timePrefix)).toList();
    for (final k in keys) {
      await prefs.remove(k);
    }
    debugPrint('OfflineCache: Cleared ${keys.length} cache entries.');
  }
}