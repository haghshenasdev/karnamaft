int _toInt(dynamic value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _toNullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}


class MobileReport {
  final String resource;
  final int? year;
  final int total;
  final int? completed;
  final List<ReportStatus> status;
  final List<ReportMonth> monthly;
  final List<ReportGroup> groups;
  final int onTime;
  final int delayed;
  final List<ReportCity> cities;
  final List<ReportGantt> gantt;

  const MobileReport({
    required this.resource, this.year, required this.total,
    this.completed, this.status=const[], this.monthly=const[], this.groups=const[], this.onTime=0, this.delayed=0, this.cities=const[], this.gantt=const[],
  });

  factory MobileReport.fromJson(Map<String,dynamic> j)=>MobileReport(
    resource:j['resource']?.toString()??'',
    year:j['year'] is int?j['year']:int.tryParse('${j['year']}'),
    total:j['total'] is int?j['total']:int.tryParse('${j['total']}')??0,
    completed:j['completed'] is int?j['completed']:int.tryParse('${j['completed']}'),
    status:(j['status'] as List? ?? []).whereType<Map>().map((e)=>ReportStatus.fromJson(Map<String,dynamic>.from(e))).toList(),
    monthly:(j['monthly'] as List? ?? []).whereType<Map>().map((e)=>ReportMonth.fromJson(Map<String,dynamic>.from(e))).toList(),
    groups:(j['groups'] as List? ?? []).whereType<Map>().map((e)=>ReportGroup.fromJson(Map<String,dynamic>.from(e))).toList(),
    onTime:(j['delay']?['on_time'] is int)?j['delay']['on_time']:int.tryParse('${j['delay']?['on_time']}')??0,
    delayed:(j['delay']?['delayed'] is int)?j['delay']['delayed']:int.tryParse('${j['delay']?['delayed']}')??0,
    cities:(j['cities'] as List? ?? []).whereType<Map>().map((e)=>ReportCity.fromJson(Map<String,dynamic>.from(e))).toList(),
    gantt:(j['gantt'] as List? ?? []).whereType<Map>().map((e)=>ReportGantt.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}
class ReportStatus {
  final String label; final int count;
  const ReportStatus({required this.label,required this.count});
  factory ReportStatus.fromJson(Map<String,dynamic> j)=>ReportStatus(label:j['label']?.toString()??'',count:j['count'] is int?j['count']:int.tryParse('${j['count']}')??0);
}
class ReportMonth {
  final int month; final String name; final int count; final int completed;
  const ReportMonth({required this.month,required this.name,required this.count,this.completed=0});
  factory ReportMonth.fromJson(Map<String,dynamic> j)=>ReportMonth(month:j['month']??0,name:j['name']?.toString()??'',count:j['count'] is int?j['count']:int.tryParse('${j['count']}')??0,completed:j['completed'] is int?j['completed']:int.tryParse('${j['completed']}')??0);
}
class ReportGroup {
  final int? id; final String name; final int count;
  const ReportGroup({this.id,required this.name,required this.count});
  factory ReportGroup.fromJson(Map<String,dynamic> j)=>ReportGroup(id:j['id'] is int?j['id']:int.tryParse('${j['id']}'),name:j['name']?.toString()??'',count:j['count'] is int?j['count']:int.tryParse('${j['count']}')??0);
}

class ProjectReport {
  final String name; final int tasksTotal,tasksCompleted,tasksOpen,lettersTotal,minutesTotal,onTime,delayed;
  final List<ReportMonth> monthly; final List<ProjectCityStat> cities;
  const ProjectReport({required this.name,required this.tasksTotal,required this.tasksCompleted,required this.tasksOpen,required this.lettersTotal,required this.minutesTotal,required this.onTime,required this.delayed,required this.monthly,required this.cities});
  factory ProjectReport.fromJson(Map<String,dynamic> j){
    final p=Map<String,dynamic>.from(j['project']??{});
    final s=Map<String,dynamic>.from(j['stats']??{});
    return ProjectReport(
      name:p['name']?.toString()??'',
      tasksTotal:s['tasks_total']??0,tasksCompleted:s['tasks_completed']??0,tasksOpen:s['tasks_open']??0,
      lettersTotal:s['letters_total']??0,minutesTotal:s['minutes_total']??0,onTime:s['on_time']??0,delayed:s['delayed']??0,
      monthly:(j['monthly_tasks'] as List? ?? []).whereType<Map>().map((e)=>ReportMonth.fromJson(Map<String,dynamic>.from(e))).toList(),
      cities:(j['cities'] as List? ?? []).whereType<Map>().map((e)=>ProjectCityStat.fromJson(Map<String,dynamic>.from(e))).toList(),
    );
  }
}
class ProjectCityStat { final String name; final int total,completed; const ProjectCityStat({required this.name,required this.total,required this.completed}); factory ProjectCityStat.fromJson(Map<String,dynamic> j)=>ProjectCityStat(name:j['name']?.toString() ?? j['label']?.toString() ?? 'بدون شهر',total:_toInt(j['total']),completed:_toInt(j['completed'])); }
class CalendarEvent {
  final int id;
  final String type;
  final String typeTitle;
  final String title;
  final DateTime? date;
  final bool completed;
  final int? progress;
  final String? city;

  const CalendarEvent({
    required this.id,
    required this.type,
    required this.typeTitle,
    required this.title,
    this.date,
    this.completed = false,
    this.progress,
    this.city,
  });

  factory CalendarEvent.fromJson(Map<String, dynamic> json) {
    final cityValue = json['city'];

    String? cityName;
    if (cityValue is Map) {
      cityName = cityValue['name']?.toString();
    } else if (cityValue != null) {
      cityName = cityValue.toString();
    }

    return CalendarEvent(
      id: _toInt(json['id']),
      type: json['type']?.toString() ?? 'task',
      typeTitle: json['type_title']?.toString() ?? 'فعالیت',
      title: json['title']?.toString() ?? '',
      date: json['date'] == null
          ? null
          : DateTime.tryParse(json['date'].toString()),
      completed: json['completed'] == true || json['completed'] == 1,
      progress: _toNullableInt(json['progress']),
      city: cityName,
    );
  }
}

class ReportCity {
  final String name; final int total; final int completed;
  const ReportCity({required this.name,required this.total,required this.completed});
  factory ReportCity.fromJson(Map<String,dynamic> j)=>ReportCity(name:j['name']?.toString()??'',total:j['total']??0,completed:j['completed']??0);
}
class ReportGantt {
  final int id; final String name; final DateTime? startedAt,endedAt; final int days;
  const ReportGantt({required this.id,required this.name,this.startedAt,this.endedAt,this.days=0});
  factory ReportGantt.fromJson(Map<String,dynamic> j)=>ReportGantt(id:j['id']??0,name:j['name']?.toString()??'',startedAt:j['started_at']==null?null:DateTime.tryParse(j['started_at'].toString()),endedAt:j['ended_at']==null?null:DateTime.tryParse(j['ended_at'].toString()),days:j['days']??0);
}
