import 'package:flutter/material.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/widgets/file_viewer_page.dart';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../services/minute_service.dart';

class RecordPreview extends StatelessWidget {
  final MinuteModel minute;

  const RecordPreview({super.key, required this.minute});

  final MinuteService _service = const MinuteService();

  bool get hasFile => minute.file != null && minute.file!.trim().isNotEmpty;

  String get extension {
    if (!hasFile) return "";

    final uri = Uri.parse(minute.file!);

    final name = uri.path.toLowerCase();

    if (!name.contains(".")) {
      return "";
    }

    return name.split(".").last;
  }

  bool get isImage =>
      ["jpg", "jpeg", "png", "gif", "bmp", "webp"].contains(extension);

  bool get isPdf => extension == "pdf";

  bool get isWord => extension == "doc" || extension == "docx";

  void openFile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FileViewerPage(
          title: minute.title,
          fileName: minute.file!,
          future: _service.getFile(minute.id, minute.file),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasFile) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          height: 230,
          alignment: Alignment.center,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(
                Icons.insert_drive_file_outlined,
                size: 70,
                color: Colors.grey,
              ),
              SizedBox(height: 12),
              Text("فایلی برای نمایش وجود ندارد"),
            ],
          ),
        ),
      );
    }

    //--------------------------------------------------
    // Image
    //--------------------------------------------------

    if (isImage) {
      return FutureBuilder<Uint8List?>(
        future: _service.getFile(minute.id, minute.file),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError || snapshot.data == null) {
            return Card(
              child: SizedBox(
                height: 260,
                child: const Center(child: Icon(Icons.broken_image, size: 70)),
              ),
            );
          }

          return Card(
            elevation: 0,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: () => openFile(context),
              child: SizedBox(
                height: 260,
                width: double.infinity,
                child: Image.memory(snapshot.data!, fit: BoxFit.cover),
              ),
            ),
          );
        },
      );
    }
    //--------------------------------------------------
    // PDF
    //--------------------------------------------------

    if (isPdf) {
      return _FileCard(
        icon: Icons.picture_as_pdf,
        color: Colors.red,
        title: "فایل PDF",
        subtitle: "برای مشاهده فایل لمس کنید",
        onTap: () => openFile(context),
      );
    }

    //--------------------------------------------------
    // Word
    //--------------------------------------------------

    if (isWord) {
      return _FileCard(
        icon: Icons.description,
        color: Colors.blue,
        title: "فایل Word",
        subtitle: "برای مشاهده فایل لمس کنید",
        onTap: () => openFile(context),
      );
    }

    //--------------------------------------------------
    // Other
    //--------------------------------------------------

    return _FileCard(
      icon: Icons.insert_drive_file,
      color: theme.colorScheme.primary,
      title: "فایل پیوست",
      subtitle: minute.file!,
      onTap: () => openFile(context),
    );
  }
}

class _FileCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FileCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 230,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 80, color: color),

              const SizedBox(height: 20),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                subtitle,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              // const SizedBox(height: 20),

              // FilledButton.icon(
              //   onPressed: onTap,
              //   icon: const Icon(Icons.open_in_new),
              //   label: const Text("باز کردن"),
              // ),
            ],
          ),
        ),
      ),
    );
  }
}
