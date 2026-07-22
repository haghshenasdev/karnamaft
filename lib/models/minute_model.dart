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

      status: RecordStatus.pending,

      hasAttachment: (file ?? "").isNotEmpty,
    );
  }
}
