import 'package:flutter/foundation.dart';

class AppConstants {
  static String get baseUrl {
    if (kIsWeb) {
      return "http://127.0.0.1:8000/api";
    }
    return "http://192.168.1.76:8000/api";
  }
}

class UrlFixer {
  static String fixUrl(String url) {
    if (url.isEmpty) return url;

    try {
      final uri = Uri.parse(url);

      if (uri.host == 'localhost' || uri.host == '127.0.0.1') {
        final baseUri = Uri.parse(AppConstants.baseUrl);
        final serverHost = baseUri.host;
        final serverPort = uri.port != 80 && uri.port != 0 ? uri.port : 8000;

        final fixedUri = Uri(
          scheme: uri.scheme,
          host: serverHost,
          port: serverPort,
          path: uri.path,
          query: uri.query.isNotEmpty ? uri.query : null,
          fragment: uri.fragment.isNotEmpty ? uri.fragment : null,
        );

        return fixedUri.toString();
      }

      return url;
    } catch (e) {
      print("Error in fixUrl: $e");
      return url;
    }
  }
}

void main() {
  final url = "http://127.0.0.1:8000/storage/courses/01KSE704JMWM96Z6KHZMS8Y44Y.pdf";
  print(UrlFixer.fixUrl(url));
}
