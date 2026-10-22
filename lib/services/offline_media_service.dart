import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/url_fixer.dart';

/// Manages downloading and offline storage of course materials, PDFs, and lesson documents.
class OfflineMediaService {
  static const String _metaKey = 'offline_materials_metadata';

  /// Generates a deterministic local filename for any given URL.
  static String _generateLocalFilename(String url) {
    final cleanUrl = url.split('?').first;
    final extension = cleanUrl.contains('.') ? cleanUrl.split('.').last.toLowerCase() : 'pdf';
    final safeHash = url.hashCode.abs().toString();
    return 'material_${safeHash}.$extension';
  }

  /// Returns the Directory dedicated to offline school materials.
  static Future<Directory> _getMaterialsDir() async {
    final baseDir = await getApplicationDocumentsDirectory();
    final materialsDir = Directory('${baseDir.path}/classy_offline_materials');
    if (!await materialsDir.exists()) {
      await materialsDir.create(recursive: true);
    }
    return materialsDir;
  }

  /// Checks if a file has been downloaded and exists locally on disk.
  static Future<bool> isFileCached(String url) async {
    try {
      final dir = await _getMaterialsDir();
      final filename = _generateLocalFilename(url);
      final file = File('${dir.path}/$filename');
      return await file.exists() && await file.length() > 0;
    } catch (_) {
      return false;
    }
  }

  /// Returns the absolute path to the local cached file, or null if not cached.
  static Future<String?> getCachedFilePath(String url) async {
    try {
      final dir = await _getMaterialsDir();
      final filename = _generateLocalFilename(url);
      final file = File('${dir.path}/$filename');
      if (await file.exists() && await file.length() > 0) {
        return file.path;
      }
    } catch (e) {
      debugPrint('OfflineMedia: Error checking cached file: $e');
    }
    return null;
  }

  /// Downloads file from URL and saves it persistently for offline viewing.
  static Future<String> downloadAndCacheFile(
    String url, {
    String? title,
    String? courseTitle,
    Function(double progress)? onProgress,
  }) async {
    final fixedUrl = UrlFixer.fixUrl(url);
    debugPrint('OfflineMedia: Downloading $fixedUrl for offline storage...');

    final dir = await _getMaterialsDir();
    final filename = _generateLocalFilename(url);
    final file = File('${dir.path}/$filename');

    // If already downloaded, return path immediately
    if (await file.exists() && await file.length() > 0) {
      debugPrint('OfflineMedia: File already cached at ${file.path}');
      return file.path;
    }

    final response = await http.get(Uri.parse(fixedUrl));
    if (response.statusCode != 200) {
      throw Exception('Erreur de téléchargement: Code HTTP ${response.statusCode}');
    }

    await file.writeAsBytes(response.bodyBytes);
    debugPrint('OfflineMedia: Saved ${response.bodyBytes.length} bytes to ${file.path}');

    // Record metadata for offline management
    await _saveMaterialMetadata(
      url: url,
      localPath: file.path,
      title: title ?? filename,
      courseTitle: courseTitle,
      sizeBytes: response.bodyBytes.length,
    );

    return file.path;
  }

  /// Saves metadata about downloaded course files.
  static Future<void> _saveMaterialMetadata({
    required String url,
    required String localPath,
    required String title,
    String? courseTitle,
    required int sizeBytes,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listRaw = prefs.getStringList(_metaKey) ?? [];
      final list = listRaw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      list.removeWhere((item) => item['url'] == url);
      list.add({
        'url': url,
        'localPath': localPath,
        'title': title,
        'courseTitle': courseTitle ?? '',
        'sizeBytes': sizeBytes,
        'downloadedAt': DateTime.now().toIso8601String(),
      });

      await prefs.setStringList(_metaKey, list.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      debugPrint('OfflineMedia: Error saving metadata: $e');
    }
  }

  /// Lists all downloaded materials currently available offline.
  static Future<List<Map<String, dynamic>>> getDownloadedMaterials() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final listRaw = prefs.getStringList(_metaKey) ?? [];
      final list = listRaw.map((e) => jsonDecode(e) as Map<String, dynamic>).toList();

      final validList = <Map<String, dynamic>>[];
      for (final item in list) {
        final path = item['localPath'] as String?;
        if (path != null && await File(path).exists()) {
          validList.add(item);
        }
      }
      return validList;
    } catch (_) {
      return [];
    }
  }

  /// Deletes a cached offline file.
  static Future<void> deleteCachedFile(String url) async {
    try {
      final dir = await _getMaterialsDir();
      final filename = _generateLocalFilename(url);
      final file = File('${dir.path}/$filename');
      if (await file.exists()) {
        await file.delete();
      }

      final prefs = await SharedPreferences.getInstance();
      final listRaw = prefs.getStringList(_metaKey) ?? [];
      final list = listRaw
          .map((e) => jsonDecode(e) as Map<String, dynamic>)
          .where((item) => item['url'] != url)
          .toList();
      await prefs.setStringList(_metaKey, list.map((e) => jsonEncode(e)).toList());
    } catch (e) {
      debugPrint('OfflineMedia: Error deleting cached file: $e');
    }
  }
}