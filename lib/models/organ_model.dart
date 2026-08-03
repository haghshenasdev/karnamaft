import 'package:karnamaft/models/record_item.dart';

class OrganModel {
  final int id;
  final String name;
  final String? address;
  final String? phone;
  final int organTypeId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const OrganModel({
    required this.id,
    required this.name,
    this.address,
    this.phone,
    required this.organTypeId,
    this.createdAt,
    this.updatedAt,
  });

  factory OrganModel.fromJson(Map<String, dynamic> json) {
    return OrganModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      address: json["address"]?.toString(),
      phone: json["phone"]?.toString(),
      organTypeId: json["organ_type_id"] ?? 0,
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
      "address": address,
      "phone": phone,
      "organ_type_id": organTypeId,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }

  OrganModel copyWith({
    int? id,
    String? name,
    String? address,
    String? phone,
    int? organTypeId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrganModel(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      organTypeId: organTypeId ?? this.organTypeId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,
      title: name,
      description: address ?? "",
      number: id.toString(),
      from: null,
      to: null,
      date: createdAt,
      tag: phone,
      status: null,
      hasAttachment: false,
    );
  }
}
