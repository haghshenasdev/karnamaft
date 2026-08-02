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
  }) async {
    final List<SearchItem> results = [];

    final List<(SearchType, RecordService<dynamic>)> sources = [
      (SearchType.letter, const LetterService()),

      (SearchType.meeting, const MinuteService()),

      (SearchType.activity, const TaskService()),

      (SearchType.agenda, const ProjectService()),
    ];

    for (final source in sources) {
      if (filter != null && filter != source.$1) {
        continue;
      }

      final Map<String, String> filters = {};

      if (keyword.trim().isNotEmpty) {
        filters["search"] = keyword.trim();
      }

      final response = await source.$2.list(
        page: 1,
        sort: "-id",
        filters: filters,
      );

      results.addAll(
        response.data.map((record) => SearchItem.fromRecord(record, source.$1)),
      );
    }

    results.sort((a, b) {
      return b.id.compareTo(a.id);
    });

    return results;
  }

  static Map<SearchType, List<SearchItem>> groupByType(List<SearchItem> items) {
    final Map<SearchType, List<SearchItem>> groups = {};

    for (final item in items) {
      groups.putIfAbsent(item.type, () => []);

      groups[item.type]!.add(item);
    }

    return groups;
  }
}
