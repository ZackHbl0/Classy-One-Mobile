import 'package:flutter/foundation.dart';
void main() {
  final url = "http://127.0.0.1:8000/storage/courses/01KSE704JMWM96Z6KHZMS8Y44Y.pdf";
  final uri = Uri.parse(url);
  print('host: ${uri.host}');
  
  final baseUrl = "http://192.168.1.76:8000/api";
  final baseUri = Uri.parse(baseUrl);
  print('baseHost: ${baseUri.host}');
  
  final fixedUri = Uri(
    scheme: uri.scheme,
    host: baseUri.host,
    port: uri.port,
    path: uri.path,
  );
  print('fixed: ${fixedUri.toString()}');
}
