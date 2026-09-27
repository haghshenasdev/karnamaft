
import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import '../models/mobile_report.dart';

class CalendarService {
  const CalendarService();
  Future<CalendarData> month(int year,int month) async {
    try {
      final r=await ApiClient.dio.get('/mobile/v1/calendar/tasks',queryParameters:{'year':year,'month':month});
      return CalendarData.fromJson(Map<String,dynamic>.from(r.data['data']??{}));
    } catch(e) { throw ApiErrorHandler.handle(e); }
  }
}
class CalendarData {
  final int year,month,days; final String monthName; final List<CalendarEvent> events;
  const CalendarData({required this.year,required this.month,required this.days,required this.monthName,required this.events});
  factory CalendarData.fromJson(Map<String,dynamic> j)=>CalendarData(
    year:j['year']??1405,month:j['month']??1,days:j['days']??31,monthName:j['month_name']?.toString()??'',
    events:(j['events'] as List? ?? []).whereType<Map>().map((e)=>CalendarEvent.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
