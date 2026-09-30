import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/pages/content_create_page.dart';
import 'package:karnamaft/pages/content_show_page.dart';
import 'package:karnamaft/services/content_service.dart';
import 'package:karnamaft/pages/records_page.dart';
import 'package:provider/provider.dart';

class ContentsPage extends StatelessWidget {
  const ContentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserController>();

    return RecordsPage(
      title: 'یادداشت‌های آنلاین',
      service: const ContentService(),
      showPageBuilder: (id, title) => ContentShowPage(id: id, title: title),
      createPageBuilder: user.can('create_content')
          ? () => const ContentCreatePage()
          : null,
      createSuccessMessage: 'یادداشت با موفقیت ایجاد شد',
    );
  }
}
