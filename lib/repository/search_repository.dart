import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:karnamaft/models/search_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/services/task_service.dart';
import 'package:karnamaft/services/content_service.dart';
import 'package:karnamaft/models/record_item.dart';
import '../offline/offline_store.dart';
import '../offline/offline_sync_service.dart';
import '../utils/app_settings.dart';
import 'dart:convert';

class SearchRepository {
  static Future<List<SearchItem>> search({
    required String keyword,
    SearchType? filter,
    required Map<SearchType, bool> hasMore,
    Map<SearchType, int>? pages,
    CancelToken? cancelToken,
  }) async {
    final List<SearchItem> results = [];

    final List<(SearchType, RecordService<dynamic>)> sources = [
      (SearchType.letter, const LetterService()),
      (SearchType.meeting, const MinuteService()),
      (SearchType.activity, const TaskService()),
      (SearchType.agenda, const ProjectService()),
      (SearchType.note, const ContentService()),
    ];

    if (await AppSettings.getOfflineEnabled()) {
      final userId = await OfflineSyncService.currentUserScope();
      const resources = <(SearchType, String)>[
        (SearchType.letter, 'letters'),
        (SearchType.meeting, 'minutes'),
        (SearchType.activity, 'tasks'),
        (SearchType.agenda, 'projects'),
        (SearchType.note, 'contents'),
      ];
      final selectedResources = resources.where((r) => filter == null || filter == r.$1);
      for (final entry in selectedResources) {
        final cached = await OfflineStore.instance.readCachedRecords(
          resource: entry.$2, userId: userId,
        );
        final matched = cached.where((row) => jsonEncode(row).toLowerCase().contains(keyword.trim().toLowerCase())).toList();
        matched.sort((a, b) => (int.tryParse('${b['id'] ?? 0}') ?? 0)
            .compareTo(int.tryParse('${a['id'] ?? 0}') ?? 0));
        const pageSize = 30;
        final page = pages?[entry.$1] ?? 1;
        final start = (page - 1) * pageSize;
        final pageRows = matched.skip(start).take(pageSize);
        hasMore[entry.$1] = matched.length > start + pageSize;
        for (final row in pageRows) {
          final record = _recordFromOffline(row);
          if (record != null) results.add(SearchItem.fromRecord(record, entry.$1));
        }
      }
      results.sort((a, b) => b.id.compareTo(a.id));
      return results;
    }

    final selected = sources.where(
      (source) => filter == null || filter == source.$1,
    );

    // چهار منبع را موازی می‌خوانیم؛ جستجوی قبلی نیز در SearchPage لغو می‌شود.
    final futures = selected.map((source) async {
      try {
        final response = await source.$2.list(
          page: pages?[source.$1] ?? 1,
          sort: "-id",
          search: keyword.trim(),
          filters: const {},
        );

        hasMore[source.$1] = response.hasNextPage;

        return response.data
            .map((record) => SearchItem.fromRecord(record, source.$1))
            .toList();
      } catch (e) {
        if (e is DioException && CancelToken.isCancel(e)) rethrow;

        debugPrint("SEARCH ${source.$1} ERROR: $e");
        hasMore[source.$1] = false;
        return <SearchItem>[];
      }
    });

    final batches = await Future.wait(futures);

    for (final batch in batches) {
      results.addAll(batch);
    }

    results.sort((a, b) => b.id.compareTo(a.id));

    return results;
  }

  static RecordItem? _recordFromOffline(Map<String, dynamic> row) {
    final id = int.tryParse('${row['id'] ?? row['uuid'] ?? ''}');
    if (id == null) return null;
    final organ = row['organ'] is Map ? Map<String, dynamic>.from(row['organ']) : null;
    final customers = row['customers'] is List ? row['customers'] as List : const [];
    final customer = customers.isNotEmpty && customers.first is Map
        ? Map<String, dynamic>.from(customers.first as Map)
        : null;
    final body = row['body'] is List ? row['body'] as List : const [];
    final bodyText = body.whereType<Map>()
        .where((part) => part['type'] == 'text')
        .map((part) => part['text']?.toString() ?? '')
        .where((text) => text.isNotEmpty).join('\n');
    return RecordItem(
      id: id,
      title: '${row['title'] ?? row['subject'] ?? row['name'] ?? 'بدون عنوان'}',
      description: row['description']?.toString() ?? row['summary']?.toString() ?? row['text']?.toString() ?? bodyText,
      from: row['from']?.toString() ?? organ?['name']?.toString(),
      to: row['to']?.toString() ?? customer?['name']?.toString(),
      number: row['number']?.toString() ?? row['letter_number']?.toString() ?? id.toString(),
      date: DateTime.tryParse('${row['date'] ?? row['created_at'] ?? ''}'),
      tag: row['tag']?.toString(),
      status: RecordStatusExtension.fromValue(int.tryParse('${row['status'] ?? ''}')),
      hasAttachment: row['has_attachment'] == true || row['file'] != null ||
          (row['files'] is List && (row['files'] as List).isNotEmpty) ||
          body.any((part) => part is Map && (part['file'] != null || part['drawing'] != null)),
    );
  }

  static Map<SearchType, List<SearchItem>> groupByType(
    List<SearchItem> items,
  ) {
    final Map<SearchType, List<SearchItem>> groups = {};

    for (final item in items) {
      groups.putIfAbsent(item.type, () => []);
      groups[item.type]!.add(item);
    }

    return groups;
  }
}
