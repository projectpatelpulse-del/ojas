import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'package:ojas_user/core/services/api_service.dart';

class SocketService {
  static final SocketService instance = SocketService._internal();
  SocketService._internal();

  io.Socket? socket;
  
  // Callback registry for specific events
  final Map<String, List<Function(dynamic)>> _listeners = {};

  void init() {
    if (socket != null) return;

    // Use the same base URL as API but without /api suffix usually for socket.io
    // Same host as API without trailing /api (Socket.IO on ojas_backend port).
    final baseUrl = ApiService.baseUrl.replaceAll('/api', '');
    
    debugPrint('Initializing Socket connection to: $baseUrl');

    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': true,
    });

    socket!.onConnect((_) {
      debugPrint('Socket connected: ${socket!.id}');
    });

    socket!.onDisconnect((_) {
      debugPrint('Socket disconnected');
    });

    socket!.onConnectError((err) => debugPrint('Socket Connect Error: $err'));
    
    // Listen for the general admin update event
    socket!.on('admin_data_updated', (data) {
      debugPrint('Real-time update received: $data');
      
      // Notify generic listeners
      if (_listeners.containsKey('admin_data_updated')) {
        final listeners = List<Function(dynamic)>.from(_listeners['admin_data_updated']!);
        for (var callback in listeners) {
          callback(data);
        }
      }
      
      // Notify type-specific listeners (e.g., 'blog', 'category', 'product')
      final type = data['type'];
      if (type != null && _listeners.containsKey(type)) {
        final listeners = List<Function(dynamic)>.from(_listeners[type]!);
        for (var callback in listeners) {
          callback(data);
        }
      }
    });

    // Also support direct event names if emitted that way
    socket!.on('settings_updated', (data) {
      if (_listeners.containsKey('settings_updated')) {
        for (var callback in _listeners['settings_updated']!) {
          callback(data);
        }
      }
    });
  }

  void on(String type, Function(dynamic) callback) {
    if (!_listeners.containsKey(type)) {
      _listeners[type] = [];
    }
    _listeners[type]!.add(callback);
  }

  void off(String type, [Function(dynamic)? callback]) {
    if (callback == null) {
      _listeners.remove(type);
    } else {
      _listeners[type]?.remove(callback);
    }
  }

  void disconnect() {
    socket?.disconnect();
    socket = null;
  }
}
