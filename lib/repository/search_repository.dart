import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:karnamaft/models/search_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/services/task_service.dart';

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
    ];

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
