
import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import '../models/project_children.dart';

class ProjectChildrenService {
  const ProjectChildrenService();
  Future<ProjectChildPage<ProjectChildLetter>> letters(int id,{int page=1})=>_get(id,'letters',page,(e)=>ProjectChildLetter.fromJson(e));
  Future<ProjectChildPage<ProjectChildTask>> tasks(int id,{int page=1})=>_get(id,'tasks',page,(e)=>ProjectChildTask.fromJson(e));
  Future<ProjectChildPage<ProjectChildMinute>> minutes(int id,{int page=1})=>_get(id,'minutes',page,(e)=>ProjectChildMinute.fromJson(e));
  Future<ProjectChildPage<ProjectChildApprove>> approves(int id,{int page=1})=>_get(id,'approves',page,(e)=>ProjectChildApprove.fromJson(e));

  Future<ProjectChildPage<T>> _get<T>(int id,String type,int page,T Function(Map<String,dynamic>) map) async {
    try {
      final r=await ApiClient.dio.get('/mobile/v1/projects/$id/children',queryParameters:{'type':type,'page':page,'per_page':10});
      final j=Map<String,dynamic>.from(r.data);
      final meta=Map<String,dynamic>.from(j['meta']??{});
      return ProjectChildPage(
        data:(j['data'] as List? ?? []).whereType<Map>().map((e)=>map(Map<String,dynamic>.from(e))).toList(),
        currentPage:meta['current_page']??1,lastPage:meta['last_page']??1,total:meta['total']??0,
      );
    } catch(e){throw ApiErrorHandler.handle(e);}
  }
}
