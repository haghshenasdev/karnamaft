import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';

abstract class RecordService<T> {
  List<RecordFilter> get filters;

  Future<PageResult<RecordItem>> list({
    int page = 1,

    String? search,

    String? sort,

    Map<String, String>? filters,
  });

  Future<bool> delete(int id);
}
