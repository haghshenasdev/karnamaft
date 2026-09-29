import 'package:flutter/material.dart';

import '../api/api_client.dart';
import '../api/api_error_handler.dart';
import 'letter_show_page.dart';
import 'minute_show_page.dart';
import 'project_show_page.dart';
import 'task_show_page.dart';

class AnnouncementsPage extends StatefulWidget {
  const AnnouncementsPage({super.key});

  @override
  State<AnnouncementsPage> createState() => _AnnouncementsPageState();
}

class _AnnouncementsPageState extends State<AnnouncementsPage> {
  bool loading = true;
  String? error;
  List<Map<String, dynamic>> items = [];
  int page = 1;
  int lastPage = 1;

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load({int p = 1}) async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await ApiClient.dio.get(
        '/mobile/v1/notifications',
        queryParameters: {'page': p, 'per_page': 20},
      );
      final json = Map<String, dynamic>.from(response.data as Map);
      final meta = Map<String, dynamic>.from(json['meta'] ?? const {});
      final nextItems = (json['data'] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      if (!mounted) return;
      setState(() {
        items = p == 1 ? nextItems : [...items, ...nextItems];
        page = int.tryParse('${meta['current_page'] ?? p}') ?? p;
        lastPage = int.tryParse('${meta['last_page'] ?? 1}') ?? 1;
      });
    } catch (e) {
      if (mounted) setState(() => error = ApiErrorHandler.handle(e).toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _openNotification(Map<String, dynamic> item, int index) async {
    final id = item['id']?.toString();
    if (id == null || id.isEmpty) return;

    try {
      await ApiClient.dio.patch('/mobile/v1/notifications/$id/read');
      if (mounted) {
        setState(() => items[index]['read_at'] = DateTime.now().toIso8601String());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('علامت‌گذاری اعلان به‌عنوان خوانده‌شده انجام نشد: ${ApiErrorHandler.handle(e)}')),
        );
      }
      return;
    }

    final resourceType = (item['resource_type'] ?? '').toString().toLowerCase();
    final resourceId = int.tryParse('${item['resource_id'] ?? ''}');
    if (resourceId == null || resourceId <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('این اعلان قدیمی است یا به رکورد مشخصی متصل نشده است.')),
        );
      }
      return;
    }

    Widget? destination;
    switch (resourceType) {
      case 'letter':
      case 'letters':
        destination = LetterShowPage(id: resourceId, title: 'نامه');
        break;
      case 'minute':
      case 'minutes':
        destination = MinuteShowPage(id: resourceId, title: 'صورتجلسه');
        break;
      case 'task':
      case 'tasks':
        destination = TaskShowPage(id: resourceId, title: 'فعالیت');
        break;
      case 'project':
      case 'projects':
        destination = ProjectShowPage(id: resourceId, title: 'دستورکار');
        break;
    }

    if (destination != null && mounted) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => destination!));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اعلانات'),
        actions: [
          IconButton(
            onPressed: loading ? null : () => load(),
            icon: const Icon(Icons.refresh),
            tooltip: 'بروزرسانی',
          ),
        ],
      ),
      body: loading && items.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : error != null && items.isEmpty
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(error!, textAlign: TextAlign.center)))
              : items.isEmpty
                  ? const Center(child: Text('اعلانی وجود ندارد.'))
                  : ListView.builder(
                      itemCount: items.length + (page < lastPage ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == items.length) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: FilledButton(
                              onPressed: loading ? null : () => load(p: page + 1),
                              child: const Text('نمایش بیشتر'),
                            ),
                          );
                        }
                        final item = items[index];
                        final unread = item['read_at'] == null;
                        return ListTile(
                          isThreeLine: true,
                          leading: CircleAvatar(
                            child: Icon(unread ? Icons.notifications_active : Icons.notifications_none),
                          ),
                          title: Text(
                            item['title']?.toString() ?? 'اعلان',
                            style: TextStyle(fontWeight: unread ? FontWeight.bold : FontWeight.normal),
                          ),
                          subtitle: Text(item['message']?.toString() ?? ''),
                          trailing: item['resource_id'] != null ? const Icon(Icons.chevron_left) : null,
                          onTap: () => _openNotification(item, index),
                        );
                      },
                    ),
    );
  }
}
