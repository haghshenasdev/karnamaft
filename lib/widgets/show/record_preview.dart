import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class RecordPreview extends StatelessWidget {
  final String? file;

  const RecordPreview({
    super.key,
    this.file,
  });

  bool get hasFile => file != null && file!.trim().isNotEmpty;

  String get extension {
    if (!hasFile) return "";

    final uri = Uri.parse(file!);

    final name = uri.path.toLowerCase();

    if (!name.contains(".")) {
      return "";
    }

    return name.split(".").last;
  }

  bool get isImage =>
      [
        "jpg",
        "jpeg",
        "png",
        "gif",
        "bmp",
        "webp",
      ].contains(extension);

  bool get isPdf => extension == "pdf";

  bool get isWord =>
      extension == "doc" ||
      extension == "docx";

  Future<void> openFile() async {
    if (!hasFile) return;

    final uri = Uri.parse(file!);

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!hasFile) {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
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
      return Card(
        elevation: 0,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SizedBox(
          height: 260,
          width: double.infinity,
          child: CachedNetworkImage(
            imageUrl: file!,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(),
            ),
            errorWidget: (_, __, ___) => const Center(
              child: Icon(
                Icons.broken_image,
                size: 60,
              ),
            ),
          ),
        ),
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
        onTap: openFile,
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
        onTap: openFile,
      );
    }

    //--------------------------------------------------
    // Other
    //--------------------------------------------------

    return _FileCard(
      icon: Icons.insert_drive_file,
      color: theme.colorScheme.primary,
      title: "فایل پیوست",
      subtitle: file!,
      onTap: openFile,
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 230,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 80,
                color: color,
              ),

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

              const SizedBox(height: 20),

              FilledButton.icon(
                onPressed: onTap,
                icon: const Icon(Icons.open_in_new),
                label: const Text("باز کردن"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}