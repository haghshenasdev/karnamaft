import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/widgets/content_group_filter.dart';
import 'package:karnamaft/services/content_service.dart';

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
  Uint8List? pickedFileBytes;
  String? pickedFileName;

  @override void dispose() { title.dispose(); text.dispose(); super.dispose(); }

  Future<void> pickGroups() async {
    final result = await ContentGroupPicker.show(context, title: 'دسته‌بندی یادداشت', multiSelect: true);
    if (result != null) {
      setState(() => groups = result.map((g) => RecordItem(id: g.id, title: g.name)).toList());
    }
  }

  Future<void> pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true, allowMultiple: false);
      if (result == null || result.files.isEmpty) return;
      final file = result.files.single;
      if (file.bytes == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خواندن فایل انتخاب‌شده ممکن نشد')));
        return;
      }
      setState(() { pickedFileBytes = file.bytes; pickedFileName = file.name; });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('انتخاب فایل ناموفق بود: $e')));
    }
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
        uploadBytes: pickedFileBytes ?? widget.initialFileBytes,
        uploadFileName: pickedFileName ?? widget.initialFileName,
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
                  children: groups.isEmpty ? [const Text('انتخاب دسته‌بندی')] : groups.map((e) => Chip(label: Text('${e.id} - ${e.title}'))).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(controller: text, minLines: 5, maxLines: 15, decoration: const InputDecoration(labelText: 'متن یادداشت', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: saving ? null : pickFile,
              icon: const Icon(Icons.attach_file),
              label: Text(pickedFileName == null && widget.initialFileName == null ? 'افزودن فایل پیوست' : 'تغییر فایل پیوست'),
            ),
            if (pickedFileName != null || widget.initialFileName != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.insert_drive_file_outlined),
                  title: Text(pickedFileName ?? widget.initialFileName!, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    tooltip: 'حذف فایل انتخاب‌شده',
                    icon: const Icon(Icons.close),
                    onPressed: saving ? null : () => setState(() { pickedFileBytes = null; pickedFileName = null; }),
                  ),
                ),
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
