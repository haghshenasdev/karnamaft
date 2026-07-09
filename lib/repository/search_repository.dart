import 'dart:math';

import 'package:karnamaft/models/search_item.dart';

class SearchRepository {
  SearchRepository._();

  //-------------------------------------------------------
  // Sample Data
  //-------------------------------------------------------

  static final List<SearchItem> _items = List.generate(120, (index) {
    final type = SearchType.values[index % SearchType.values.length];

    final titles = [
      "احداث سالن جلسات",
      "جلسه هیئت علمی",
      "خرید تجهیزات",
      "برنامه امتحانات",
      "بودجه سالانه",
      "بازسازی ساختمان",
      "نامه ریاست",
      "جلسه شورای آموزشی",
      "سامانه جدید",
      "طراحی اپلیکیشن",
    ];

    final subtitles = [
      "دانشگاه آزاد",
      "دانشکده فنی",
      "واحد مالی",
      "معاونت آموزشی",
      "مدیریت",
      "دبیرخانه",
    ];

    return SearchItem(
      id: index + 1,
      type: type,
      title: "${titles[index % titles.length]} ${index + 1}",
      subtitle: subtitles[index % subtitles.length],
      description: "این متن نمونه جهت تست موتور جستجوی برنامه می‌باشد.",
      number: "14${1000 + index}",
      date: DateTime.now().subtract(Duration(days: Random().nextInt(400))),
      matchedField: MatchField.values[index % MatchField.values.length],
    );
  });

  //-------------------------------------------------------
  // All
  //-------------------------------------------------------

  static List<SearchItem> all() {
    return List.from(_items);
  }

  //-------------------------------------------------------
  // Search
  //-------------------------------------------------------

  static List<SearchItem> search({
    required String keyword,
    SearchType? filter,
  }) {
    Iterable<SearchItem> result = _items;

    if (filter != null) {
      result = result.where((e) => e.type == filter);
    }

    if (keyword.trim().isEmpty) {
      return result.toList();
    }

    final text = keyword.toLowerCase();

    result = result.where((item) {
      return item.title.toLowerCase().contains(text) ||
          item.subtitle.toLowerCase().contains(text) ||
          item.description.toLowerCase().contains(text) ||
          item.number.toLowerCase().contains(text);
    });

    return result.toList();
  }

  //-------------------------------------------------------
  // Group By Type
  //-------------------------------------------------------

  static Map<SearchType, List<SearchItem>> groupByType(List<SearchItem> list) {
    final Map<SearchType, List<SearchItem>> map = {};

    for (final item in list) {
      map.putIfAbsent(item.type, () => []);

      map[item.type]!.add(item);
    }

    return map;
  }

  //-------------------------------------------------------
  // Recent
  //-------------------------------------------------------

  static List<SearchItem> recent() {
    final list = List<SearchItem>.from(_items);

    list.sort((a, b) => b.date.compareTo(a.date));

    return list.take(20).toList();
  }

  //-------------------------------------------------------
  // Suggestions
  //-------------------------------------------------------

  static List<String> suggestions() {
    return [
      "جلسه",
      "نامه",
      "بودجه",
      "سالن",
      "دانشگاه",
      "فعالیت",
      "مالی",
      "مصوبه",
      "کارپوشه",
      "امتحانات",
    ];
  }

  //-------------------------------------------------------
  // Count
  //-------------------------------------------------------

  static int count(SearchType type) {
    return _items.where((e) => e.type == type).length;
  }
}
