import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../models/note_page.dart';

class AutoSaveInfo {
  final String id;
  final String fileName;
  final String title;
  final DateTime updatedAt;

  AutoSaveInfo({
    required this.id,
    required this.fileName,
    required this.title,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'title': title,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory AutoSaveInfo.fromJson(Map<String, dynamic> json) {
    return AutoSaveInfo(
      id: json['id'],
      fileName: json['fileName'],
      title: json['title'] ?? '',
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

class AutoSaveData {
  final String id;
  final String title;
  final DateTime updatedAt;
  final int currentPage;
  final List<NotePage> pages;

  AutoSaveData({
    required this.id,
    required this.title,
    required this.updatedAt,
    required this.currentPage,
    required this.pages,
  });
}

class NoteAutoSaveService {
  static const int maxFiles = 3;

  Directory? _directory;

  Future<Directory> get _autoSaveDirectory async {
    if (_directory != null) {
      return _directory!;
    }

    final base = await getApplicationDocumentsDirectory();

    final directory = Directory(
      '${base.path}${Platform.pathSeparator}AutoSave',
    );

    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }

    _directory = directory;

    return directory;
  }

  String _sanitizeFileName(String value) {
    var result = value.trim();

    if (result.isEmpty) {
      result = 'یادداشت';
    }

    result = result.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_');

    if (result.length > 80) {
      result = result.substring(0, 80);
    }

    return result;
  }

  Future<File> _getFile(String fileName) async {
    final directory = await _autoSaveDirectory;

    return File('${directory.path}${Platform.pathSeparator}$fileName');
  }

  Future<File> _getIndexFile() async {
    final directory = await _autoSaveDirectory;

    return File('${directory.path}${Platform.pathSeparator}index.json');
  }

  // --------------------------------------------------
  // Save
  // --------------------------------------------------

  Future<AutoSaveInfo> save({
    required String id,
    required String title,
    required List<NotePage> pages,
    required int currentPage,
  }) async {
    final now = DateTime.now();

    final safeTitle = _sanitizeFileName(title);

    final fileName = 'note_$id.json';

    final file = await _getFile(fileName);

    final data = {
      'id': id,
      'title': title,
      'updatedAt': now.toIso8601String(),
      'currentPage': currentPage,
      'pages': pages.map((page) => page.toJson()).toList(),
    };

    await file.writeAsString(jsonEncode(data), flush: true);

    final info = AutoSaveInfo(
      id: id,
      fileName: fileName,
      title: title.isEmpty ? safeTitle : title,
      updatedAt: now,
    );

    await _updateIndex(info);

    await _removeOldFiles();

    return info;
  }

  // --------------------------------------------------
  // Index
  // --------------------------------------------------

  Future<List<AutoSaveInfo>> getHistory() async {
    final file = await _getIndexFile();

    if (!await file.exists()) {
      return [];
    }

    try {
      final content = await file.readAsString();

      final list = jsonDecode(content) as List;

      final result = list
          .map((item) => AutoSaveInfo.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      result.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

      return result;
    } catch (_) {
      return [];
    }
  }

  Future<void> _updateIndex(AutoSaveInfo info) async {
    final history = await getHistory();

    history.removeWhere((item) => item.id == info.id);

    history.add(info);

    history.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    final limited = history.take(maxFiles).toList();

    final file = await _getIndexFile();

    await file.writeAsString(
      jsonEncode(limited.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }

  // --------------------------------------------------
  // Load
  // --------------------------------------------------

  Future<AutoSaveData?> load(String id) async {
    final history = await getHistory();

    final info = history.cast<AutoSaveInfo?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );

    if (info == null) {
      return null;
    }

    final file = await _getFile(info.fileName);

    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();

      final json = jsonDecode(content);

      return AutoSaveData(
        id: json['id'],
        title: json['title'] ?? '',
        updatedAt: DateTime.parse(json['updatedAt']),
        currentPage: (json['currentPage'] ?? 0) as int,
        pages: (json['pages'] as List)
            .map((page) => NotePage.fromJson(Map<String, dynamic>.from(page)))
            .toList(),
      );
    } catch (_) {
      return null;
    }
  }

  // --------------------------------------------------
  // Latest
  // --------------------------------------------------

  Future<AutoSaveData?> loadLatest() async {
    final history = await getHistory();

    if (history.isEmpty) {
      return null;
    }

    return load(history.first.id);
  }

  // --------------------------------------------------
  // Delete
  // --------------------------------------------------

  Future<void> delete(String id) async {
    final history = await getHistory();

    final info = history.cast<AutoSaveInfo?>().firstWhere(
      (item) => item?.id == id,
      orElse: () => null,
    );

    if (info != null) {
      final file = await _getFile(info.fileName);

      if (await file.exists()) {
        await file.delete();
      }
    }

    history.removeWhere((item) => item.id == id);

    final index = await _getIndexFile();

    await index.writeAsString(
      jsonEncode(history.map((item) => item.toJson()).toList()),
      flush: true,
    );
  }

  // --------------------------------------------------
  // Maximum 3 files
  // --------------------------------------------------

  Future<void> _removeOldFiles() async {
    final history = await getHistory();

    if (history.length <= maxFiles) {
      return;
    }

    final oldItems = history.skip(maxFiles);

    for (final item in oldItems) {
      final file = await _getFile(item.fileName);

      if (await file.exists()) {
        await file.delete();
      }
    }

    final index = await _getIndexFile();

    await index.writeAsString(
      jsonEncode(history.take(maxFiles).map((item) => item.toJson()).toList()),
      flush: true,
    );
  }
}
