import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karnamaft/services/scan_service.dart';

class MinuteFileEditor extends StatefulWidget {
  final String? file;

  final ValueChanged<String?> onChanged;

  final ValueChanged<Uint8List?>? onBytesChanged;
  final VoidCallback? onScan;

  const MinuteFileEditor({
    super.key,
    required this.file,
    required this.onChanged,
    this.onBytesChanged,
    this.onScan,
  });

  @override
  State<MinuteFileEditor> createState() => _MinuteFileEditorState();
}

class _MinuteFileEditorState extends State<MinuteFileEditor> {
  Future<void> pickFile(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ["pdf", "jpg", "jpeg", "png", "doc", "docx"],
      withData: kIsWeb,
    );

    if (result == null) {
      return;
    }

    final picked = result.files.single;

    if (picked.size > 20 * 1024 * 1024) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("حجم فایل نباید بیشتر از 20 مگابایت باشد"),
        ),
      );

      return;
    }

    if (kIsWeb) {
      widget.onChanged(picked.name);

      widget.onBytesChanged?.call(picked.bytes);
    } else {
      widget.onChanged(picked.path!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xffe4e8f0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.attach_file),
              const SizedBox(width: 8),
              Text(
                "فایل پیوست",
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (widget.file != null && widget.file!.isNotEmpty)
            ListTile(
              contentPadding: EdgeInsets.zero,

              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.description, color: Colors.blue),
              ),

              title: Text(
                widget.file!.split('/').last,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              trailing: IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () {
                  widget.onChanged(null);
                },
              ),
            )
          else
            const Text(
              "فایلی انتخاب نشده است",
              style: TextStyle(color: Colors.grey),
            ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.folder_open),
                  label: const Text("انتخاب فایل"),
                  onPressed: () {
                    pickFile(context);
                  },
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.document_scanner),
                  label: const Text("اسکن"),
                  onPressed: widget.onScan,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> scanFile() async {
    try {
      await ScanService.startScan();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطا در باز کردن اسکنر\n$e")));
    }
  }
}
