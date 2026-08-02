import 'package:flutter/material.dart';

import '../models/search_item.dart';

import '../pages/minute_show_page.dart';
import '../pages/letter_show_page.dart';
import '../pages/task_show_page.dart';
import '../pages/project_show_page.dart';

class SearchPageMapper {
  static Widget open(BuildContext context, SearchItem item) {
    switch (item.type) {
      case SearchType.meeting:
        return MinuteShowPage(id: item.id, title: item.title);

      case SearchType.letter:
        return LetterShowPage(id: item.id, title: item.title);

      case SearchType.activity:
        return TaskShowPage(id: item.id, title: item.title);

      case SearchType.agenda:
        return ProjectShowPage(id: item.id, title: item.title);

      default:
        return Scaffold(
          appBar: AppBar(title: Text(item.title)),
          body: const Center(
            child: Text("صفحه نمایش این نوع رکورد هنوز ساخته نشده است"),
          ),
        );
    }
  }
}
