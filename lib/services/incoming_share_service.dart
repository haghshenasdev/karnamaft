import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class IncomingShareService {
  IncomingShareService._();

  static const MethodChannel _channel =
      MethodChannel('karnama/incoming_share');

  static final StreamController<String> _controller =
      StreamController<String>.broadcast();

  static String? _pendingPath;
  static bool _initialized = false;

  static Stream<String> get sharedFiles => _controller.stream;

  static bool get isSupported => Platform.isAndroid;

  static void initialize() {
    if (!isSupported || _initialized) {
      return;
    }

    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'sharedFileReceived') {
        return;
      }

      final path = call.arguments?.toString();

      if (path == null || path.trim().isEmpty) {
        return;
      }

      _pendingPath = path;

      if (!_controller.isClosed) {
        _controller.add(path);
      }
    });
  }

  static Future<String?> takeInitialFile() async {
    if (!isSupported) {
      return null;
    }

    initialize();

    try {
      final path =
          await _channel.invokeMethod<String>('getInitialSharedFile');

      if (path != null && path.isNotEmpty) {
        _pendingPath = path;
      }

      final result = _pendingPath;
      _pendingPath = null;

      return result;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> takeNextFile() async {
    if (!isSupported) {
      return null;
    }

    initialize();

    try {
      final path =
          await _channel.invokeMethod<String>('getPendingSharedFile');

      if (path != null && path.isNotEmpty) {
        _pendingPath = null;
        return path;
      }

      final result = _pendingPath;
      _pendingPath = null;
      return result;
    } catch (_) {
      final result = _pendingPath;
      _pendingPath = null;
      return result;
    }
  }
}
