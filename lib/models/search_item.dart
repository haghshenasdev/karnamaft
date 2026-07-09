import 'package:flutter/material.dart';

enum SearchType {
  note,
  letter,
  meeting,
  resolution,
  activity,
  agenda,
  workspace,
}

extension SearchTypeExtension on SearchType {
  String get title {
    switch (this) {
      case SearchType.note:
        return "یادداشت";

      case SearchType.letter:
        return "نامه";

      case SearchType.meeting:
        return "صورت جلسه";

      case SearchType.resolution:
        return "مصوبه";

      case SearchType.activity:
        return "فعالیت";

      case SearchType.agenda:
        return "دستور کار";

      case SearchType.workspace:
        return "کارپوشه";
    }
  }

  IconData get icon {
    switch (this) {
      case SearchType.note:
        return Icons.edit_note_rounded;

      case SearchType.letter:
        return Icons.mark_email_read_outlined;

      case SearchType.meeting:
        return Icons.groups_rounded;

      case SearchType.resolution:
        return Icons.gavel_rounded;

      case SearchType.activity:
        return Icons.task_alt_rounded;

      case SearchType.agenda:
        return Icons.event_note_rounded;

      case SearchType.workspace:
        return Icons.work_history_rounded;
    }
  }

  Color get color {
    switch (this) {
      case SearchType.note:
        return Colors.blue;

      case SearchType.letter:
        return Colors.green;

      case SearchType.meeting:
        return Colors.orange;

      case SearchType.resolution:
        return Colors.red;

      case SearchType.activity:
        return Colors.purple;

      case SearchType.agenda:
        return Colors.teal;

      case SearchType.workspace:
        return Colors.indigo;
    }
  }
}

enum MatchField { title, subtitle, description, number }

extension MatchFieldExtension on MatchField {
  String get title {
    switch (this) {
      case MatchField.title:
        return "عنوان";

      case MatchField.subtitle:
        return "زیرعنوان";

      case MatchField.description:
        return "متن";

      case MatchField.number:
        return "شماره";
    }
  }
}

class SearchItem {
  final int id;

  final SearchType type;

  final String title;

  final String subtitle;

  final String description;

  final String number;

  final DateTime date;

  final MatchField matchedField;

  const SearchItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.number,
    required this.date,
    required this.matchedField,
  });

  SearchItem copyWith({
    int? id,
    SearchType? type,
    String? title,
    String? subtitle,
    String? description,
    String? number,
    DateTime? date,
    MatchField? matchedField,
  }) {
    return SearchItem(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      description: description ?? this.description,
      number: number ?? this.number,
      date: date ?? this.date,
      matchedField: matchedField ?? this.matchedField,
    );
  }

  factory SearchItem.fromJson(Map<String, dynamic> json) {
    return SearchItem(
      id: json["id"],
      type: SearchType.values.firstWhere((e) => e.name == json["type"]),
      title: json["title"] ?? "",
      subtitle: json["subtitle"] ?? "",
      description: json["description"] ?? "",
      number: json["number"] ?? "",
      date: DateTime.parse(json["date"]),
      matchedField: MatchField.values.firstWhere(
        (e) => e.name == json["matched_field"],
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "type": type.name,
      "title": title,
      "subtitle": subtitle,
      "description": description,
      "number": number,
      "date": date.toIso8601String(),
      "matched_field": matchedField.name,
    };
  }
}
