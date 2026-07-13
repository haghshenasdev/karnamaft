import 'package:flutter/material.dart';

class RecordMoreSheet extends StatelessWidget {
  final VoidCallback? onView;
  final VoidCallback? onEdit;
  final VoidCallback? onPrint;
  final VoidCallback? onPdf;
  final VoidCallback? onShare;
  final VoidCallback? onDelete;

  const RecordMoreSheet({
    super.key,
    this.onView,
    this.onEdit,
    this.onPrint,
    this.onPdf,
    this.onShare,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),

            ListTile(
              leading: const Icon(Icons.visibility_outlined),
              title: const Text("مشاهده"),
              onTap: () {
                Navigator.pop(context);
                onView?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text("ویرایش"),
              onTap: () {
                Navigator.pop(context);
                onEdit?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.print_outlined),
              title: const Text("چاپ"),
              onTap: () {
                Navigator.pop(context);
                onPrint?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text("خروجی PDF"),
              onTap: () {
                Navigator.pop(context);
                onPdf?.call();
              },
            ),

            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text("اشتراک گذاری"),
              onTap: () {
                Navigator.pop(context);
                onShare?.call();
              },
            ),

            const Divider(),

            ListTile(
              iconColor: Colors.red,
              textColor: Colors.red,
              leading: const Icon(Icons.delete_outline),
              title: const Text("حذف"),
              onTap: () {
                Navigator.pop(context);
                onDelete?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}
