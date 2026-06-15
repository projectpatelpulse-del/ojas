import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/session_service.dart';
import 'package:ojas_user/features/auth/domain/models/user_model.dart';
import 'package:ojas_user/features/auth/application/auth_service.dart';

class ProfileService {
  Future<UserModel?> updateProfile({
    required String name,
    required String bio,
    required String mobile,
    required String gender,
    XFile? photo,
  }) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/user/profile/update');
      final request = http.MultipartRequest('PUT', uri);
      
      final token = await AuthService().getToken();
      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      request.fields['name'] = name;
      request.fields['bio'] = bio;
      request.fields['mobile'] = mobile;
      request.fields['gender'] = gender;

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: photo.name,
            contentType: MediaType('image', 'jpeg'), // Standard JPEG
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            photo.path,
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          final updatedUser = UserModel.fromJson(data['data']);
          SessionService.instance.setUser(updatedUser);
          return updatedUser;
        }
      }
      return null;
    } catch (e) {
      debugPrint('Update profile error: $e');
      return null;
    }
  }
}
