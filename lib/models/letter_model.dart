import 'package:karnamaft/models/record_item.dart';

class LetterModel {
  final int id;

  final String subject;

  final String? description;

  final String? summary;

  final String? file;

  final int? status;

  final int? kind;

  final LetterUser? user;

  final LetterType? type;

  final LetterOrgan? organ;

  final LetterDaftar? daftar;

  final List<LetterCustomer> customers;

  final List<LetterOrganOwner> organsOwner;
  final List<LetterUser> cartables;

  final List<LetterProject> projects;

  final DateTime? created_at;
  final DateTime? updated_at;

  const LetterModel({
    required this.id,
    required this.subject,
    this.description,
    this.summary,
    this.file,
    this.status,
    this.kind,
    this.user,
    this.type,
    this.organ,
    this.daftar,
    required this.customers,
    required this.organsOwner,
    required this.projects,
    this.created_at,
    this.updated_at,
    required this.cartables,
  });

  RecordStatus get recordStatus {
    switch (status) {
      case 1:
        return RecordStatus.newRecord;

      case 2:
        return RecordStatus.pending;

      case 3:
        return RecordStatus.referred;

      default:
        return RecordStatus.archived;
    }
  }

  String? get kindTitle {
    switch (kind) {
      case 0:
        return "وارده";
      case 1:
        return "صادره";
      default:
        return null;
    }
  }

  factory LetterModel.fromJson(Map<String, dynamic> json) {
    return LetterModel(
      id: json["id"] ?? 0,
      subject: json["subject"] ?? "",
      description: json["description"]?.toString(),
      summary: json["summary"]?.toString(),
      file: json["file"]?.toString(),
      status: json["status"],
      kind: json["kind"],

      created_at: json["created_at"] == null
          ? null
          : DateTime.parse(json["created_at"]),
      updated_at: json["updated_at"] == null
          ? null
          : DateTime.parse(json["updated_at"]),

      user: json["user"] != null ? LetterUser.fromJson(json["user"]) : null,

      type: json["type"] != null ? LetterType.fromJson(json["type"]) : null,

      organ: json["organ"] != null ? LetterOrgan.fromJson(json["organ"]) : null,

      daftar: json["daftar"] != null
          ? LetterDaftar.fromJson(json["daftar"])
          : null,

      customers: json["customers"] != null
          ? (json["customers"] as List)
                .map((e) => LetterCustomer.fromJson(e))
                .toList()
          : [],

      organsOwner: json["organs_owner"] != null
          ? (json["organs_owner"] as List)
                .map((e) => LetterOrganOwner.fromJson(e))
                .toList()
          : [],

      cartables: json["cartables"] != null
          ? (json["cartables"] as List)
                .map((e) => LetterUser.fromJson(e))
                .toList()
          : [],

      projects: json["projects"] != null
          ? (json["projects"] as List)
                .map((e) => LetterProject.fromJson(e))
                .toList()
          : [],
    );
  }

  RecordItem toRecord() {
    return RecordItem(
      id: id,
      title: subject,
      description: description ?? "",
      from: organ?.name,
      to: customers.isNotEmpty ? customers.first.name : null,
      number: id.toString(),
      date: created_at,
      tag: kindTitle,
      status: recordStatus,
      hasAttachment: (file ?? "").isNotEmpty,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "created_at": created_at?.toIso8601String(),
      "subject": subject,
      "description": description,
      "summary": summary,
      "file": file,
      "status": status,
      "kind": kind,
    };
  }

  LetterModel copyWith({
    int? id,
    String? subject,
    String? description,
    String? summary,
    String? file,
    int? status,
    int? kind,
    DateTime? created_at,
    DateTime? updated_at,
  }) {
    return LetterModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      description: description ?? this.description,
      summary: summary ?? this.summary,
      file: file ?? this.file,
      status: status ?? this.status,
      kind: kind ?? this.kind,
      user: user,
      type: type,
      organ: organ,
      daftar: daftar,
      customers: customers,
      organsOwner: organsOwner,
      cartables: cartables,
      projects: projects,
      created_at: created_at ?? this.created_at,

      updated_at: updated_at ?? this.updated_at,
    );
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      "subject": subject,
      "created_at": created_at?.toIso8601String(),
      "description": description,
      "summary": summary,
      "file": file,
      "status": status,
      "kind": kind,
    };
  }
}

class LetterUser {
  final int id;
  final String name;
  final String? avatarUrl;

  const LetterUser({required this.id, required this.name, this.avatarUrl});

  factory LetterUser.fromJson(Map<String, dynamic> json) {
    return LetterUser(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      avatarUrl: json["avatar_url"]?.toString(),
    );
  }
}

class LetterType {
  final int id;
  final String name;

  const LetterType({required this.id, required this.name});

  factory LetterType.fromJson(Map<String, dynamic> json) {
    return LetterType(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class LetterOrgan {
  final int id;
  final String name;

  const LetterOrgan({required this.id, required this.name});

  factory LetterOrgan.fromJson(Map<String, dynamic> json) {
    return LetterOrgan(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class LetterDaftar {
  final int id;
  final String name;

  const LetterDaftar({required this.id, required this.name});

  factory LetterDaftar.fromJson(Map<String, dynamic> json) {
    return LetterDaftar(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class LetterCustomer {
  final int id;
  final String name;

  const LetterCustomer({required this.id, required this.name});

  factory LetterCustomer.fromJson(Map<String, dynamic> json) {
    return LetterCustomer(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class LetterOrganOwner {
  final int id;
  final String name;

  const LetterOrganOwner({required this.id, required this.name});

  factory LetterOrganOwner.fromJson(Map<String, dynamic> json) {
    return LetterOrganOwner(id: json["id"] ?? 0, name: json["name"] ?? "");
  }
}

class LetterProject {
  final int id;
  final String name;
  final String? summary;

  const LetterProject({required this.id, required this.name, this.summary});

  factory LetterProject.fromJson(Map<String, dynamic> json) {
    return LetterProject(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      summary: json["summary"]?.toString(),
    );
  }
}
