import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ojas_user/core/services/api_service.dart';
import '../domain/models/user_model.dart';

class AuthService {
  String get endpoint => ApiService.userBaseUrl;

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_auth_token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_auth_token');
  }

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return AuthResponse(
          success: true,
          user: data['data'] != null ? UserModel.fromJson(data['data']) : null,
          message: data['message'] ?? 'Login Successful',
          token: data['token'],
        );
      } else {
        return AuthResponse(success: false, message: data['message'] ?? 'Login Failed');
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Server error: $e');
    }
  }

  Future<AuthResponse> signInWithGoogle() async {
    try {
      User? firebaseUser;

      if (kIsWeb) {
        final authProvider = GoogleAuthProvider();
        try {
          final userCredential = await FirebaseAuth.instance.signInWithPopup(authProvider);
          firebaseUser = userCredential.user;
        } catch (e) {
          return AuthResponse(success: false, message: 'Google Sign In Error: $e');
        }
      } else {
        final googleSignIn = GoogleSignIn.instance;
        try {
          await googleSignIn.initialize();
        } catch (_) {}

        GoogleSignInAccount? googleUser;
        try {
          googleUser = await googleSignIn.authenticate();
        } catch (e) {
          return AuthResponse(success: false, message: 'Google Sign In Error: $e');
        }

        final googleAuth = googleUser.authentication;
        final credential = FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(
            idToken: googleAuth.idToken,
          )
        );

        final userCredential = await credential;
        firebaseUser = userCredential.user;
      }

      if (firebaseUser != null) {
        final idToken = await firebaseUser.getIdToken(true);
        if (idToken != null) {
          final response = await http.post(
            Uri.parse('$endpoint/google'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idToken': idToken}),
          );

          final data = json.decode(response.body);

          if (response.statusCode == 200) {
            if (data['token'] != null) {
              await _saveToken(data['token']);
            }
            return AuthResponse(
              success: true,
              user: data['data'] != null ? UserModel.fromJson(data['data']) : null,
              message: data['message'] ?? 'Login Successful',
              token: data['token'],
            );
          } else {
            return AuthResponse(success: false, message: data['message'] ?? 'Login Failed');
          }
        }
      }
      return AuthResponse(success: false, message: 'Failed to retrieve Google token');
    } catch (e) {
      return AuthResponse(success: false, message: 'Google Sign In Error: $e');
    }
  }

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
    required String gender,
    required String mobile,
    String role = "user",
    XFile? image,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$endpoint/register'));
      
      request.fields['name'] = name;
      request.fields['email'] = email;
      request.fields['password'] = password;
      request.fields['gender'] = gender.toLowerCase();
      request.fields['mobile'] = mobile;
      request.fields['role'] = role;

      if (image != null) {
        if (kIsWeb) {
          final bytes = await image.readAsBytes();
          request.files.add(http.MultipartFile.fromBytes(
            'photo',
            bytes,
            filename: image.name,
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'photo',
            image.path,
          ));
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = json.decode(response.body);

      if (response.statusCode == 201 || response.statusCode == 200) {
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return AuthResponse(
          success: true, 
          message: 'Registration Successful',
          token: data['token'],
        );
      } else {
        return AuthResponse(success: false, message: data['message'] ?? 'Registration Failed');
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Server error: $e');
    }
  }

  Future<UserModel?> getCurrentUser() async {
    try {
      final token = await getToken();
      final response = await http.get(
        Uri.parse('$endpoint/profile'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] != null ? UserModel.fromJson(data['data']) : null;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_auth_token');
  }

  Future<AuthResponse> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$endpoint/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      print('Forgot Password Response: ${response.body}');
      final data = json.decode(response.body);

      if (response.statusCode == 200) {
        return AuthResponse(
          success: true,
          message: data['message'] ?? 'Password reset email sent',
        );
      } else {
        return AuthResponse(
          success: false,
          message: data['message'] ?? 'Failed to send reset email',
        );
      }
    } catch (e) {
      return AuthResponse(success: false, message: 'Server error: $e');
    }
  }
}

class AuthResponse {
  final bool success;
  final String message;
  final UserModel? user;
  final String? token;

  AuthResponse({required this.success, required this.message, this.user, this.token});
}
