import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_item.dart';

abstract class RecordService<T> {
  Future<PageResult<RecordItem>> list({
    int page = 1,
    String? sort,
    Map<String, String>? filters,
  });

  Future<bool> delete(int id);
}