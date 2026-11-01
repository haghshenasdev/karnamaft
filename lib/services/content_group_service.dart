import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
import '../offline/offline_store.dart';
import '../offline/offline_sync_service.dart';
import '../utils/app_settings.dart';

class ContentGroupService implements RecordService<ContentGroupModel> {
  const ContentGroupService();
  final rootPath = '/mobile/v1/content-groups';
  @override
  List<RecordFilter> get filters => [];

  Future<List<ContentGroupModel>> allGroups() async {
    try {
      if (await AppSettings.getOfflineEnabled()) {
        final cached = await OfflineStore.instance.readCachedRecords(
          resource: 'content-groups',
          userId: await OfflineSyncService.currentUserScope(),
        );
        return cached.map(ContentGroupModel.fromJson).toList();
      }
      final all = <ContentGroupModel>[];
      var page = 1;
      var last = 1;
      do {
        final r = await ApiClient.dio.get(rootPath, queryParameters: {'page': page, 'per_page': 100});
        final rows = (r.data['data'] as List? ?? []);
        all.addAll(rows.map((e) => ContentGroupModel.fromJson(Map<String, dynamic>.from(e))));
        final meta = Map<String, dynamic>.from(r.data['meta'] ?? {});
        last = meta['last_page'] ?? 1;
        page++;
      } while (page <= last && page <= 100);
      return all;
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }


  /// دریافت یک سطح از درخت؛ parentId=null یعنی فقط دسته‌های اصلی.
  Future<List<ContentGroupModel>> children({int? parentId, String? search}) async {
    try {
      if (await AppSettings.getOfflineEnabled()) {
        final cached = await OfflineStore.instance.readCachedRecords(
          resource: 'content-groups',
          userId: await OfflineSyncService.currentUserScope(),
        );
        final query = search?.trim().toLowerCase() ?? '';
        return cached
            .where((row) => parentId == null
                ? row['parent_id'] == null
                : '${row['parent_id'] ?? ''}' == '$parentId')
            .where((row) => query.isEmpty || '${row['id']} ${row['name']}'.toLowerCase().contains(query))
            .map(ContentGroupModel.fromJson)
            .toList();
      }
      final params = <String, dynamic>{'per_page': 100};
      // ریشه‌ها را با پارامتر صریح می‌گیریم تا خالی بودن parent_id توسط Dio حذف/تفسیر نشود.
      if (parentId == null) {
        params['root_only'] = 1;
      } else {
        params['parent_id'] = parentId;
      }
      if (search != null && search.trim().isNotEmpty) params['search'] = search.trim();
      final response = await ApiClient.dio.get(rootPath, queryParameters: params);
      final rows = (response.data['data'] as List? ?? const []);
      return rows.map((e) => ContentGroupModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<List<ContentGroupModel>> searchGroups(String search) async {
    try {
      if (await AppSettings.getOfflineEnabled()) {
        final cached = await OfflineStore.instance.readCachedRecords(
          resource: 'content-groups',
          userId: await OfflineSyncService.currentUserScope(),
        );
        final query = search.trim().toLowerCase();
        return cached
            .where((row) => '${row['id']} ${row['name']}'.toLowerCase().contains(query))
            .map(ContentGroupModel.fromJson)
            .toList();
      }
      final response = await ApiClient.dio.get(rootPath, queryParameters: {'search': search, 'per_page': 100});
      final rows = (response.data['data'] as List? ?? const []);
      return rows.map((e) => ContentGroupModel.fromJson(Map<String, dynamic>.from(e))).toList();
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  Future<ContentGroupModel> createGroup({required String name, int? parentId}) async {
    try {
      final response = await ApiClient.dio.post(rootPath, data: {
        'name': name.trim(),
        'parent_id': parentId,
      });
      return ContentGroupModel.fromJson(Map<String, dynamic>.from(response.data['data']));
    } catch (e) {
      throw ApiErrorHandler.handle(e);
    }
  }

  @override
  Future<PageResult<RecordItem>> list({int page=1, String? search, String? sort, Map<String,String>? filters}) async {
    try {
      final q = <String,dynamic>{'page':page,'per_page':100};
      if (search?.isNotEmpty == true) q['search'] = search;
      final r = await ApiClient.dio.get(rootPath, queryParameters:q);
      final data = (r.data['data'] as List? ?? []).map((e) => ContentGroupModel.fromJson(Map<String,dynamic>.from(e))).toList();
      final m = Map<String,dynamic>.from(r.data['meta'] ?? {});
      return PageResult(data:data.map((e)=>RecordItem(id:e.id,title:e.name)).toList(),currentPage:m['current_page']??1,lastPage:m['last_page']??1,total:m['total']??data.length,perPage:m['per_page']??data.length);
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }
  @override
  Future<bool> delete(int id) => throw UnimplementedError();
}
