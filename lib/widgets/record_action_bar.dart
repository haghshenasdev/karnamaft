import 'package:flutter/material.dart';
import 'package:karnamaft/widgets/record_more_sheet.dart';

class RecordActionBar extends StatelessWidget {
  final VoidCallback? onOpen;
  final VoidCallback? onFile;
  final VoidCallback? onRefer;
  final VoidCallback? onMore;
  final VoidCallback? onDelete;

  const RecordActionBar({
    super.key,
    this.onOpen,
    this.onFile,
    this.onRefer,
    this.onMore, this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        _ActionButton(
          icon: Icons.visibility_outlined,
          label: "مشاهده",
          color: color,
          onTap: onOpen,
        ),

        const SizedBox(width: 8),

        _ActionButton(
          icon: Icons.attach_file,
          label: "فایل",
          color: color,
          onTap: onFile,
        ),

        const SizedBox(width: 8),

        _ActionButton(
          icon: Icons.reply_outlined,
          label: "ارجاع",
          color: color,
          onTap: onRefer,
        ),

        const Spacer(),

        IconButton(
          tooltip: "بیشتر",
          icon: const Icon(Icons.more_vert),
          onPressed: () {
            showModalBottomSheet(
              context: context,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) {
                return RecordMoreSheet(
                  onView: onOpen,
                  onEdit: () {},
                  onPrint: () {},
                  onPdf: () {},
                  onShare: () {},
                  onDelete: onDelete,
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(30),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
