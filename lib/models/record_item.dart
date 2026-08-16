import 'package:flutter/material.dart';

enum RecordStatus {
  archived,       // 0 - بایگانی
  completed,      // 1 - اتمام
  inProgress,     // 2 - در حال پیگیری
  notTrackable,   // 3 - غیرقابل پیگیری
  newRecord,      // 4 - جدید
  unknown,        // وضعیت نامشخص
}

extension RecordStatusExtension on RecordStatus {
  // --------------------------------------------------
  // PHP status value
  // --------------------------------------------------

  int get value {
    switch (this) {
      case RecordStatus.archived:
        return 0;

      case RecordStatus.completed:
        return 1;

      case RecordStatus.inProgress:
        return 2;

      case RecordStatus.notTrackable:
        return 3;

      case RecordStatus.newRecord:
        return 4;

      case RecordStatus.unknown:
        return -1;
    }
  }

  // --------------------------------------------------
  // عنوان فارسی
  // --------------------------------------------------

  String get title {
    switch (this) {
      case RecordStatus.archived:
        return "بایگانی";

      case RecordStatus.completed:
        return "اتمام";

      case RecordStatus.inProgress:
        return "در حال پیگیری";

      case RecordStatus.notTrackable:
        return "غیرقابل پیگیری";

      case RecordStatus.newRecord:
        return "جدید";

      case RecordStatus.unknown:
        return "بدون وضعیت";
    }
  }

  // --------------------------------------------------
  // رنگ مطابق وضعیت
  // --------------------------------------------------

  Color color(BuildContext context) {
    switch (this) {
      case RecordStatus.archived:
        return Colors.grey;

      case RecordStatus.completed:
        return Colors.green;

      case RecordStatus.inProgress:
        return Colors.blue;

      case RecordStatus.notTrackable:
        return Colors.red;

      case RecordStatus.newRecord:
        return Colors.indigo;

      case RecordStatus.unknown:
        return Colors.orange;
    }
  }

  // --------------------------------------------------
  // تبدیل int به enum
  // --------------------------------------------------

  static RecordStatus fromValue(int? value) {
    switch (value) {
      case 0:
        return RecordStatus.archived;

      case 1:
        return RecordStatus.completed;

      case 2:
        return RecordStatus.inProgress;

      case 3:
        return RecordStatus.notTrackable;

      case 4:
        return RecordStatus.newRecord;

      default:
        return RecordStatus.unknown;
    }
  }
}

// --------------------------------------------------
// Record Item
// --------------------------------------------------

class RecordItem {
  final int id;

  final String title;

  final String? description;

  final String? from;

  final String? to;

  final String? number;

  final DateTime? date;

  final String? tag;

  final RecordStatus? status;

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