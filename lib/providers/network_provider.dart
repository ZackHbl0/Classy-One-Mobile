import 'dart:async';
import 'package:flutter/material.dart';
import '../services/network_connectivity_service.dart';

class NetworkProvider extends ChangeNotifier {
  final NetworkConnectivityService _service = NetworkConnectivityService();
  late StreamSubscription<bool> _subscription;

  bool _isOnline = true;
  bool _wasOffline = false;
  bool _showReconnectedBanner = false;
  DateTime? _lastOnlineTime;

  bool get isOnline => _isOnline;
  bool get wasOffline => _wasOffline;
  bool get showReconnectedBanner => _showReconnectedBanner;
  DateTime? get lastOnlineTime => _lastOnlineTime;

  NetworkProvider() {
    _isOnline = _service.isOnline;
    _service.initialize();
    _subscription = _service.onConnectivityChanged.listen(_handleStateChange);
  }

  void _handleStateChange(bool online) {
    if (_isOnline == online) return;

    if (!online) {
      _wasOffline = true;
      _showReconnectedBanner = false;
    } else if (_wasOffline) {
      _showReconnectedBanner = true;
      _lastOnlineTime = DateTime.now();
      Timer(const Duration(seconds: 4), () {
        _showReconnectedBanner = false;
        notifyListeners();
      });
    }

    _isOnline = online;
    notifyListeners();
  }

  Future<void> manualRefresh() async {
    await _service.checkConnection();
  }

  @override
  void dispose() {
    _subscription.cancel();
    _service.dispose();
    super.dispose();
  }
}