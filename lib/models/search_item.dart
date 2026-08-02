import 'package:flutter/material.dart';
import 'record_item.dart';

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
        return Icons.edit_note;

      case SearchType.letter:
        return Icons.mail;

      case SearchType.meeting:
        return Icons.groups;

      case SearchType.resolution:
        return Icons.gavel;

      case SearchType.activity:
        return Icons.task;

      case SearchType.agenda:
        return Icons.event_note;

      case SearchType.workspace:
        return Icons.work;
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
  String get label {
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

  factory SearchItem.fromRecord(RecordItem record, SearchType type) {
    return SearchItem(
      id: record.id,

      type: type,

      title: record.title,

      subtitle: record.from ?? "",

      description: record.description ?? "",

      number: record.number ?? "",

      date: record.date ?? DateTime.now(),

      matchedField: MatchField.title,
    );
  }
}
