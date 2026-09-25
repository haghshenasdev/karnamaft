import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';

class ReferenceService implements RecordService<RecordItem> {
  final String resource;
  final String label;
  const ReferenceService(this.resource, {this.label = 'نام'});

  @override
  Future<PageResult<RecordItem>> list({
    int page=1,String? search,String? sort,Map<String,String>? filters,
  }) async {
    try {
      final q=<String,dynamic>{'page':page,'per_page':30};
      if(search?.trim().isNotEmpty==true) q['search']=search!.trim();
      if(sort?.isNotEmpty==true) q['sort']=sort;
      if(filters!=null) {
        for(final e in filters.entries) {
          if(e.value.isNotEmpty) q['filter[${e.key}]']=e.value;
        }
      }
      final r=await ApiClient.dio.get('/mobile/v1/$resource',queryParameters:q);
      final j=r.data as Map<String,dynamic>;
      final data=(j['data'] as List? ?? []).map((e){
        final m=e as Map<String,dynamic>;
        final title=(m['name']??m['subject']??m['title']??'#${m['id']}').toString();
        final desc=(m['description']??'').toString();
        return RecordItem(id:m['id']??0,title:title,description:desc,number:'${m['id']??''}');
      }).toList();
      final meta=j['meta'] as Map<String,dynamic>? ?? {};
      return PageResult<RecordItem>(
        data:data,currentPage:meta['current_page']??1,lastPage:meta['last_page']??1,
        total:meta['total']??data.length,perPage:meta['per_page']??data.length,
      );
    } catch(e){throw ApiErrorHandler.handle(e);}
  }

  @override List<RecordFilter> get filters => const [];
  @override Future<bool> delete(int id) => throw UnimplementedError();
}
