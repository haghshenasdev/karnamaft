import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';

import '../utils/app_settings.dart';

/// Local cache and durable outbox for Karnama. It never writes directly to
/// server tables; queued mutations are only sent by the sync layer after auth.
class OfflineStore {
  OfflineStore._();

  static final OfflineStore instance = OfflineStore._();
  static const int _maxBatchRecords = 400;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;

    final rootPath = await AppSettings.getOfflineRootPath();
    final dbDir = Directory(p.join(rootPath, 'database'));
    await dbDir.create(recursive: true);

    late final DatabaseFactory factory;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      sqfliteFfiInit();
      factory = databaseFactoryFfi;
    } else {
      factory = databaseFactory;
    }

    final dbPath = p.join(dbDir.path, 'karnama_offline.sqlite');
    _db = await factory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 3,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cache_records (
              cache_key TEXT PRIMARY KEY,
              resource TEXT NOT NULL,
              record_id TEXT NOT NULL,
              payload TEXT NOT NULL,
              fetched_at TEXT NOT NULL,
              user_id TEXT NOT NULL,
              UNIQUE(resource, record_id, user_id)
            )
          ''');
          await db.execute('''
            CREATE TABLE http_cache (
              cache_key TEXT PRIMARY KEY,
              payload TEXT NOT NULL,
              saved_at TEXT NOT NULL,
              user_scope TEXT NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE outbox (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              client_mutation_id TEXT NOT NULL UNIQUE,
              method TEXT NOT NULL,
              endpoint TEXT NOT NULL,
              payload TEXT NOT NULL,
              created_at TEXT NOT NULL,
              user_id TEXT NOT NULL,
              attempts INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE sync_state (
              state_key TEXT PRIMARY KEY,
              state_value TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
          await db.execute(
            'CREATE INDEX idx_cache_resource_user '
            'ON cache_records(resource,user_id)',
          );
          await db.execute(
            'CREATE INDEX idx_outbox_user ON outbox(user_id,id)',
          );
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          if (oldVersion < 2) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS http_cache (
                cache_key TEXT PRIMARY KEY,
                payload TEXT NOT NULL,
                saved_at TEXT NOT NULL,
                user_scope TEXT NOT NULL
              )
            ''');
          }
          if (oldVersion < 3) {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS sync_state (
                state_key TEXT PRIMARY KEY,
                state_value TEXT NOT NULL,
                updated_at TEXT NOT NULL
              )
            ''');
          }
        },
      ),
    );

    return _db!;
  }


  /// Durable checkpoint for offline synchronization. A resource index is
  /// enough to resume safely; the current resource is re-fetched and existing
  /// files are reused, so interruption never requires starting from scratch.
  Future<int?> getSyncCheckpoint() async {
    final db = await database;
    final rows = await db.query('sync_state', where: 'state_key=?', whereArgs: ['offline_resource_index'], limit: 1);
    if (rows.isEmpty) return null;
    return int.tryParse(rows.first['state_value'] as String);
  }

  Future<void> saveSyncCheckpoint(int resourceIndex) async {
    final db = await database;
    await db.insert('sync_state', {
      'state_key': 'offline_resource_index',
      'state_value': resourceIndex.toString(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> clearSyncCheckpoint() async {
    final db = await database;
    await db.delete('sync_state', where: 'state_key=?', whereArgs: ['offline_resource_index']);
  }

  Future<void> cacheHttpResponse({
    required String key,
    required String userScope,
    required dynamic payload,
  }) async {
    final db = await database;
    await db.insert(
      'http_cache',
      {
        'cache_key': key,
        'payload': jsonEncode(payload),
        'saved_at': DateTime.now().toUtc().toIso8601String(),
        'user_scope': userScope,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<dynamic> readHttpResponse({
    required String key,
    required String userScope,
  }) async {
    final db = await database;
    final rows = await db.query(
      'http_cache',
      where: 'cache_key=? AND user_scope=?',
      whereArgs: [key, userScope],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    try {
      return jsonDecode(rows.first['payload'] as String);
    } catch (_) {
      return null;
    }
  }

  /// Writes records in bounded SQLite batches. This keeps large offline syncs
  /// from building a single oversized batch while preserving the existing API.
  Future<void> cacheRecords({
    required String resource,
    required String userId,
    required List<Map<String, dynamic>> records,
  }) async {
    if (records.isEmpty) return;
    final db = await database;

    for (var start = 0; start < records.length; start += _maxBatchRecords) {
      final end = (start + _maxBatchRecords < records.length)
          ? start + _maxBatchRecords
          : records.length;
      final batchRecords = records.sublist(start, end);
      final batch = db.batch();
      final now = DateTime.now().toUtc().toIso8601String();

      for (final record in batchRecords) {
        final id = (record['id'] ?? record['uuid'])?.toString();
        if (id == null || id.isEmpty) continue;

        batch.insert(
          'cache_records',
          {
            'cache_key': '$userId:$resource:$id',
            'resource': resource,
            'record_id': id,
            'payload': jsonEncode(record),
            'fetched_at': now,
            'user_id': userId,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
    }
  }

  Future<List<Map<String, dynamic>>> readCachedRecords({
    required String resource,
    required String userId,
  }) async {
    final db = await database;
    final rows = await db.query(
      'cache_records',
      where: 'resource=? AND user_id=?',
      whereArgs: [resource, userId],
      // Numeric IDs sort correctly as numbers instead of text (e.g. 100 > 99).
      // fetched_at remains a secondary key for non-numeric IDs and updates.
      orderBy: 'CAST(record_id AS INTEGER) DESC, fetched_at DESC',
    );

    return rows
        .map(
          (row) => Map<String, dynamic>.from(
            jsonDecode(row['payload']! as String) as Map,
          ),
        )
        .toList();
  }


  Future<String?> findLocalFileByUrl({required String userId, required String url}) async {
    final db = await database;
    final rows = await db.query('cache_records', columns: ['payload'], where: 'user_id=?', whereArgs: [userId]);
    for (final row in rows) {
      try {
        final payload = jsonDecode(row['payload'] as String);
        String? find(dynamic value) {
          if (value is Map) {
            final candidateUrl = (value['url'] ?? value['download_url'] ?? value['drawing_url'] ?? '').toString();
            final localPath = value['local_path']?.toString();
            if (candidateUrl == url && localPath != null && localPath.isNotEmpty) return localPath;
            for (final child in value.values) { final found = find(child); if (found != null) return found; }
          } else if (value is List) {
            for (final child in value) { final found = find(child); if (found != null) return found; }
          }
          return null;
        }
        final path = find(payload);
        if (path != null && await File(path).exists()) return path;
      } catch (_) { /* Skip a damaged cache row. */ }
    }
    return null;
  }

  Future<Map<String, dynamic>?> readCachedRecord({required String resource, required String userId, required String recordId}) async {
    final db = await database;
    final rows = await db.query('cache_records', where: 'resource=? AND user_id=? AND record_id=?', whereArgs: [resource, userId, recordId], limit: 1);
    if (rows.isEmpty) return null;
    return Map<String, dynamic>.from(jsonDecode(rows.first['payload']! as String) as Map);
  }

  Future<int> countCachedRecords({required String resource, required String userId}) async {
    final db = await database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM cache_records WHERE resource=? AND user_id=?', [resource, userId]);
    return (rows.first['total'] as int?) ?? 0;
  }

  Future<List<Map<String, dynamic>>> readCachedRecordsPage({required String resource, required String userId, required int limit, required int offset}) async {
    final db = await database;
    final rows = await db.query('cache_records', where: 'resource=? AND user_id=?', whereArgs: [resource, userId], orderBy: 'CAST(record_id AS INTEGER) DESC, fetched_at DESC', limit: limit, offset: offset);
    return rows.map((row) => Map<String, dynamic>.from(jsonDecode(row['payload']! as String) as Map)).toList();
  }

  Future<bool> isRecordOutdated({required String resource, required String userId, required Map<String,dynamic> serverRecord}) async {
    final id = (serverRecord['id'] ?? serverRecord['uuid'])?.toString();
    if (id == null || id.isEmpty) return true;
    final db = await database;
    final rows = await db.query('cache_records', columns: ['payload'], where: 'resource=? AND user_id=? AND record_id=?', whereArgs: [resource,userId,id], limit: 1);
    if (rows.isEmpty) return true;
    try {
      final old = jsonDecode(rows.first['payload'] as String) as Map<String,dynamic>;
      final newUpdated = DateTime.tryParse('${serverRecord['updated_at'] ?? serverRecord['updatedAt'] ?? ''}');
      final oldUpdated = DateTime.tryParse('${old['updated_at'] ?? old['updatedAt'] ?? ''}');
      bool hasRemoteFiles(dynamic value) {
        if (value is Map) {
          if ((value['url'] ?? value['download_url'] ?? value['drawing_url'])?.toString().isNotEmpty == true) return true;
          for (final key in ['file', 'file_path', 'file_url', 'attachment', 'attachment_url', 'document_url']) {
            if (value[key] is String && (value[key] as String).trim().isNotEmpty) return true;
          }
          return value.values.any(hasRemoteFiles);
        }
        if (value is List) return value.any(hasRemoteFiles);
        return false;
      }
      void collectLocalPaths(dynamic value, List<String> paths) {
        if (value is Map) {
          final path = value['local_path']?.toString();
          if (path != null && path.isNotEmpty) paths.add(path);
          for (final child in value.values) { collectLocalPaths(child, paths); }
        } else if (value is List) {
          for (final child in value) { collectLocalPaths(child, paths); }
        }
      }
      if (hasRemoteFiles(serverRecord) || serverRecord['has_attachment'] == true || serverRecord['has_file'] == true) {
        final paths = <String>[];
        collectLocalPaths(old, paths);
        var hasExistingLocalFile = false;
        for (final path in paths) {
          if (await File(path).exists()) { hasExistingLocalFile = true; break; }
        }
        if (!hasExistingLocalFile) return true;
      }
      if (newUpdated == null) return true;
      return oldUpdated == null || newUpdated.isAfter(oldUpdated);
    } catch (_) { return true; }
  }

  /// Reconciles a full server snapshot and removes records deleted remotely.
  /// Called only after every page of a resource has been fetched successfully.
  Future<void> removeRecordsMissingFromServer({
    required String resource,
    required String userId,
    required List<Map<String, dynamic>> serverRecords,
  }) async {
    final db = await database;
    final serverIds = serverRecords
        .map((record) => (record['id'] ?? record['uuid'])?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet();

    final localRows = await db.query(
      'cache_records',
      columns: ['record_id'],
      where: 'resource=? AND user_id=?',
      whereArgs: [resource, userId],
    );
    final staleIds = localRows
        .map((row) => row['record_id']?.toString())
        .whereType<String>()
        .where((id) => !serverIds.contains(id))
        .toList();

    for (var start = 0; start < staleIds.length; start += 400) {
      final chunk = staleIds.skip(start).take(400).toList();
      if (chunk.isEmpty) continue;
      final placeholders = List.filled(chunk.length, '?').join(',');
      await db.rawDelete(
        'DELETE FROM cache_records WHERE resource=? AND user_id=? AND record_id IN ($placeholders)',
        [resource, userId, ...chunk],
      );
    }
  }

  Future<void> enqueueMutation({
    required String mutationId,
    required String method,
    required String endpoint,
    required String userId,
    required Map<String, dynamic> payload,
  }) async {
    final db = await database;
    await db.insert(
      'outbox',
      {
        'client_mutation_id': mutationId,
        'method': method.toUpperCase(),
        'endpoint': endpoint,
        'payload': jsonEncode(payload),
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'user_id': userId,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<List<Map<String, Object?>>> pendingMutations(String userId) async {
    final db = await database;
    return db.query(
      'outbox',
      where: 'user_id=?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );
  }

  Future<void> markMutationSynced(int id) async {
    final db = await database;
    await db.delete('outbox', where: 'id=?', whereArgs: [id]);
  }

  Future<void> markMutationFailed(int id, Object error) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE outbox SET attempts=attempts+1,last_error=? WHERE id=?',
      [error.toString(), id],
    );
  }

  Future<void> clearUserCache(String userId) async {
    final db = await database;
    await db.delete(
      'cache_records',
      where: 'user_id=?',
      whereArgs: [userId],
    );
    // Do not delete the outbox: unsynced edits must not be silently lost.
  }
}
