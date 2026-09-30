import 'package:flutter/material.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/content_group_service.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';

class ContentGroupFilter extends StatelessWidget {
  final Map<String, String> values;
  final String field;
  final VoidCallback onChanged;

  const ContentGroupFilter({
    super.key,
    required this.values,
    required this.field,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final label = values['__label__$field'] ?? '';
    final selected = values[field] ?? '';

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final result = await showDialog<List<RecordItem>>(
          context: context,
          builder: (_) => SelectRecordDialog(
            service: const ContentGroupService(),
            config: const SelectDialogConfig(
              title: 'دسته‌بندی یادداشت‌ها',
              multiSelect: true,
              historyKey: 'content_groups_filter',
            ),
          ),
        );

        if (result == null) return;

        if (result.isEmpty) {
          values.remove(field);
          values.remove('__label__$field');
        } else {
          values[field] = result.map((e) => e.id).join(',');
          values['__label__$field'] = result.map((e) => e.title).join('، ');
        }

        onChanged();
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'دسته‌بندی',
          prefixIcon: const Icon(Icons.label_outline),
          suffixIcon: selected.isEmpty
              ? const Icon(Icons.keyboard_arrow_down)
              : IconButton(
                  tooltip: 'حذف فیلتر دسته‌بندی',
                  onPressed: () {
                    values.remove(field);
                    values.remove('__label__$field');
                    onChanged();
                  },
                  icon: const Icon(Icons.clear),
                ),
          border: const OutlineInputBorder(),
        ),
        child: Text(
          label.isEmpty ? 'همه دسته‌بندی‌ها' : label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
