import '../config/constants.dart';

/// Utility class to fix localhost URLs returned by the backend
/// and convert them to use the proper server IP address.
class UrlFixer {
  UrlFixer._();

  /// Fixes localhost URLs to use the proper server IP
  /// Handles various localhost formats:
  /// - http://localhost:8000/...
  /// - http://127.0.0.1:8000/...
  /// - http://localhost/...
  static String fixUrl(String url) {
    if (url.isEmpty) return url;

    try {
      String newUrl = url;
      
      // If the URL contains localhost or 127.0.0.1 or 10.0.2.2
      if (newUrl.contains('localhost:8000') || 
          newUrl.contains('127.0.0.1:8000') || 
          newUrl.contains('10.0.2.2:8000') ||
          newUrl.contains('localhost') || 
          newUrl.contains('127.0.0.1')) {
          
        // Get the actual host from baseUrl
        final baseUri = Uri.parse(AppConstants.baseUrl);
        final serverHost = baseUri.host;
        
        // Replace all possible local hosts with the correct server host
        newUrl = newUrl.replaceAll('localhost:8000', '$serverHost:8000');
        newUrl = newUrl.replaceAll('127.0.0.1:8000', '$serverHost:8000');
        newUrl = newUrl.replaceAll('10.0.2.2:8000', '$serverHost:8000');
        
        // Also catch without port just in case
        newUrl = newUrl.replaceAll('http://localhost/', 'http://$serverHost/');
        newUrl = newUrl.replaceAll('http://127.0.0.1/', 'http://$serverHost/');
      }

      return newUrl;
    } catch (e) {
      // If anything fails, return original URL
      return url;
    }
  }

  /// Fixes storage URLs specifically
  /// Converts: http://localhost:8000/storage/...
  /// To: http://192.168.100.99:8000/storage/...
  static String fixStorageUrl(String url) {
    return fixUrl(url);
  }

  /// Batch fix multiple URLs
  static List<String> fixUrls(List<String> urls) {
    return urls.map((url) => fixUrl(url)).toList();
  }
}
