import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ojas_user/core/models/app_settings.dart';
import 'package:ojas_user/core/services/api_service.dart';
import 'package:ojas_user/core/services/socket_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SettingsController with ChangeNotifier {
  static final SettingsController instance = SettingsController._internal();
  SettingsController._internal();

  AppSettings _settings = AppSettings.defaultSettings();
  AppSettings get settings => _settings;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  Future<void> init() async {
    await fetchSettings();
    
    // Listen for real-time settings updates
    SocketService.instance.on('settings', (data) {
      if (data['data'] != null) {
        _settings = AppSettings.fromJson(data['data']);
        _updateBrowserMetadata();
        notifyListeners();
        debugPrint('Settings auto-updated via socket');
      }
    });
  }

  Future<void> fetchSettings() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await http.get(Uri.parse('${ApiService.baseUrl}/home/settings'));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          _settings = AppSettings.fromJson(data['data']);
          _updateBrowserMetadata();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _updateBrowserMetadata() {
    if (!kIsWeb) return;
    try {
      // Update Title
      html.document.title = _settings.marketplaceName;

      // Update Favicon (More aggressive approach)
      if (_settings.favicon.isNotEmpty) {
        // 1. Remove all existing favicon links
        html.document.head!
            .querySelectorAll("link[rel*='icon']")
            .forEach((el) => el.remove());

        // 2. Create and append new favicon link
        final link = html.LinkElement()
          ..rel = 'icon'
          ..href = '${_settings.favicon}?v=${DateTime.now().millisecondsSinceEpoch}'; // Cache busting
        
        html.document.head!.append(link);
        debugPrint('Favicon updated to: ${link.href}');
      }
    } catch (e) {
      debugPrint('Error updating browser metadata: $e');
    }
  }
}
