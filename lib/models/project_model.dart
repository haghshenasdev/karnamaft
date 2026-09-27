import 'package:karnamaft/models/record_item.dart';

class ProjectModel {
  final int id;

  final String name;

  final String? description;

  final int? status;

  final double? requiredAmount;

  final double? amount;

  final DateTime? createdAt;

  final DateTime? updatedAt;

  final ProjectOrgan? organ;

  final ProjectCity? city;

  final ProjectUser? user;

  final List<ProjectGroup> groups;
  final List<ProjectLetter> letters;
  final List<ProjectTask> tasks;

  const ProjectModel({
    required this.id,

    required this.name,

    this.description,

    this.status,

    this.requiredAmount,

    this.amount,

    this.createdAt,

    this.updatedAt,

    this.organ,

    this.city,

    this.user,

    required this.groups,
    this.letters = const [],
    this.tasks = const [],
  });

  RecordStatus get recordStatus {
    return RecordStatusExtension.fromValue(status);
  }

  String get statusTitle {
    switch (status) {
      case 1:
        return "فعال";

      case 2:
        return "در حال انجام";

      case 3:
        return "تکمیل شده";

      default:
        return "-";
    }
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json["id"] ?? 0,

      name: json["name"] ?? "",

      description: json["description"]?.toString(),

      status: json["status"],

      requiredAmount: json["required_amount"] == null
          ? null
          : double.tryParse(json["required_amount"].toString()),

      amount: json["amount"] == null
          ? null
          : double.tryParse(json["amount"].toString()),

      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,

      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,

      organ: json["organ"] != null
          ? ProjectOrgan.fromJson(json["organ"])
          : null,

      city: json["city"] != null ? ProjectCity.fromJson(json["city"]) : null,

      user: json["user"] != null ? ProjectUser.fromJson(json["user"]) : null,

      groups: json["group"] != null
          ? (json["group"] as List)
                .map((e) => ProjectGroup.fromJson(e))
                .toList()
          : [],
      letters: (json["related_letters"] as List? ?? [])
          .map((e) => ProjectLetter.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      tasks: (json["related_tasks"] as List? ?? [])
          .map((e) => ProjectTask.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,

      title: name,

      description: description ?? "",

      from: organ?.name,

      to: user?.name,

      number: id.toString(),

      date: createdAt,

      tag: statusTitle,

      status: recordStatus,

      hasAttachment: false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,

      "name": name,

      "description": description,

      "status": status,

      "required_amount": requiredAmount,

      "amount": amount,

      "created_at": createdAt?.toIso8601String(),

      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  ProjectModel copyWith({
    int? id,

    String? name,

    String? description,

    int? status,

    double? requiredAmount,

    double? amount,
  }) {
    return ProjectModel(
      id: id ?? this.id,

      name: name ?? this.name,

      description: description ?? this.description,

      status: status ?? this.status,

      requiredAmount: requiredAmount ?? this.requiredAmount,

      amount: amount ?? this.amount,

      createdAt: createdAt,

      updatedAt: updatedAt,

      organ: organ,

      city: city,

      user: user,

      groups: groups,
      letters: letters,
      tasks: tasks,
    );
  }
}

class ProjectUser {
  final int id;

  final String name;

  final String? avatarUrl;

  const ProjectUser({required this.id, required this.name, this.avatarUrl});

  factory ProjectUser.fromJson(Map<String, dynamic> json) {
    return ProjectUser(
      id: json["id"] ?? 0,

      name: json["name"] ?? "",

      avatarUrl: json["avatar_url"]?.toString(),
    );
  }
}

class ProjectOrgan {
  final int id;

  final String name;

  const ProjectOrgan({required this.id, required this.name});

  factory ProjectOrgan.fromJson(Map<String, dynamic> json) {
    return ProjectOrgan(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class ProjectCity {
  final int id;

  final String name;

  const ProjectCity({required this.id, required this.name});

  factory ProjectCity.fromJson(Map<String, dynamic> json) {
    return ProjectCity(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class ProjectGroup {
  final int id;

  final String name;

  const ProjectGroup({required this.id, required this.name});

  factory ProjectGroup.fromJson(Map<String, dynamic> json) {
    return ProjectGroup(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}


class ProjectLetter {
  final int id;
  final String subject;
  final String? description;
  final String? file;
  final DateTime? createdAt;

  const ProjectLetter({required this.id, required this.subject, this.description, this.file, this.createdAt});

  factory ProjectLetter.fromJson(Map<String, dynamic> json) => ProjectLetter(
    id: json['id'] ?? 0,
    subject: json['subject']?.toString() ?? '',
    description: json['description']?.toString(),
    file: json['file']?.toString(),
    createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
  );
}

class ProjectTask {
  final int id;
  final String name;
  final String? description;
  final bool completed;
  final int? progress;
  final ProjectMinute? minutes;

  const ProjectTask({required this.id, required this.name, this.description, this.completed = false, this.progress, this.minutes});

  factory ProjectTask.fromJson(Map<String, dynamic> json) => ProjectTask(
    id: json['id'] ?? 0,
    name: json['name']?.toString() ?? '',
    description: json['description']?.toString(),
    completed: json['completed'] == true || json['completed'] == 1,
    progress: json['progress'] is int ? json['progress'] : int.tryParse('${json['progress']}'),
    minutes: json['minutes'] is Map ? ProjectMinute.fromJson(Map<String, dynamic>.from(json['minutes'])) : null,
  );
}

class ProjectMinute {
  final int id;
  final String title;
  final DateTime? date;

  const ProjectMinute({required this.id, required this.title, this.date});

  factory ProjectMinute.fromJson(Map<String, dynamic> json) => ProjectMinute(
    id: json['id'] ?? 0,
    title: json['title']?.toString() ?? '',
    date: json['date'] != null ? DateTime.tryParse(json['date'].toString()) : null,
  );
}
