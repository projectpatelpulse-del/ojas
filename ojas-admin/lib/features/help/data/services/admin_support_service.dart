import 'package:ojas_admin/core/services/api_service.dart';
import 'package:ojas_admin/core/services/service_locator.dart';
import '../../domain/models/support_ticket_model.dart';

class AdminSupportService {
  final _dio = sl<ApiService>().dio;

  Future<List<SupportTicketModel>> getAllTickets() async {
    try {
      final response = await _dio.get('/support/admin/all');
      if (response.data['success']) {
        final List list = response.data['data'];
        return list.map((item) => SupportTicketModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateStatus(String id, String status) async {
    try {
      final response = await _dio.put('/support/admin/status/$id', data: {'status': status});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addResponse(String id, String message) async {
    try {
      final response = await _dio.post('/support/admin/respond/$id', data: {
        'message': message,
        'sender': 'Admin'
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  // --- User Support Tickets ---

  Future<List<SupportTicketModel>> getAllUserTickets() async {
    try {
      final response = await _dio.get('/user-support/admin/all');
      if (response.data['success']) {
        final List list = response.data['data'];
        return list.map((item) => SupportTicketModel.fromMap(item)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> updateUserTicketStatus(String id, String status) async {
    try {
      final response = await _dio.put('/user-support/admin/status/$id', data: {'status': status});
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addUserTicketResponse(String id, String message) async {
    try {
      final response = await _dio.post('/user-support/admin/respond/$id', data: {
        'message': message,
        'sender': 'Admin'
      });
      return response.data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
