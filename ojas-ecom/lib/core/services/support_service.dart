import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/session_service.dart';

class SupportService {
  static const String _endpoint = '/user-support';

  static Future<Map<String, dynamic>> createTicket({
    required String category,
    required String subject,
    required String message,
    String? phone,
    String? priority,
  }) async {
    try {
      final token = SessionService.instance.token;
      if (token == null) {
        return {'success': false, 'message': 'You must be logged in to raise a ticket'};
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}$_endpoint/create'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'category': category,
          'subject': subject,
          'message': message,
          'phone': phone,
          'priority': priority ?? 'Medium',
        }),
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }

  static Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final token = SessionService.instance.token;
      if (token == null) {
        return {'success': false, 'message': 'You must be logged in'};
      }

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}$_endpoint/my-tickets'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'An error occurred: $e'};
    }
  }
}
