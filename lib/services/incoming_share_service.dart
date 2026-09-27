
import 'dart:io';
import 'package:flutter/services.dart';

class IncomingShareService {
  IncomingShareService._();
  static const _channel = MethodChannel('karnama/incoming_share');
  static String? _pendingPath;

  static Future<String?> takeInitialFile() async {
    try {
      final path = await _channel.invokeMethod<String>('getInitialSharedFile');
      if (path != null && path.isNotEmpty) _pendingPath = path;
      return _pendingPath;
    } catch (_) { return null; }
  }

  static Future<String?> takeNextFile() async {
    try {
      final path = await _channel.invokeMethod<String>('getPendingSharedFile');
      if (path != null && path.isNotEmpty) {
        _pendingPath = null;
        return path;
      }
      return null;
    } catch (_) { return null; }
  }

  static bool get isSupported => Platform.isAndroid;
}
