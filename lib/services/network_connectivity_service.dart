import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Instant internet connectivity listener and health monitor without external native plugin compilation.
/// Uses Dart IO DNS resolution + Socket tests for true internet reachability.
class NetworkConnectivityService {
  static final NetworkConnectivityService _instance = NetworkConnectivityService._internal();
  factory NetworkConnectivityService() => _instance;
  NetworkConnectivityService._internal();

  final ValueNotifier<bool> isOnlineNotifier = ValueNotifier<bool>(true);
  final StreamController<bool> _connectivityController = StreamController<bool>.broadcast();

  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  bool get isOnline => isOnlineNotifier.value;

  Timer? _pollingTimer;
  bool _isChecking = false;

  /// Starts global network monitoring
  void initialize() {
    checkConnection();
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      checkConnection();
    });
  }

  /// Disposes polling resources
  void dispose() {
    _pollingTimer?.cancel();
    _connectivityController.close();
  }

  /// Force manual check of network reachability
  Future<bool> checkConnection() async {
    if (_isChecking) return isOnlineNotifier.value;
    _isChecking = true;

    bool connected = false;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 2));
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        connected = true;
      }
    } on SocketException catch (_) {
      connected = false;
    } on TimeoutException catch (_) {
      connected = false;
    } catch (_) {
      connected = false;
    } finally {
      _isChecking = false;
    }

    if (isOnlineNotifier.value != connected) {
      isOnlineNotifier.value = connected;
      _connectivityController.add(connected);
      debugPrint('NetworkConnectivityService: Connection state changed -> ${connected ? "ONLINE" : "OFFLINE"}');
    }

    return connected;
  }

  /// Mark offline immediately when an HTTP call fails due to connection loss
  void reportNetworkFailure() {
    if (isOnlineNotifier.value) {
      isOnlineNotifier.value = false;
      _connectivityController.add(false);
      debugPrint('NetworkConnectivityService: Immediate offline flag triggered by failed network call');
    }
  }

  /// Mark online immediately when an HTTP call succeeds
  void reportNetworkSuccess() {
    if (!isOnlineNotifier.value) {
      isOnlineNotifier.value = true;
      _connectivityController.add(true);
      debugPrint('NetworkConnectivityService: Back online flag triggered by successful network call');
    }
  }
}