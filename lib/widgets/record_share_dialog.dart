import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

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
  List<ShareFile> files = const [],
}) async {
  final allFiles = <ShareFile>[
    if (file != null) file,
    ...files,
  ];
  await showDialog(
    context: context,
    builder: (context) => _RecordShareDialog(
      title: title,
      fields: fields,
      files: allFiles,
    ),
  );
}

class _RecordShareDialog extends StatefulWidget {
  final String title;
  final List<ShareField> fields;
  final List<ShareFile> files;

  const _RecordShareDialog({
    required this.title,
    required this.fields,
    required this.files,
  });

  @override
  State<_RecordShareDialog> createState() => _RecordShareDialogState();
}

class _RecordShareDialogState extends State<_RecordShareDialog> {
  bool sharing = false;
  bool includeFile = true;

  Future<void> share() async {
    final selected = widget.fields.where((e) => e.selected && e.value.trim().isNotEmpty).toList();
    if (selected.isEmpty && widget.files.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حداقل یک مورد را انتخاب کنید.')));
      return;
    }

    setState(() => sharing = true);
    try {
      final text = selected.map((e) => '${e.label}: ${e.value}').join('\n');
      final shareText = text.isEmpty ? widget.title : text;
      // متن قبل از بازشدن پنجره اشتراک‌گذاری در کلیپ‌بورد نیز قرار می‌گیرد.
      await Clipboard.setData(ClipboardData(text: shareText));
      final sharedFiles = <XFile>[];

      if (includeFile && widget.files.isNotEmpty) {
        final loaded = <({String name, Uint8List bytes})>[];
        for (final item in widget.files) {
          final bytes = await item.load();
          if (bytes != null && bytes.isNotEmpty) {
            loaded.add((name: _safeFileName(item.name), bytes: bytes));
          }
        }

        final imageFiles = loaded.where((e) => _isImageName(e.name)).toList();

        // چند تصویر به یک PDF چندصفحه‌ای تبدیل می‌شود تا اندروید/Share
        // آن‌ها را به صورت یک سند واحد دریافت کند.
        if (imageFiles.length > 1 && imageFiles.length == loaded.length) {
          final pdf = pw.Document();
          for (final item in imageFiles) {
            final image = pw.MemoryImage(item.bytes);
            pdf.addPage(
              pw.Page(
                pageFormat: PdfPageFormat.a4,
                margin: pw.EdgeInsets.zero,
                build: (_) => pw.SizedBox(
                  width: PdfPageFormat.a4.width,
                  height: PdfPageFormat.a4.height,
                  child: pw.Image(image, fit: pw.BoxFit.contain),
                ),
              ),
            );
          }
          final pdfBytes = Uint8List.fromList(await pdf.save());
          sharedFiles.add(XFile.fromData(
            pdfBytes,
            name: '${_safeFileName(widget.title)}_تصاویر.pdf',
            mimeType: 'application/pdf',
          ));
        } else {
          for (final item in loaded) {
            sharedFiles.add(XFile.fromData(
              item.bytes,
              name: item.name,
              mimeType: _mimeTypeFor(item.name),
            ));
          }
        }
      }

      await SharePlus.instance.share(
        ShareParams(
          title: widget.title,
          text: shareText,
          files: sharedFiles,
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

  String _safeFileName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'attachment';
    // اگر نام فایل از سرور بدون پسوند برگشته باشد، پسوند ساختگی اضافه نمی‌کنیم؛
    // MIME نوع فایل را به سیستم اشتراک‌گذاری معرفی می‌کند.
    return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  }

  bool _isImageName(String name) {
    final ext = name.split('.').last.toLowerCase();
    return const ['jpg', 'jpeg', 'png', 'webp', 'gif', 'bmp'].contains(ext);
  }

  String _mimeTypeFor(String name) {
    switch (name.split('.').last.toLowerCase()) {
      case 'pdf': return 'application/pdf';
      case 'png': return 'image/png';
      case 'jpg':
      case 'jpeg': return 'image/jpeg';
      case 'webp': return 'image/webp';
      case 'gif': return 'image/gif';
      case 'txt': return 'text/plain';
      case 'doc': return 'application/msword';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case 'xls': return 'application/vnd.ms-excel';
      case 'xlsx': return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case 'zip': return 'application/zip';
      default: return 'application/octet-stream';
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
          if (widget.files.isNotEmpty) ...[
            CheckboxListTile(
              value: includeFile,
              contentPadding: EdgeInsets.zero,
              title: Text('فایل‌ها (${widget.files.length})'),
              subtitle: Text(
                widget.files.map((e) => e.name).join('، '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onChanged: sharing ? null : (v) => setState(() => includeFile = v ?? false),
            ),
            SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: widget.files.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (_, index) => _SharePreview(
                  file: widget.files[index],
                ),
              ),
            ),
          ],
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


class _SharePreview extends StatelessWidget {
  final ShareFile file;

  const _SharePreview({required this.file});

  bool get isImage {
    final ext = file.name.split('.').last.toLowerCase();
    return const ['jpg','jpeg','png','gif','bmp','webp'].contains(ext);
  }

  bool get isPdf => file.name.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: file.load(),
      builder: (context, snapshot) {
        final bytes = snapshot.data;
        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 86,
            height: 92,
            color: Colors.grey.shade100,
            child: bytes == null
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
                : isImage
                    ? Image.memory(bytes, fit: BoxFit.cover)
                    : isPdf
                        ? SfPdfViewer.memory(
                            bytes,
                            pageLayoutMode: PdfPageLayoutMode.single,
                            canShowScrollHead: false,
                            canShowScrollStatus: false,
                          )
                        : const Center(child: Icon(Icons.insert_drive_file, size: 38)),
          ),
        );
      },
    );
  }
}
