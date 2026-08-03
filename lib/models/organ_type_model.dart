import 'package:karnamaft/models/record_item.dart';

class OrganTypeModel {
  final int id;
  final String name;
  final String? description;


  const OrganTypeModel({
    required this.id,
    required this.name, this.description,
  });

  factory OrganTypeModel.fromJson(Map<String, dynamic> json) {
    return OrganTypeModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      description: json["description"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "name": name,
      "description": description,
    };
  }

  OrganTypeModel copyWith({
    int? id,
    String? name,
    String? description,
  }) {
    return OrganTypeModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,
      title: name,
      description: description ?? "",
      number: id.toString(),
      from: null,
      to: null,
      date: null,
      tag: null,
      status: null,
      hasAttachment: false,
    );
  }
}
