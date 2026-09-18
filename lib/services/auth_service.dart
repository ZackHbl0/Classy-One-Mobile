import '../models/parent_dashboard_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../models/student.dart';
import '../config/constants.dart';

class AuthService {
  // Use centralized BASE_URL from constants
  static String get baseUrl => AppConstants.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, dynamic>> login(
    String matricule,
    String password, {
    String fcmToken = '',
  }) async {
    if (fcmToken.isEmpty) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (e) {
        debugPrint('Erreur FCM: $e');
      }
    }

    final url = Uri.parse('$baseUrl/login'); // Laravel route

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'matricule': matricule,
          'password': password,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Trop de tentatives de connexion. Pour votre sécurité, veuillez patienter une minute.',
        };
      } else if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Laravel auth returns status 'success' (string) or success true
        if (data['status'] == 'success' || data['success'] == true) {
          // Save Sanctum token
          final prefs = await SharedPreferences.getInstance();
          if (data['token'] != null) {
            await prefs.setString('auth_token', data['token']);
          }

          return {
            'success': true,
            'message': data['message'],
            'student': Student.fromJson(data['student'] ?? data['data']),
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      } else {
        try {
          final errorData = jsonDecode(response.body);
          return {
            'success': false,
            'message':
                errorData['message'] ?? 'Server error: ${response.statusCode}',
          };
        } catch (e) {
          return {
            'success': false,
            'message':
                'Server returned an invalid response. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> register(
    String matricule,
    String nom,
    String prenom,
    String password, {
    String fcmToken = '',
    String telephone = '',
  }) async {
    if (fcmToken.isEmpty) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (e) {
        debugPrint('Erreur FCM: $e');
      }
    }

    final url = Uri.parse('$baseUrl/register');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'matricule': matricule,
          'nom': nom,
          'prenom': prenom,
          'password': password,
          'fcmToken': fcmToken,
          'telephone': telephone,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['status'] == 'success' || data['success'] == true) {
          // Save Sanctum token
          final prefs = await SharedPreferences.getInstance();
          if (data['token'] != null) {
            await prefs.setString('auth_token', data['token']);
          }

          return {
            'success': true,
            'message': data['message'] ?? 'Registration successful',
            'student': Student.fromJson(data['student'] ?? data['data']),
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      } else {
        try {
          final errorData = jsonDecode(response.body);
          // Handle Laravel validation errors nicely if present
          String errMsg =
              errorData['message'] ?? 'Server error: ${response.statusCode}';
          if (errorData['errors'] != null) {
            final errors = errorData['errors'] as Map<String, dynamic>;
            errMsg = errors.values.first[0]; // Get first validation error
          }
          return {'success': false, 'message': errMsg};
        } catch (e) {
          return {
            'success': false,
            'message':
                'Server returned an invalid response. Status: ${response.statusCode}',
          };
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<void> logout() async {
    final url = Uri.parse('$baseUrl/logout');
    try {
      final headers = await _getHeaders();
      await http.post(url, headers: headers);
    } catch (e) {
      // Ignore network errors on logout, just clear locally
    }

    // Always clear the token locally
    final prefs = await SharedPreferences.getInstance();
    // Clear parent-specific read notifications before removing email
    final email = prefs.getString('parent_email') ?? '';
    if (email.isNotEmpty) {
      await prefs.remove('parent_read_notifs_' + email);
    }
    await prefs.remove('parent_read_notifs_default');
        await prefs.remove('auth_token');
  }

  Future<Map<String, dynamic>> getDashboardData(int idStudent) async {
    final url = Uri.parse('$baseUrl/dashboard');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode(
          {},
        ), // idStudent is no longer needed but backend ignores it anyway
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {'success': true, 'data': data['data']};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load data',
        };
      } else if (response.statusCode == 401) {
        return {'success': false, 'message': 'Session expired'};
      } else {
        return {'success': false, 'message': 'Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getNotifications(int idStudent) async {
    final url = Uri.parse('$baseUrl/notifications');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getEvenements(
    int idStudent, {
    String category = 'Tout',
  }) async {
    final url = Uri.parse('$baseUrl/events');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'category': category}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPlanning(int idStudent) async {
    final url = Uri.parse('$baseUrl/planning');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);

      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error: ${response.statusCode}',
        };
      } catch (e) {
        return {'success': false, 'message': 'Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getPaiement(int idStudent) async {
    final url = Uri.parse('$baseUrl/paiement');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error: ${response.statusCode}',
        };
      } catch (e) {
        return {'success': false, 'message': 'Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePassword(
    int idStudent,
    String currentPassword,
    String newPassword,
  ) async {
    final url = Uri.parse('$baseUrl/profile/update-password');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updatePhone(
    int idStudent,
    String newPhone,
  ) async {
    final url = Uri.parse('$baseUrl/profile/update-phone');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'newPhone': newPhone}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> markNotificationsRead(
    int idStudent, {
    int? idNotification,
  }) async {
    final url = Uri.parse('$baseUrl/notifications/mark-read');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'idNotification': idNotification}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(int idNotification) async {
    final url = Uri.parse('$baseUrl/notifications/$idNotification');
    try {
      final headers = await _getHeaders();
      final response = await http.delete(url, headers: headers);
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> registerForEvent(
    int idStudent,
    int idNotification,
  ) async {
    final url = Uri.parse('$baseUrl/events/register');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'idNotification':
              idNotification, // using legacy param name mapping inside EventController
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getDocumentRequests(int idStudent) async {
    final url = Uri.parse('$baseUrl/documents');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> createDocumentRequest(
    int idStudent,
    String type,
    String? reason,
    String urgency,
  ) async {
    final url = Uri.parse('$baseUrl/documents/create');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'documentType': type,
          'reason': reason,
          'urgency': urgency.toLowerCase(),
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateFcmToken(String fcmToken) async {
    final url = Uri.parse('$baseUrl/profile/update-fcm-token');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> updateNotificationPreferences({
    required bool eventNotifications,
    required bool paymentNotifications,
  }) async {
    final url = Uri.parse('$baseUrl/profile/update-preferences');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'eventNotifications': eventNotifications,
          'paymentNotifications': paymentNotifications,
        }),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      return {'success': false, 'message': 'Error: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getGrades(int idStudent) async {
    final url = Uri.parse('$baseUrl/grades');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({}),
      );
      if (response.statusCode == 200) return jsonDecode(response.body);
      try {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['message'] ?? 'Error: ${response.statusCode}',
        };
      } catch (e) {
        return {'success': false, 'message': 'Error: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }


  // â”€â”€â”€ Absences Methods â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

  Future<Map<String, dynamic>> getAbsences() async {
    final url = Uri.parse('$baseUrl/student/absences');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Failed to load absences: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> submitJustification(int absenceId, String reason) async {
    final url = Uri.parse('$baseUrl/student/absences/$absenceId/justify');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        return {'status': 'error', 'message': 'Failed to submit justification: ${response.statusCode}'};
      }
    } catch (e) {
      return {'status': 'error', 'message': 'Connection error: $e'};
    }
  }

  // -------------------------------------------------------------
  // PARENT PORTAL AUTH, DASHBOARD, DOCUMENTS & NOTIFICATIONS
  // -------------------------------------------------------------

  Future<Map<String, dynamic>> parentLogin(
    String email,
    String password, {
    String fcmToken = '',
  }) async {
    if (fcmToken.isEmpty) {
      try {
        fcmToken = await FirebaseMessaging.instance.getToken() ?? '';
      } catch (e) {
        debugPrint('Erreur FCM Parent: $e');
      }
    }

    final url = Uri.parse('$baseUrl/parent/login');
    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          if (fcmToken.isNotEmpty) 'fcmToken': fcmToken,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 429) {
        return {
          'success': false,
          'message': 'Trop de tentatives de connexion. Pour votre sécurité, veuillez patienter une minute.',
        };
      } else if (response.statusCode == 200 && (data['status'] == 'success' || data['success'] == true)) {
        final prefs = await SharedPreferences.getInstance();
        if (data['token'] != null) {
          await prefs.setString('auth_token', data['token']);
          await prefs.setString('user_role', 'parent');
        }
        if (data['parent'] != null) {
          await prefs.setString('parent_name', data['parent']['name'] ?? '');
          await prefs.setString('parent_email', data['parent']['email'] ?? '');
          await prefs.setString('parent_phone', data['parent']['phone'] ?? '');
        }
        return {'success': true, 'data': data};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Erreur d\'authentification (${response.statusCode})',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  Future<Map<String, dynamic>> updateParentFcmToken(String fcmToken) async {
    final url = Uri.parse('$baseUrl/parent/update-fcm-token');
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({'fcmToken': fcmToken}),
      );
      final data = jsonDecode(response.body);
      return {'success': response.statusCode == 200, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': '$e'};
    }
  }

  Future<Map<String, dynamic>> getParentDocumentRequests({int? studentId}) async {
    final query = studentId != null ? '?student_id=$studentId' : '';
    final url = Uri.parse('$baseUrl/parent/documents$query');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'data': data['data'] ?? []};
      }
      return {'success': false, 'message': 'Erreur serveur: ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  Future<Map<String, dynamic>> createParentDocumentRequest({
    required int studentId,
    required String documentType,
    String? reason,
    String? comments,
    required String urgency,
  }) async {
    final url = Uri.parse('$baseUrl/parent/documents');
    try {
      final headers = await _getHeaders();
      final finalReason = (reason != null && reason.isNotEmpty)
          ? reason
          : ((comments != null && comments.isNotEmpty) ? comments : 'Demande parent');
      final response = await http.post(
        url,
        headers: headers,
        body: jsonEncode({
          'student_id': studentId,
          'document_type': documentType,
          'reason': finalReason,
          'comments': finalReason,
          'urgency': urgency.toLowerCase().startsWith('urg') ? 'urgent' : 'normal',
        }),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 || (data['status'] == 'success'),
        'message': data['message'] ?? (response.statusCode == 201 ? 'Demande soumise avec succès.' : 'Erreur'),
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  Future<Map<String, dynamic>> getParentDashboard() async {
    final url = Uri.parse('$baseUrl/parent/dashboard');
    try {
      final headers = await _getHeaders();
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'success' || data['success'] == true) {
          final parsed = ParentDashboardResponse.fromJson(data);
          return {'success': true, 'data': parsed};
        } else {
          return {'success': false, 'message': data['message'] ?? 'Erreur inconnue'};
        }
      } else {
        return {'success': false, 'message': 'Erreur serveur: ${response.statusCode}'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion : $e'};
    }
  }

  Future<void> parentLogout() async {
    final url = Uri.parse('$baseUrl/parent/logout');
    try {
      final headers = await _getHeaders();
      await http.post(url, headers: headers);
    } catch (e) {
      // ignore
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_role');
    await prefs.remove('parent_name');
    await prefs.remove('parent_email');
    await prefs.remove('parent_phone');
  }
}