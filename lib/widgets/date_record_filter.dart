import 'package:flutter/material.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class DateRecordFilter extends StatelessWidget {
  final Map<String, String> values;

  final String field;

  final VoidCallback onChanged;

  const DateRecordFilter({
    super.key,
    required this.values,
    required this.field,
    required this.onChanged,
  });

  Future<void> pickDate(BuildContext context) async {
    final Jalali? date = await showJalaliDropdownDialog(context);

    if (date == null) return;

    final gregorian = date.toDateTime();

    values[field] =
        "${gregorian.year}-"
        "${gregorian.month.toString().padLeft(2, '0')}-"
        "${gregorian.day.toString().padLeft(2, '0')}";

    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.calendar_today),

      title: const Text("تاریخ"),

      subtitle: Text(values[field] ?? "همه تاریخ‌ها"),

      trailing: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          if (values.containsKey(field))
            IconButton(
              icon: const Icon(Icons.close),

              onPressed: () {
                values.remove(field);

                onChanged();
              },
            ),

          IconButton(
            icon: const Icon(Icons.edit_calendar),

            onPressed: () {
              pickDate(context);
            },
          ),
        ],
      ),
    );
  }
}
