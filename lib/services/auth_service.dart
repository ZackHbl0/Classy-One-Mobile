import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class AuthService {
  // Use your local IP or appropriate testing server URL.
  // For android emulator, 'http://10.0.2.2/OSBT_notif' is typical.
  // For physical device, use your machine's local IP on the network (e.g. 'http://192.168.1.100/OSBT_notif').
  static const String baseUrl = 'http://192.168.0.33/OSBT_notif';

  Future<Map<String, dynamic>> login(
    String matricule,
    String password, {
    String fcmToken = '',
  }) async {
    final url = Uri.parse('$baseUrl/login.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': matricule,
          'password': password,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Wrap the response in our own result map including the model
        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'message': data['message'],
            'student': Student.fromJson(data['data']),
          };
        }
        return {'success': false, 'message': data['message'] ?? 'Login failed'};
      } else {
        // Handle non-200 responses safely
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
  }) async {
    final url = Uri.parse('$baseUrl/register.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'matricule': matricule,
          'nom': nom,
          'prenom': prenom,
          'password': password,
          'fcmToken': fcmToken,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['success'] == true && data['data'] != null) {
          return {
            'success': true,
            'message': data['message'] ?? 'Registration successful',
            'student': Student.fromJson(data['data']),
          };
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
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

  Future<Map<String, dynamic>> getDashboardData(int idStudent) async {
    final url = Uri.parse('$baseUrl/get_dashboard_data.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idStudent': idStudent}),
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
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> getNotifications(int idStudent) async {
    final url = Uri.parse('$baseUrl/get_notifications.php');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idStudent': idStudent}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return {'success': true, 'data': data['data']};
        }
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to load notifications',
        };
      } else {
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
