
import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import '../models/mobile_report.dart';

class ReportService {
  const ReportService();

  Future<MobileReport> report(String resource,{int? year}) async {
    try {
      final q=<String,dynamic>{};
      if(year!=null) q['year']=year;
      final r=await ApiClient.dio.get('/mobile/v1/reports/$resource',queryParameters:q);
      return MobileReport.fromJson(Map<String,dynamic>.from(r.data['data']??{}));
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }

  Future<ProjectReport> projectReport(int id) async {
    try {
      final r=await ApiClient.dio.get('/mobile/v1/projects/$id/report');
      return ProjectReport.fromJson(Map<String,dynamic>.from(r.data['data']??{}));
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }
}
