import 'package:flutter/material.dart';
import '../models/record_file.dart';
import '../services/file_service.dart';
import 'file_viewer_page.dart';

class RecordFilesCard extends StatelessWidget {
  final List<RecordFile> files;

  const RecordFilesCard({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    if (files.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xffe5e9f2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.attach_file),
            SizedBox(width: 8),
            Text('فایل‌ها', style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          ...files.map((file) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.insert_drive_file_outlined),
            title: Text(file.title, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(file.extension.isEmpty ? 'فایل' : file.extension.toUpperCase()),
            trailing: const Icon(Icons.open_in_new),
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
          )),
        ],
      ),
    );
  }
}
