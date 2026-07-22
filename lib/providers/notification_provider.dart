import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class NotificationProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  List<dynamic> _notifications = [];
  bool _isLoading = false;
  String _errorMessage = '';

  List<dynamic> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  // Calculates the unread count dynamically
  int get unreadCount => _notifications.where((n) {
    final isRead = n['isRead'];
    return isRead != true && isRead != 1;
  }).length;

  Future<void> fetchNotifications(int idStudent) async {
    if (idStudent == 0) return;
    
    _isLoading = true;
    notifyListeners();

    final result = await _authService.getNotifications(idStudent);

    _isLoading = false;
    if (result['success'] == true) {
      _notifications = result['data'] ?? [];
      _errorMessage = '';
    } else {
      _errorMessage = result['message'] ?? 'Erreur lors du chargement des notifications';
    }
    notifyListeners();
  }

  Future<bool> markAllAsRead(int idStudent) async {
    if (idStudent == 0) return false;
    if (unreadCount == 0) return true;

    final result = await _authService.markNotificationsRead(idStudent);
    if (result['success'] == true) {
      for (var notif in _notifications) {
        notif['isRead'] = true;
      }
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> markAsRead(int idStudent, int idNotification) async {
    if (idStudent == 0) return false;

    // Local optimistic update
    final index = _notifications.indexWhere((n) => n['id'] == idNotification);
    if (index != -1 && _notifications[index]['isRead'] != true) {
      _notifications[index]['isRead'] = true;
      notifyListeners();

      final result = await _authService.markNotificationsRead(
        idStudent,
        idNotification: idNotification,
      );

      if (result['success'] != true) {
        // Revert on failure
        _notifications[index]['isRead'] = false;
        notifyListeners();
        return false;
      }
      return true;
    }
    return false;
  }

  void removeNotification(int notifId) {
    _notifications.removeWhere((n) => n['id'] == notifId);
    notifyListeners();
  }

  Future<bool> deleteNotification(int notifId) async {
    // Optimistic UI update: remove locally first
    final backupNotif = _notifications.firstWhere((n) => n['id'] == notifId, orElse: () => null);
    final backupIndex = _notifications.indexWhere((n) => n['id'] == notifId);
    
    if (backupIndex != -1) {
      _notifications.removeAt(backupIndex);
      notifyListeners();

      final result = await _authService.deleteNotification(notifId);
      
      if (result['success'] != true) {
        // Revert on failure
        if (backupNotif != null) {
          _notifications.insert(backupIndex, backupNotif);
          notifyListeners();
        }
        return false;
      }
      return true;
    }
    return false;
  }
}
