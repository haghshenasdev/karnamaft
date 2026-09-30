import 'package:flutter/material.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/content_model.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/content_group_service.dart';
import 'package:karnamaft/services/content_service.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';
import 'package:karnamaft/widgets/file_viewer_page.dart';
import 'package:karnamaft/services/file_service.dart';
import 'package:provider/provider.dart';

class ContentShowPage extends StatefulWidget {
  final int id; final String title;
  const ContentShowPage({super.key, required this.id, required this.title});
  @override State<ContentShowPage> createState() => _ContentShowPageState();
}

class _ContentShowPageState extends State<ContentShowPage> {
  final service = const ContentService();
  ContentModel? item;
  late TextEditingController title;
  late TextEditingController text;
  List<RecordItem> groups = [];
  bool loading = true, editing = false, saving = false;
  String? error;

  @override void initState() { super.initState(); title = TextEditingController(); text = TextEditingController(); load(); }
  @override void dispose() { title.dispose(); text.dispose(); super.dispose(); }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final result = await service.show(widget.id);
      if (!mounted) return;
      setState(() {
        item = result;
        title.text = result.title;
        text.text = result.body.where((e) => e.type == 'text').map((e) => e.text ?? '').join('\n\n');
        groups = result.groups.map((e) => RecordItem(id: e.id, title: e.name)).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (mounted) setState(() { loading = false; error = e.toString(); });
    }
  }

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
    final current = item;
    if (current == null) return;
    setState(() => saving = true);
    try {
      final body = current.bodyJson;
      final texts = body.where((e) => e['type'] == 'text').toList();
      if (texts.isEmpty && text.text.trim().isNotEmpty) {
        body.insert(0, {'type': 'text', 'text': text.text.trim()});
      } else if (texts.isNotEmpty) {
        texts.first['text'] = text.text.trim();
      }
      final result = await service.update(current.id, title: title.text.trim(), groupIds: groups.map((e) => e.id).toList(), body: body);
      if (!mounted) return;
      setState(() { item = result; editing = false; });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('یادداشت با موفقیت ذخیره شد.')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Widget _part(ContentPart part) {
    if (part.type == 'text') return Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(part.text ?? ''));
    return Card(child: ListTile(leading: const Icon(Icons.attach_file), title: Text(part.name ?? 'پیوست'), subtitle: Text(part.mime ?? part.file ?? ''), onTap: part.url == null ? null : () => _openFile(part)));
  }

  Future<void> _openFile(ContentPart part) async {
    final url = part.url;
    if (url == null || url.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerPage(
          title: part.name ?? 'پیوست یادداشت',
          fileName: part.name ?? 'attachment',
          future: FileService.download(url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return Scaffold(appBar: AppBar(title: Text(widget.title)), body: const Center(child: CircularProgressIndicator()));
    if (error != null) return Scaffold(appBar: AppBar(title: Text(widget.title)), body: Center(child: Text(error!)));
    final x = item!;
    final canEdit = context.watch<UserController>().can('update_content');
    return Scaffold(
      appBar: AppBar(title: Text(x.title), actions: [if (canEdit) IconButton(icon: Icon(editing ? Icons.close : Icons.edit), onPressed: () => setState(() => editing = !editing))]),
      body: RefreshIndicator(
        onRefresh: load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              editing ? TextField(controller: title, decoration: const InputDecoration(labelText: 'عنوان', border: OutlineInputBorder())) : Text(x.title, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              editing
                  ? InkWell(onTap: pickGroups, child: InputDecorator(decoration: const InputDecoration(labelText: 'دسته‌بندی', border: OutlineInputBorder()), child: Wrap(spacing: 6, children: groups.isEmpty ? [const Text('بدون دسته‌بندی')] : groups.map((e) => Chip(label: Text(e.title))).toList())))
                  : Wrap(spacing: 6, children: x.groups.map((e) => Chip(label: Text(e.name))).toList()),
              const SizedBox(height: 16),
              editing ? TextField(controller: text, minLines: 5, maxLines: 15, decoration: const InputDecoration(labelText: 'متن', border: OutlineInputBorder())) : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: x.body.map(_part).toList()),
              if (editing) ...[const SizedBox(height: 24), FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save), label: const Text('ذخیره'))],
            ],
          ),
        ),
      ),
    );
  }
}
