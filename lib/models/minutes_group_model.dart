import 'record_item.dart';

class MinutesGroupModel {
  final int id;
  final String name;
  final int? parentId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MinutesGroupModel({
    required this.id,
    required this.name,
    this.parentId,
    this.createdAt,
    this.updatedAt,
  });

  factory MinutesGroupModel.fromJson(Map<String, dynamic> json) {
    return MinutesGroupModel(
      id: json["id"],
      name: json["name"] ?? "",
      parentId: json["parent_id"],
      createdAt: json["created_at"] != null
          ? DateTime.parse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.parse(json["updated_at"])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "parent_id": parentId,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,
      title: name,
      description: parentId == null ? "دسته اصلی" : "شناسه والد: $parentId",
    );
  }
}
