
import 'record_file.dart';

class ProjectChildPage<T> {
  final List<T> data;
  final int currentPage;
  final int lastPage;
  final int total;

  const ProjectChildPage({
    required this.data,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });

  bool get hasMore => currentPage < lastPage;
}

class ProjectChildLetter {
  final int id;
  final String title;
  final String? description;
  final DateTime? createdAt;
  final List<RecordFile> files;

  const ProjectChildLetter({
    required this.id,
    required this.title,
    this.description,
    this.createdAt,
    this.files = const [],
  });

  factory ProjectChildLetter.fromJson(Map<String,dynamic> j) => ProjectChildLetter(
    id: j['id'] ?? 0,
    title: j['title']?.toString() ?? '',
    description: j['description']?.toString(),
    createdAt: j['created_at'] == null ? null : DateTime.tryParse(j['created_at'].toString()),
    files: (j['files'] as List? ?? []).whereType<Map>().map((e)=>RecordFile.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}

class ProjectChildTask {
  final int id;
  final String title;
  final String? description;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool completed;
  final int? progress;
  final String statusTitle;
  final String? responsibleName;
  final String? cityName;
  final int? minuteId;
  final String? minuteTitle;
  final List<RecordFile> files;

  const ProjectChildTask({
    required this.id, required this.title, this.description, this.startedAt,
    this.endedAt, this.completed=false, this.progress, this.statusTitle='',
    this.responsibleName, this.cityName, this.minuteId, this.minuteTitle,
    this.files=const [],
  });

  factory ProjectChildTask.fromJson(Map<String,dynamic> j) {
    final m=j['minutes'];
    return ProjectChildTask(
      id:j['id']??0,
      title:j['title']?.toString()??'',
      description:j['description']?.toString(),
      startedAt:j['started_at']==null?null:DateTime.tryParse(j['started_at'].toString()),
      endedAt:j['ended_at']==null?null:DateTime.tryParse(j['ended_at'].toString()),
      completed:j['completed']==true||j['completed']==1,
      progress:j['progress'] is int?j['progress']:int.tryParse('${j['progress']}'),
      statusTitle:j['status_title']?.toString()??'',
      responsibleName:j['responsible'] is Map ? Map<String,dynamic>.from(j['responsible'])['name']?.toString() : null,
      cityName:j['city']?['name']?.toString(),
      minuteId:m is Map ? (m['id'] is int ? m['id'] : int.tryParse('${m['id']}')) : null,
      minuteTitle:m is Map ? m['title']?.toString() : null,
      files:(j['files'] as List? ?? []).whereType<Map>().map((e)=>RecordFile.fromJson(Map<String,dynamic>.from(e))).toList(),
    );
  }
}

class ProjectChildMinute {
  final int id;
  final String title;
  final String? text;
  final DateTime? date;
  final List<RecordFile> files;

  const ProjectChildMinute({required this.id,required this.title,this.text,this.date,this.files=const[]});

  factory ProjectChildMinute.fromJson(Map<String,dynamic> j)=>ProjectChildMinute(
    id:j['id']??0,title:j['title']?.toString()??'',text:j['text']?.toString(),
    date:j['date']==null?null:DateTime.tryParse(j['date'].toString()),
    files:(j['files'] as List? ?? []).whereType<Map>().map((e)=>RecordFile.fromJson(Map<String,dynamic>.from(e))).toList(),
  );
}

class ProjectChildApprove {
  final int id; final String title; final String? description; final String? status;
  const ProjectChildApprove({required this.id,required this.title,this.description,this.status});
  factory ProjectChildApprove.fromJson(Map<String,dynamic> j)=>ProjectChildApprove(id:j['id']??0,title:(j['title']??j['name']??'مصوبه').toString(),description:j['description']?.toString(),status:j['status']?.toString());
}
