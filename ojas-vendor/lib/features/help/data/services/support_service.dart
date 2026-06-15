import 'package:ojas_vendor/core/services/api_service.dart';
import 'package:ojas_vendor/core/services/service_locator.dart';
import '../../domain/models/support_ticket_model.dart';

class SupportService {
  final _dio = sl<ApiService>().dio;

  Future<List<SupportTicketModel>> getMyTickets() async {
    try {
      final response = await _dio.get('/support/vendor/my-tickets');
      if (response.data['success']) {
        final List list = response.data['data'];
        return list.map((item) => SupportTicketModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> createTicket({
    required String category,
    required String subject,
    required String message,
    String? phone,
    String? priority,
  }) async {
    try {
      final response = await _dio.post('/support/vendor/create', data: {
        'category': category,
        'subject': subject,
        'message': message,
        'phone': phone,
        'priority': priority,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
  Future<bool> addResponse(String id, String message) async {
    try {
      final response = await _dio.post('/support/vendor/respond/$id', data: {
        'message': message,
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
