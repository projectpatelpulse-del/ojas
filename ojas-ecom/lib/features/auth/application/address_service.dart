import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ojas_user/core/services/api_service.dart';
import '../domain/models/address_model.dart';

class AddressService {
  String get endpoint => ApiService.userBaseUrl;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_auth_token');
  }

  Future<List<AddressModel>> getAddresses() async {
    try {
      final token = await _getToken();
      if (token == null) return [];

      final response = await http.get(
        Uri.parse('$endpoint/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> list = data['data'] ?? [];
        return list.map((e) => AddressModel.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Get addresses error: $e');
      return [];
    }
  }

  Future<bool> addAddress(AddressModel address) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$endpoint/address/add'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(address.toJson()),
      );

      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Add address error: $e');
      return false;
    }
  }

  Future<bool> updateAddress(String addressId, AddressModel address) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$endpoint/address/update/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(address.toJson()),
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Update address error: $e');
      return false;
    }
  }

  Future<bool> deleteAddress(String addressId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.delete(
        Uri.parse('$endpoint/address/delete/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Delete address error: $e');
      return false;
    }
  }

  Future<bool> setDefaultAddress(String addressId) async {
    try {
      final token = await _getToken();
      if (token == null) return false;

      final response = await http.put(
        Uri.parse('$endpoint/address/default/$addressId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Set default address error: $e');
      return false;
    }
  }
}
