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
      version: 2,
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
      },
    ),
  );

  return _db!;
}

  Future<void> cacheHttpResponse({
    required String key,
    required String userScope,
    required dynamic payload,
  }) async {
    final db = await database;
    await db.insert('http_cache', {
      'cache_key': key,
      'payload': jsonEncode(payload),
      'saved_at': DateTime.now().toUtc().toIso8601String(),
      'user_scope': userScope,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
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

  Future<void> cacheRecords({required String resource, required String userId, required List<Map<String, dynamic>> records}) async {
    final db = await database;
    final batch = db.batch();
    final now = DateTime.now().toUtc().toIso8601String();
    for (final record in records) {
      final id = (record['id'] ?? record['uuid'])?.toString();
      if (id == null || id.isEmpty) continue;
      batch.insert('cache_records', {
        'cache_key': '$userId:$resource:$id', 'resource': resource,
        'record_id': id, 'payload': jsonEncode(record), 'fetched_at': now,
        'user_id': userId,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> readCachedRecords({required String resource, required String userId}) async {
    final db = await database;
    final rows = await db.query('cache_records', where: 'resource=? AND user_id=?', whereArgs: [resource, userId], orderBy: 'fetched_at DESC');
    return rows.map((r) => Map<String, dynamic>.from(jsonDecode(r['payload']! as String) as Map)).toList();
  }

  Future<void> enqueueMutation({required String mutationId, required String method, required String endpoint, required String userId, required Map<String, dynamic> payload}) async {
    final db = await database;
    await db.insert('outbox', {
      'client_mutation_id': mutationId, 'method': method.toUpperCase(),
      'endpoint': endpoint, 'payload': jsonEncode(payload),
      'created_at': DateTime.now().toUtc().toIso8601String(), 'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<List<Map<String, Object?>>> pendingMutations(String userId) async {
    final db = await database;
    return db.query('outbox', where: 'user_id=?', whereArgs: [userId], orderBy: 'id ASC');
  }

  Future<void> markMutationSynced(int id) async {
    final db = await database;
    await db.delete('outbox', where: 'id=?', whereArgs: [id]);
  }

  Future<void> markMutationFailed(int id, Object error) async {
    final db = await database;
    await db.rawUpdate('UPDATE outbox SET attempts=attempts+1,last_error=? WHERE id=?', [error.toString(), id]);
  }

  Future<void> clearUserCache(String userId) async {
    final db = await database;
    await db.delete('cache_records', where: 'user_id=?', whereArgs: [userId]);
    // Do not delete the outbox: unsynced edits must not be silently lost.
  }
}
