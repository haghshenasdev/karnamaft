import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryService {
  static const String _prefix = "history_";

  /// ذخیره یک مقدار جدید
  static Future<void> add(
    String key,
    String value, {
    int maxItems = 10,
  }) async {
    if (value.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();

    final items = await get(key);

    // اگر قبلا وجود داشته حذف شود تا دوباره به اول بیاید
    items.remove(value);

    // جدیدترین اول لیست
    items.insert(0, value);

    // محدود کردن تعداد
    if (items.length > maxItems) {
      items.removeRange(maxItems, items.length);
    }

    await prefs.setString(
      "$_prefix$key",
      jsonEncode(items),
    );
  }


  /// دریافت لیست تاریخچه
  static Future<List<String>> get(String key) async {
    final prefs = await SharedPreferences.getInstance();

    final data = prefs.getString("$_prefix$key");

    if (data == null) {
      return [];
    }

    try {
      return List<String>.from(jsonDecode(data));
    } catch (_) {
      return [];
    }
  }


  /// حذف یک مورد
  static Future<void> remove(
    String key,
    String value,
  ) async {
    final items = await get(key);

    items.remove(value);

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      "$_prefix$key",
      jsonEncode(items),
    );
  }


  /// پاک کردن کل تاریخچه
  static Future<void> clear(String key) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("$_prefix$key");
  }
}