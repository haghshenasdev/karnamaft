import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

class IncomingShareService {
  IncomingShareService._();

  static const MethodChannel _channel =
      MethodChannel('karnama/incoming_share');

  static final StreamController<List<String>> _controller =
      StreamController<List<String>>.broadcast();

  static List<String>? _pendingPaths;
  static bool _initialized = false;

  static Stream<List<String>> get sharedFiles => _controller.stream;

  static bool get isSupported => Platform.isAndroid;

  static void initialize() {
    if (!isSupported || _initialized) return;

    _initialized = true;

    _channel.setMethodCallHandler((call) async {
      if (call.method != 'sharedFilesReceived' &&
          call.method != 'sharedFileReceived') {
        return;
      }

      final paths = _parsePaths(call.arguments);
      if (paths.isEmpty) return;

      _pendingPaths = paths;
      if (!_controller.isClosed) {
        _controller.add(paths);
      }
    });
  }

  static Future<List<String>?> takeInitialFiles() async {
    if (!isSupported) return null;

    initialize();

    try {
      dynamic result;
      try {
        result = await _channel.invokeMethod('getInitialSharedFiles');
      } on MissingPluginException {
        result = await _channel.invokeMethod('getInitialSharedFile');
      }

      final paths = _parsePaths(result);
      if (paths.isNotEmpty) _pendingPaths = paths;

      final answer = _pendingPaths;
      _pendingPaths = null;
      return answer;
    } catch (_) {
      final answer = _pendingPaths;
      _pendingPaths = null;
      return answer;
    }
  }

  // سازگاری با کدهای قدیمی که فقط یک فایل انتظار داشتند.
  static Future<String?> takeInitialFile() async {
    final files = await takeInitialFiles();
    return files == null || files.isEmpty ? null : files.first;
  }

  static Future<List<String>?> takeNextFiles() async {
    if (!isSupported) return null;

    initialize();

    try {
      dynamic result;
      try {
        result = await _channel.invokeMethod('getPendingSharedFiles');
      } on MissingPluginException {
        result = await _channel.invokeMethod('getPendingSharedFile');
      }

      final paths = _parsePaths(result);
      if (paths.isNotEmpty) {
        _pendingPaths = null;
        return paths;
      }

      final answer = _pendingPaths;
      _pendingPaths = null;
      return answer;
    } catch (_) {
      final answer = _pendingPaths;
      _pendingPaths = null;
      return answer;
    }
  }

  static Future<String?> takeNextFile() async {
    final files = await takeNextFiles();
    return files == null || files.isEmpty ? null : files.first;
  }

  static List<String> _parsePaths(dynamic value) {
    if (value == null) return const [];

    if (value is String) {
      final path = value.trim();
      return path.isEmpty ? const [] : [path];
    }

    if (value is List) {
      return value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
    }

    return const [];
  }
}
