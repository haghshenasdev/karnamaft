import 'package:flutter/material.dart';
import 'record_item.dart';

class SelectDialogConfig {
  final String title;

  /// انتخاب چندتایی
  final bool multiSelect;

  /// کلید ذخیره تاریخچه
  final String historyKey;

  /// تعداد تاریخچه
  final int historyCount;

  /// اگر کاربر این مجوز را داشته باشد، دکمه ایجاد رکورد در دیالوگ نمایش داده می‌شود.
  final String? createPermission;

  /// رکورد تازه ایجادشده را برگرداند تا همان لحظه به انتخاب‌ها اضافه شود.
  final Future<RecordItem?> Function(BuildContext context)? onCreate;

  const SelectDialogConfig({
    required this.title,
    this.multiSelect = false,
    required this.historyKey,
    this.historyCount = 10,
    this.createPermission,
    this.onCreate,
  });
}
