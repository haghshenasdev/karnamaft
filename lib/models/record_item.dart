import 'package:flutter/material.dart';

enum RecordStatus { newRecord, pending, referred, archived }

class RecordItem {
  final int id;

  final String title;

  final String? description;

  final String? from;

  final String? to;

  final String? number;

  final DateTime? date;

  final String? tag;

  final RecordStatus status;

  final bool hasAttachment;

  const RecordItem({
    required this.id,
    required this.title,
    this.description,
    this.from,
    this.to,
    this.number,
    this.date,
    this.tag,
    this.status = RecordStatus.newRecord,
    this.hasAttachment = false,
  });
}

extension RecordStatusExtension on RecordStatus {
  String get title {
    switch (this) {
      case RecordStatus.newRecord:
        return "جدید";

      case RecordStatus.pending:
        return "درحال بررسی";

      case RecordStatus.referred:
        return "ارجاع شده";

      case RecordStatus.archived:
        return "بایگانی";
    }
  }

  Color color(BuildContext context) {
    switch (this) {
      case RecordStatus.newRecord:
        return Colors.blue;

      case RecordStatus.pending:
        return Colors.orange;

      case RecordStatus.referred:
        return Colors.green;

      case RecordStatus.archived:
        return Colors.grey;
    }
  }
}
