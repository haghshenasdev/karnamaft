import 'package:karnamaft/api/api_client.dart';
import 'package:karnamaft/api/api_error_handler.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/models/page_result.dart';
import 'package:karnamaft/models/record_filter.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/RecordService.dart';
class ContentGroupService implements RecordService<ContentGroupModel>{const ContentGroupService();final rootPath='/mobile/v1/content-groups';@override List<RecordFilter> get filters=>[];@override Future<PageResult<RecordItem>> list({int page=1,String? search,String? sort,Map<String,String>? filters})async{try{final q=<String,dynamic>{'page':page,'per_page':50};if(search?.isNotEmpty==true)q['search']=search;final r=await ApiClient.dio.get(rootPath,queryParameters:q);final data=(r.data['data'] as List? ?? []).map((e)=>ContentGroupModel.fromJson(Map<String,dynamic>.from(e))).toList();final m=Map<String,dynamic>.from(r.data['meta']??{});return PageResult(data:data.map((e)=>RecordItem(id:e.id,title:e.name)).toList(),currentPage:m['current_page']??1,lastPage:m['last_page']??1,total:m['total']??data.length,perPage:m['per_page']??data.length);}catch(e){throw ApiErrorHandler.handle(e);}}@override Future<bool> delete(int id)=>throw UnimplementedError();}
