import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import 'letter_create_page.dart';
import 'minute_create_page.dart';
import 'task_create_page.dart';

class IncomingSharePage extends StatefulWidget {
  final List<String> filePaths;

  IncomingSharePage({
    super.key,
    String? filePath,
    List<String>? filePaths,
  }) : filePaths = _normalizePaths(
         filePaths: filePaths,
         filePath: filePath,
       );

  static List<String> _normalizePaths({
    List<String>? filePaths,
    String? filePath,
  }) {
    if (filePaths != null && filePaths.isNotEmpty) {
      return List<String>.from(filePaths);
    }

    if (filePath != null && filePath.trim().isNotEmpty) {
      return <String>[filePath];
    }

    return <String>[];
  }

  @override
  State<IncomingSharePage> createState() => _IncomingSharePageState();
}

class _IncomingSharePageState extends State<IncomingSharePage> {
  Uint8List? bytes;

  String? effectiveFilePath;
  String? generatedPdfPath;

  List<String> validPaths = <String>[];

  bool loading = true;
  String? error;

  List<String> get paths => widget.filePaths;

  @override
  void initState() {
    super.initState();
    _load();
  }

  bool _isImage(String path) {
    final lower = path.toLowerCase();

    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.bmp') ||
        lower.endsWith('.heic') ||
        lower.endsWith('.heif');
  }

  bool _isPdf(String path) {
    return path.toLowerCase().endsWith('.pdf');
  }

  String _name(String path) {
    return path.split(RegExp(r'[/\\]')).last;
  }

  Future<void> _load() async {
    try {
      final valid = <String>[];

      for (final path in paths) {
        final trimmed = path.trim();

        if (trimmed.isEmpty) continue;

        final file = File(trimmed);

        if (await file.exists()) {
          valid.add(trimmed);
        }
      }

      if (valid.isEmpty) {
        throw Exception('فایل دریافت‌شده پیدا نشد.');
      }

      validPaths = valid;

      /*
       * اگر بیش از یک فایل دریافت شده باشد:
       *
       * - اگر همه تصویر باشند → یک PDF چندصفحه‌ای ساخته می‌شود.
       * - اگر ترکیبی از PDF و تصویر باشد → فعلاً تصاویر به PDF تبدیل
       *   می‌شوند و PDF موجود نیز به صورت فایل اصلی باقی می‌ماند.
       *
       * برای Share از Gallery معمولاً حالت اول اتفاق می‌افتد.
       */
      if (valid.length > 1 && valid.every(_isImage)) {
        await _createPdfFromImages(valid);
      } else if (valid.length == 1) {
        effectiveFilePath = valid.first;
        bytes = await File(valid.first).readAsBytes();
      } else {
        /*
         * چند فایل غیرتصویری:
         *
         * اگر PDF بین فایل‌ها وجود دارد، اولین PDF را انتخاب می‌کنیم.
         * این حالت بیشتر برای Share چند PDF کاربرد دارد.
         */
        final pdfPath = valid.cast<String?>().firstWhere(
          (path) => path != null && _isPdf(path),
          orElse: () => null,
        );

        if (pdfPath != null) {
          effectiveFilePath = pdfPath;
          bytes = await File(pdfPath).readAsBytes();
        } else {
          effectiveFilePath = valid.first;
          bytes = await File(valid.first).readAsBytes();
        }
      }
    } catch (e) {
      error = e.toString();
    }

    if (!mounted) return;

    setState(() {
      loading = false;
    });
  }

  Future<void> _createPdfFromImages(List<String> imagePaths) async {
    final pdf = pw.Document();

    for (final path in imagePaths) {
      final data = await File(path).readAsBytes();

      final image = pw.MemoryImage(data);

      const pageFormat = PdfPageFormat.a4;

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          margin: pw.EdgeInsets.zero,
          build: (_) {
            return pw.Container(
              width: pageFormat.width,
              height: pageFormat.height,
              alignment: pw.Alignment.center,
              child: pw.Image(
                image,
                fit: pw.BoxFit.contain,
                alignment: pw.Alignment.center,
              ),
            );
          },
        ),
      );
    }

    final dir = await getTemporaryDirectory();

    final stamp = DateTime.now().millisecondsSinceEpoch;

    final file = File(
      '${dir.path}/karnama_shared_$stamp.pdf',
    );

    final pdfBytes = await pdf.save();

    await file.writeAsBytes(
      pdfBytes,
      flush: true,
    );

    generatedPdfPath = file.path;
    effectiveFilePath = file.path;
    bytes = Uint8List.fromList(pdfBytes);
  }

  Future<void> _openCreate(Widget page) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => page,
      ),
    );

    if (!mounted || result == null) return;

    await _cleanup();

    if (!mounted) return;

    Navigator.pop(context, result);
  }

  Future<void> _cleanup() async {
    final all = <String>{
      ...paths,
      ...validPaths,
      if (generatedPdfPath != null) generatedPdfPath!,
    };

    for (final path in all) {
      try {
        final file = File(path);

        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // فایل ممکن است توسط فرم مقصد منتقل شده باشد.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = effectiveFilePath;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ثبت فایل دریافت‌شده'),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : error != null
          ? _buildError()
          : _buildContent(currentPath),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
            ),
            const SizedBox(height: 12),
            Text(
              error!,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () {
                setState(() {
                  loading = true;
                  error = null;
                });

                _load();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('تلاش مجدد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(String? currentPath) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildPreview(),

        const SizedBox(height: 14),

        if (validPaths.length > 1 && generatedPdfPath != null)
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
              ),
              title: const Text(
                'تصاویر به یک PDF تبدیل شدند',
              ),
              subtitle: Text(
                '${validPaths.length} تصویر',
              ),
            ),
          ),

        const SizedBox(height: 10),

        const Text(
          'این فایل را در کدام بخش ثبت می‌کنید؟',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),

        const SizedBox(height: 10),

        _Action(
          icon: Icons.mail_outline,
          title: 'ایجاد نامه',
          subtitle:
              'فایل آماده‌شده به عنوان فایل اصلی نامه قرار می‌گیرد.',
          onTap: currentPath == null
              ? null
              : () {
                  _openCreate(
                    LetterCreatePage(
                      initialFilePath: currentPath,
                    ),
                  );
                },
        ),

        _Action(
          icon: Icons.description_outlined,
          title: 'ایجاد صورتجلسه',
          subtitle:
              'فایل آماده‌شده در فرم صورتجلسه قرار می‌گیرد.',
          onTap: bytes == null
              ? null
              : () {
                  _openCreate(
                    MinuteCreatePage(
                      initialFileBytes: bytes,
                      initialFileName: currentPath == null
                          ? 'shared.pdf'
                          : _name(currentPath),
                    ),
                  );
                },
        ),

        _Action(
          icon: Icons.task_alt,
          title: 'ایجاد فعالیت',
          subtitle:
              'فایل آماده‌شده به عنوان پیوست فعالیت اضافه می‌شود.',
          onTap: currentPath == null
              ? null
              : () {
                  _openCreate(
                    TaskCreatePage(
                      initialFilePath: currentPath,
                    ),
                  );
                },
        ),
      ],
    );
  }

  Widget _buildPreview() {
    final data = bytes;

    if (data == null) {
      return const SizedBox.shrink();
    }

    final path = effectiveFilePath ?? '';

    final isPdf =
        _isPdf(path) ||
        (
          data.length >= 4 &&
          data[0] == 0x25 &&
          data[1] == 0x50 &&
          data[2] == 0x44 &&
          data[3] == 0x46
        );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: 420,
        width: double.infinity,
        child: isPdf
            ? SfPdfViewer.memory(
                data,
                pageLayoutMode:
                    PdfPageLayoutMode.single,
                canShowScrollHead: true,
                canShowScrollStatus: true,
              )
            : Image.memory(
                data,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) {
                  return const Center(
                    child: Icon(
                      Icons.insert_drive_file_outlined,
                      size: 80,
                    ),
                  );
                },
              ),
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
        trailing: const Icon(
          Icons.chevron_left,
        ),
        onTap: onTap,
      ),
    );
  }
}
