import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/content_group_service.dart';
import 'package:karnamaft/services/content_service.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';

class ContentCreatePage extends StatefulWidget {
  final Uint8List? initialFileBytes;
  final String? initialFileName;
  const ContentCreatePage({super.key, this.initialFileBytes, this.initialFileName});
  @override State<ContentCreatePage> createState() => _ContentCreatePageState();
}

class _ContentCreatePageState extends State<ContentCreatePage> {
  final service = const ContentService();
  final title = TextEditingController();
  final text = TextEditingController();
  List<RecordItem> groups = [];
  bool saving = false;

  @override void dispose() { title.dispose(); text.dispose(); super.dispose(); }

  Future<void> pickGroups() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ContentGroupService(),
        config: const SelectDialogConfig(title: 'دسته‌بندی یادداشت', multiSelect: true, historyKey: 'content_groups'),
      ),
    );
    if (result is List<RecordItem>) setState(() => groups = result);
  }

  Future<void> save() async {
    if (title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عنوان الزامی است')));
      return;
    }
    setState(() => saving = true);
    try {
      final body = <Map<String, dynamic>>[];
      if (text.text.trim().isNotEmpty) body.add({'type': 'text', 'text': text.text.trim()});
      final result = await service.create(
        title: title.text.trim(),
        groupIds: groups.map((e) => e.id).toList(),
        body: body,
        uploadBytes: widget.initialFileBytes,
        uploadFileName: widget.initialFileName,
      );
      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ایجاد یادداشت آنلاین')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            InkWell(
              onTap: pickGroups,
              child: InputDecorator(
                decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder(), suffixIcon: Icon(Icons.arrow_drop_down)),
                child: Wrap(
                  spacing: 6,
                  children: groups.isEmpty ? [const Text('انتخاب دسته‌بندی')] : groups.map((e) => Chip(label: Text(e.title))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: text, minLines: 5, maxLines: 15, decoration: const InputDecoration(labelText: 'متن یادداشت', border: OutlineInputBorder())),
            if (widget.initialFileName != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Card(child: ListTile(leading: const Icon(Icons.attach_file), title: Text(widget.initialFileName!))),
              ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: saving ? null : save,
              icon: saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save),
              label: const Text('ذخیره آنلاین'),
            ),
          ],
        ),
      ),
    );
  }
}
