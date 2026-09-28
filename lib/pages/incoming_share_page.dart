import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'letter_create_page.dart';
import 'minute_create_page.dart';
import 'task_create_page.dart';

class IncomingSharePage extends StatefulWidget {
  final String filePath;

  const IncomingSharePage({
    super.key,
    required this.filePath,
  });

  @override
  State<IncomingSharePage> createState() => _IncomingSharePageState();
}

class _IncomingSharePageState extends State<IncomingSharePage> {
  Uint8List? bytes;
  bool loading = true;

  String get fileName {
    return widget.filePath
        .split(Platform.pathSeparator)
        .last;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      bytes = await File(widget.filePath).readAsBytes();
    } catch (_) {
      bytes = null;
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> _openCreate(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );

    if (!mounted) return;

    if (result != null) {
      try {
        final file = File(widget.filePath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // فایل در cache است؛ خطای حذف نباید نتیجه ثبت را خراب کند.
      }

      if (!mounted) return;

      Navigator.pop(context, result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت فایل دریافت‌شده'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const Icon(
                    Icons.file_present,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      fileName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'این فایل را در کدام بخش ثبت می‌کنید؟',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 12),
          _Action(
            icon: Icons.mail_outline,
            title: 'ایجاد نامه',
            subtitle: 'فایل به عنوان فایل اصلی نامه قرار می‌گیرد.',
            onTap: () => _openCreate(
              LetterCreatePage(
                initialFilePath: widget.filePath,
              ),
            ),
          ),
          _Action(
            icon: Icons.description_outlined,
            title: 'ایجاد صورتجلسه',
            subtitle: 'فایل در فرم صورتجلسه آماده می‌شود.',
            onTap: loading || bytes == null
                ? null
                : () => _openCreate(
                      MinuteCreatePage(
                        initialFileBytes: bytes,
                        initialFileName: fileName,
                      ),
                    ),
          ),
          _Action(
            icon: Icons.task_alt,
            title: 'ایجاد فعالیت',
            subtitle: 'فایل به عنوان پیوست فعالیت اضافه می‌شود.',
            onTap: () => _openCreate(
              TaskCreatePage(
                initialFilePath: widget.filePath,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Action extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _Action({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: ListTile(
        enabled: onTap != null,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        leading: CircleAvatar(
          child: Icon(icon),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_left),
        onTap: onTap,
      ),
    );
  }
}
