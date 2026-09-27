import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class ShareField {
  final String label;
  final String value;
  bool selected;
  ShareField({required this.label, required this.value, this.selected = true});
}

class ShareFile {
  final String name;
  final Future<Uint8List?> Function() load;
  ShareFile({required this.name, required this.load});
}

Future<void> showRecordShareDialog(
  BuildContext context, {
  required String title,
  required List<ShareField> fields,
  ShareFile? file,
}) async {
  await showDialog(
    context: context,
    builder: (context) => _RecordShareDialog(
      title: title,
      fields: fields,
      file: file,
    ),
  );
}

class _RecordShareDialog extends StatefulWidget {
  final String title;
  final List<ShareField> fields;
  final ShareFile? file;

  const _RecordShareDialog({required this.title, required this.fields, this.file});

  @override
  State<_RecordShareDialog> createState() => _RecordShareDialogState();
}

class _RecordShareDialogState extends State<_RecordShareDialog> {
  bool sharing = false;
  bool includeFile = true;

  Future<void> share() async {
    final selected = widget.fields.where((e) => e.selected && e.value.trim().isNotEmpty).toList();
    if (selected.isEmpty && widget.file == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک مورد را انتخاب کنید.')));
      return;
    }

    setState(() => sharing = true);
    try {
      final text = selected.map((e) => '${e.label}: ${e.value}').join('\n');
      final files = <XFile>[];

      if (widget.file != null && includeFile) {
        final bytes = await widget.file!.load();
        if (bytes != null) {
          files.add(XFile.fromData(
            bytes,
            name: widget.file!.name,
          ));
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          title: widget.title,
          text: text.isEmpty ? widget.title : text,
          files: files,
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در اشتراک‌گذاری: $e')));
      }
    } finally {
      if (mounted) setState(() => sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Row(
      children: [
        const Icon(Icons.share_outlined),
        const SizedBox(width: 10),
        Expanded(child: Text('اشتراک‌گذاری ${widget.title}')),
      ],
    ),
    content: SizedBox(
      width: 520,
      child: ListView(
        shrinkWrap: true,
        children: [
          const Text('موارد مورد نیاز برای اشتراک‌گذاری را انتخاب کنید.'),
          const SizedBox(height: 10),
          ...widget.fields.map((field) => CheckboxListTile(
            value: field.selected,
            contentPadding: EdgeInsets.zero,
            title: Text(field.label),
            subtitle: Text(field.value, maxLines: 2, overflow: TextOverflow.ellipsis),
            onChanged: (v) => setState(() => field.selected = v ?? false),
          )),
          if (widget.file != null)
            CheckboxListTile(
              value: includeFile,
              contentPadding: EdgeInsets.zero,
              title: const Text('فایل مرتبط'),
              subtitle: Text(widget.file!.name),
              onChanged: sharing ? null : (v) => setState(() => includeFile = v ?? false),
            ),
        ],
      ),
    ),
    actions: [
      TextButton(onPressed: sharing ? null : () => Navigator.pop(context), child: const Text('انصراف')),
      FilledButton.icon(
        onPressed: sharing ? null : share,
        icon: sharing
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.share),
        label: const Text('اشتراک‌گذاری'),
      ),
    ],
  );
}
