import 'dart:html' as html;
import 'package:flutter/foundation.dart';

class WebNotificationHelper {
  static Future<bool> requestPermission() async {
    if (!kIsWeb) return false;
    try {
      if (!html.Notification.supported) return false;
      final permission = await html.Notification.requestPermission();
      return permission == 'granted';
    } catch (e) {
      debugPrint('Web Notification permission request error: $e');
      return false;
    }
  }

  static bool get isSupported {
    if (!kIsWeb) return false;
    try {
      return html.Notification.supported;
    } catch (_) {
      return false;
    }
  }

  static bool get isGranted {
    if (!kIsWeb || !isSupported) return false;
    try {
      return html.Notification.permission == 'granted';
    } catch (_) {
      return false;
    }
  }

  static void showNotification({
    required String title,
    required String body,
    String? icon,
  }) {
    if (kIsWeb && isSupported && isGranted) {
      try {
        html.Notification(
          title,
          body: body,
          icon: icon ?? '/favicon.png',
        );
      } catch (e) {
        debugPrint('Show Web Notification error: $e');
      }
    }
  }
}
