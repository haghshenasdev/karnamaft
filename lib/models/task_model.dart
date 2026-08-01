import 'package:karnamaft/models/record_item.dart';

class TaskModel {
  final int id;

  final String name;
  final String? description;

  final int? status;
  final int? progress;
  final int? completed;

  final String? startedAt;
  final String? endedAt;
  final String? completedAt;

  final double? amount;
  final int? repeat;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final TaskOrgan? organ;
  final TaskCity? city;

  final TaskUser? creator;
  final TaskUser? responsible;

  final TaskMinutes? minutes;

  final List<TaskProject> projects;
  final List<TaskGroup> taskGroups;

  final List<dynamic> appendixOthers;

  const TaskModel({
    required this.id,
    required this.name,
    this.description,
    this.status,
    this.progress,
    this.completed,
    this.startedAt,
    this.endedAt,
    this.completedAt,
    this.amount,
    this.repeat,
    this.createdAt,
    this.updatedAt,
    this.organ,
    this.city,
    this.creator,
    this.responsible,
    this.minutes,
    required this.projects,
    required this.taskGroups,
    required this.appendixOthers,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json["id"] ?? 0,

      name: json["name"] ?? "",

      description: json["description"]?.toString(),

      status: json["status"],

      progress: json["progress"],

      completed: json["completed"],

      startedAt: json["started_at"]?.toString(),

      endedAt: json["ended_at"]?.toString(),

      completedAt: json["completed_at"]?.toString(),

      amount: json["amount"] == null
          ? null
          : double.tryParse(json["amount"].toString()),

      repeat: json["repeat"],

      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,

      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,

      organ: json["organ"] != null ? TaskOrgan.fromJson(json["organ"]) : null,

      city: json["city"] != null ? TaskCity.fromJson(json["city"]) : null,

      creator: json["creator"] != null
          ? TaskUser.fromJson(json["creator"])
          : null,

      responsible: json["responsible"] != null
          ? TaskUser.fromJson(json["responsible"])
          : null,

      minutes: json["minutes"] != null
          ? TaskMinutes.fromJson(json["minutes"])
          : null,

      projects: json["projects"] != null
          ? (json["projects"] as List)
                .map((e) => TaskProject.fromJson(e))
                .toList()
          : [],

      taskGroups: json["task_groups"] != null
          ? (json["task_groups"] as List)
                .map((e) => TaskGroup.fromJson(e))
                .toList()
          : [],

      appendixOthers: json["appendix_others"] ?? [],
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,
      title: name,
      description: description ?? "",
      from: organ?.name,
      to: responsible?.name,
      number: id.toString(),
      date: createdAt,
      tag: progress == 100 ? "تکمیل شده" : "در حال انجام",
      status: RecordStatus.newRecord,
      hasAttachment: appendixOthers.isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
      "status": status,
      "progress": progress,
      "completed": completed,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  TaskModel copyWith({
    int? id,

    String? name,

    String? description,

    int? status,

    int? progress,

    int? completed,
  }) {
    return TaskModel(
      id: id ?? this.id,

      name: name ?? this.name,

      description: description ?? this.description,

      status: status ?? this.status,

      progress: progress ?? this.progress,

      completed: completed ?? this.completed,

      startedAt: startedAt,

      endedAt: endedAt,

      completedAt: completedAt,

      amount: amount,

      repeat: repeat,

      createdAt: createdAt,

      updatedAt: updatedAt,

      organ: organ,

      city: city,

      creator: creator,

      responsible: responsible,

      minutes: minutes,

      projects: projects,

      taskGroups: taskGroups,

      appendixOthers: appendixOthers,
    );
  }
}

class TaskOrgan {
  final int id;
  final String name;

  const TaskOrgan({required this.id, required this.name});

  factory TaskOrgan.fromJson(Map<String, dynamic> json) {
    return TaskOrgan(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class TaskCity {
  final int id;
  final String name;

  const TaskCity({required this.id, required this.name});

  factory TaskCity.fromJson(Map<String, dynamic> json) {
    return TaskCity(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class TaskUser {
  final int id;
  final String name;
  final String? avatarUrl;

  const TaskUser({required this.id, required this.name, this.avatarUrl});

  factory TaskUser.fromJson(Map<String, dynamic> json) {
    return TaskUser(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      avatarUrl: json["avatar_url"]?.toString(),
    );
  }
}

class TaskMinutes {
  final int id;
  final String title;
  final DateTime? date;

  const TaskMinutes({required this.id, required this.title, this.date});

  factory TaskMinutes.fromJson(Map<String, dynamic> json) {
    return TaskMinutes(
      id: json["id"] ?? 0,

      title: json["title"] ?? "",

      date: json["date"] != null ? DateTime.parse(json["date"]) : null,
    );
  }
}

class TaskProject {
  final int id;
  final String name;

  const TaskProject({required this.id, required this.name});

  factory TaskProject.fromJson(Map<String, dynamic> json) {
    return TaskProject(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class TaskGroup {
  final int id;
  final String name;

  const TaskGroup({required this.id, required this.name});

  factory TaskGroup.fromJson(Map<String, dynamic> json) {
    return TaskGroup(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}
