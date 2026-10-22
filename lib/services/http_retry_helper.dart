import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'network_connectivity_service.dart';

/// Exponential backoff retry helper for HTTP API calls.
class HttpRetryHelper {
  /// Retries an asynchronous HTTP operation with exponential backoff delays.
  /// Example delays for 3 attempts: 1s, 2s, 4s.
  static Future<T> retry<T>(
    Future<T> Function() request, {
    int maxAttempts = 3,
    Duration initialDelay = const Duration(seconds: 1),
    double backoffMultiplier = 2.0,
  }) async {
    int attempt = 0;
    Duration currentDelay = initialDelay;

    while (true) {
      attempt++;
      try {
        final result = await request();
        NetworkConnectivityService().reportNetworkSuccess();
        return result;
      } catch (e) {
        final isNetworkIssue = e is SocketException ||
            e is TimeoutException ||
            e is HttpException ||
            e.toString().contains('Failed host lookup') ||
            e.toString().contains('Connection refused') ||
            e.toString().contains('OS Error');

        if (isNetworkIssue) {
          NetworkConnectivityService().reportNetworkFailure();
        }

        if (attempt >= maxAttempts || !isNetworkIssue) {
          debugPrint('HttpRetryHelper: Giving up after $attempt attempts. Error: $e');
          rethrow;
        }

        debugPrint('HttpRetryHelper: Attempt $attempt failed. Retrying in ${currentDelay.inMilliseconds}ms...');
        await Future.delayed(currentDelay);
        currentDelay = Duration(milliseconds: (currentDelay.inMilliseconds * backoffMultiplier).toInt());
      }
    }
  }
}