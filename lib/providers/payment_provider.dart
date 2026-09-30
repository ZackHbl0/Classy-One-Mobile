import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';

class PaymentProvider with ChangeNotifier {
  final AuthService _authService = AuthService();

  Map<String, dynamic>? _paymentData;
  bool _isLoading = false;
  String _errorMessage = '';

  // Target amount defaults to 15000.0 but dynamically loaded from student's frais_scolarite
  double _targetAmount = 15000.0;

  Map<String, dynamic>? get paymentData => _paymentData;
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;

  double get totalPaid {
    if (_paymentData != null && _paymentData!['total_paid'] != null) {
      final parsed = double.tryParse(_paymentData!['total_paid'].toString());
      if (parsed != null) return parsed;
    }

    if (_paymentData == null || _paymentData!['tranches'] == null) return 0.0;

    double total = 0.0;
    final tranches = _paymentData!['tranches'] as List;

    for (var tranche in tranches) {
      final status = (tranche['status'] ?? '').toString().toLowerCase();
      if (status == 'payé' || status == 'paye' || status == 'payǸ') {
        // Amount is string like "1 500 MAD"
        String amountStr = (tranche['amount'] ?? '0')
            .toString()
            .replaceAll('MAD', '')
            .replaceAll(' ', '')
            .trim();
        total += double.tryParse(amountStr) ?? 0.0;
      }
    }
    return total;
  }

  double get targetAmount => _targetAmount;

  double get progression {
    if (_targetAmount <= 0) return 0.0;
    return (totalPaid / _targetAmount) * 100;
  }

  String get formattedTotalPaid {
    final formatter = NumberFormat("#,##0", "fr_FR");
    return "${formatter.format(totalPaid).replaceAll(',', ' ')} MAD";
  }

  String get formattedTargetAmount {
    final formatter = NumberFormat("#,##0", "fr_FR");
    return "${formatter.format(_targetAmount).replaceAll(',', ' ')} MAD";
  }

  Future<void> fetchPaymentData(int idStudent) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final result = await _authService.getPaiement(idStudent);
      if (result['success'] == true) {
        _paymentData = result['data'];
        if (_paymentData != null) {
          final target = _paymentData!['target_amount'] ?? _paymentData!['frais_scolarite'];
          if (target != null) {
            final parsed = double.tryParse(target.toString());
            if (parsed != null && parsed > 0) {
              _targetAmount = parsed;
            }
          }
        }
      } else {
        _errorMessage =
            result['message'] ?? 'Erreur lors du chargement des paiements';
      }
    } catch (e) {
      _errorMessage = 'Erreur de connexion';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void updateFromDashboard(Map<String, dynamic> dashboardStats) {
    if (dashboardStats.containsKey('frais_scolarite')) {
      final parsed = double.tryParse(dashboardStats['frais_scolarite'].toString());
      if (parsed != null && parsed > 0) {
        _targetAmount = parsed;
        notifyListeners();
      }
    }
  }
}