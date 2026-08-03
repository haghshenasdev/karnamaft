import 'package:karnamaft/models/minute_relation.dart';
import 'package:karnamaft/models/record_item.dart';

class MinuteModel {
  final int id;

  final String title;

  final String? text;

  final String? file;
  final DateTime? date;
  final int? typer_id;
  final int? task_id;
  final DateTime? created_at;
  final DateTime? updated_at;
  final MinuteUser? typer;

  final TaskCreator? taskCreator;

  final List<OrganModel>? organs;

  final List<GroupModel> group;

  const MinuteModel({
    required this.id,
    required this.title,
    this.date,
    this.file,
    this.text,
    this.typer_id,
    this.task_id,
    this.created_at,
    this.updated_at,
    this.typer,
    this.taskCreator,
    required this.organs,
    required this.group,
  });

  factory MinuteModel.fromJson(Map<String, dynamic> json) {
    return MinuteModel(
      id: json["id"] ?? 0,
      title: json["title"] ?? "",
      text: json["text"]?.toString(),
      file: json["file"]?.toString(),
      date: json["date"] == null ? null : DateTime.parse(json["date"]),
      typer_id: json["typer_id"] ?? null,
      task_id: json["task_id"] ?? null,
      created_at: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updated_at: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),
      typer: json["typer"] != null ? MinuteUser.fromJson(json["typer"]) : null,

      taskCreator: json["task_creator"] != null
          ? TaskCreator.fromJson(json["task_creator"])
          : null,

      organs: json['organs'] != null
          ? (json['organs'] as List).map((e) => OrganModel.fromJson(e)).toList()
          : [],

      group: json['group'] != null
          ? (json['group'] as List).map((e) => GroupModel.fromJson(e)).toList()
          : [],
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,

      title: title,

      description: text ?? "",

      from: null,

      to: null,

      number: id.toString(),

      date: date,

      tag: null,

      status: null,

      hasAttachment: (file ?? "").isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "text": text,
      "file": file,
      "date": date?.toIso8601String(),
      "typer_id": typer_id,
      "task_id": task_id,
      "created_at": created_at?.toIso8601String(),
      "updated_at": updated_at?.toIso8601String(),
    };
  }

  MinuteModel copyWith({
    int? id,
    String? title,
    String? text,
    String? file,
    DateTime? date,
    int? typer_id,
    int? task_id,
    DateTime? created_at,
    DateTime? updated_at,
    List<OrganModel>? organs,
  }) {
    return MinuteModel(
      id: id ?? this.id,

      title: title ?? this.title,

      text: text ?? this.text,

      file: file ?? this.file,

      date: date ?? this.date,

      typer_id: typer_id ?? this.typer_id,

      task_id: task_id ?? this.task_id,

      created_at: created_at ?? this.created_at,

      updated_at: updated_at ?? this.updated_at,

      typer: typer,

      taskCreator: taskCreator,

      organs: organs,

      group: group,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      "title": title,
      "text": text,
      "file": file,
      "date": date?.toIso8601String(),
      "typer_id": typer_id,
      "task_id": task_id,
    };
  }
}
