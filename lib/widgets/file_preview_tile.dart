import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../models/record_file.dart';
import '../services/file_service.dart';
import 'file_viewer_page.dart';

class FilePreviewTile extends StatelessWidget {
  final RecordFile file;

  const FilePreviewTile({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    return _PreviewTile(
      title: file.title,
      fileName: file.fileName,
      future: FileService.download(file.url),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileViewerPage(
            title: file.title,
            fileName: file.fileName,
            future: FileService.download(file.url),
          ),
        ),
      ),
    );
  }
}

class LocalFilePreviewTile extends StatelessWidget {
  final String path;
  final VoidCallback? onRemove;

  const LocalFilePreviewTile({
    super.key,
    required this.path,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final fileName = path.split(RegExp(r'[/\\]')).last;
    return _PreviewTile(
      title: fileName,
      fileName: fileName,
      future: File(path).readAsBytes(),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileViewerPage(
            title: fileName,
            fileName: fileName,
            future: File(path).readAsBytes(),
          ),
        ),
      ),
      trailing: onRemove == null
          ? null
          : IconButton(
              tooltip: 'حذف',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
    );
  }
}


class MemoryFilePreviewTile extends StatelessWidget {
  final Uint8List bytes;
  final String fileName;
  final VoidCallback? onRemove;

  const MemoryFilePreviewTile({
    super.key,
    required this.bytes,
    required this.fileName,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return _PreviewTile(
      title: fileName,
      fileName: fileName,
      future: Future.value(bytes),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FileViewerPage(
            title: fileName,
            fileName: fileName,
            future: Future.value(bytes),
          ),
        ),
      ),
      trailing: onRemove == null
          ? null
          : IconButton(
              tooltip: 'حذف',
              onPressed: onRemove,
              icon: const Icon(Icons.close),
            ),
    );
  }
}

class _PreviewTile extends StatelessWidget {
  final String title;
  final String fileName;
  final Future<Uint8List?> future;
  final VoidCallback onTap;
  final Widget? trailing;

  const _PreviewTile({
    required this.title,
    required this.fileName,
    required this.future,
    required this.onTap,
    this.trailing,
  });

  bool get isImage {
    final ext = fileName.toLowerCase().split('.').last;
    return const ['jpg','jpeg','png','gif','bmp','webp'].contains(ext);
  }

  bool get isPdf => fileName.toLowerCase().endsWith('.pdf');

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 118,
        child: Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  color: Colors.grey.shade100,
                  child: FutureBuilder<Uint8List?>(
                    future: future,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        );
                      }
                      final bytes = snapshot.data;
                      if (bytes == null || bytes.isEmpty) {
                        return _fallback();
                      }
                      if (isImage) {
                        return Image.memory(
                          bytes,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => _fallback(),
                        );
                      }
                      if (isPdf) {
                        return SfPdfViewer.memory(
                          bytes,
                          pageLayoutMode: PdfPageLayoutMode.single,
                          canShowScrollHead: false,
                          canShowScrollStatus: false,
                          enableDoubleTapZooming: false,
                        );
                      }
                      return _fallback();
                    },
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }

  Widget _fallback() {
    final ext = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'FILE';
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isPdf ? Icons.picture_as_pdf_outlined : Icons.insert_drive_file_outlined,
            size: 42,
          ),
          const SizedBox(height: 4),
          Text(ext, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
