import 'package:flutter/material.dart';

import '../models/record_file.dart';
import 'file_preview_tile.dart';

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
          const Row(
            children: [
              Icon(Icons.attach_file),
              SizedBox(width: 8),
              Text(
                'پیش‌نمایش فایل‌ها',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final file in files) ...[
            FilePreviewTile(file: file),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
