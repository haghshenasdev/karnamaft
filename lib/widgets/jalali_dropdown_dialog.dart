import 'package:flutter/material.dart';
import 'package:shamsi_date/shamsi_date.dart';

Future<Jalali?> showJalaliDropdownDialog(
  BuildContext context, {
  Jalali? initialDate,
  int firstYear = 1390,
  int lastYear = 1450,
}) {
  return showDialog<Jalali>(
    context: context,
    builder: (_) => _JalaliDropdownDialog(
      initialDate: initialDate ?? Jalali.now(),
      firstYear: firstYear,
      lastYear: lastYear,
    ),
  );
}

class _JalaliDropdownDialog extends StatefulWidget {
  final Jalali initialDate;
  final int firstYear;
  final int lastYear;

  const _JalaliDropdownDialog({
    required this.initialDate,
    required this.firstYear,
    required this.lastYear,
  });

  @override
  State<_JalaliDropdownDialog> createState() => _JalaliDropdownDialogState();
}

class _JalaliDropdownDialogState extends State<_JalaliDropdownDialog> {
  static const months = [
    '1-فروردین',
    '2-اردیبهشت',
    '3-خرداد',
    '4-تیر',
    '5-مرداد',
    '6-شهریور',
    '7-مهر',
    '8-آبان',
    '9-آذر',
    '10-دی',
    '11-بهمن',
    '12-اسفند',
  ];

  late int year;
  late int month;
  late int day;

  @override
  void initState() {
    super.initState();
    year = widget.initialDate.year;
    month = widget.initialDate.month;
    day = widget.initialDate.day;
  }

  int get daysInMonth {
    return Jalali(year, month).monthLength;
  }

  @override
  Widget build(BuildContext context) {
    if (day > daysInMonth) {
      day = daysInMonth;
    }

    return AlertDialog(
      title: const Text("انتخاب تاریخ"),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<int>(
              value: year,
              decoration: const InputDecoration(labelText: "سال"),
              items: [
                for (int y = widget.firstYear; y <= widget.lastYear; y++)
                  DropdownMenuItem(value: y, child: Text("$y")),
              ],
              onChanged: (v) {
                setState(() => year = v!);
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: month,
              decoration: const InputDecoration(labelText: "ماه"),
              items: [
                for (int i = 1; i <= 12; i++)
                  DropdownMenuItem(value: i, child: Text(months[i - 1])),
              ],
              onChanged: (v) {
                setState(() => month = v!);
              },
            ),

            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              value: day,
              decoration: const InputDecoration(labelText: "روز"),
              items: [
                for (int d = 1; d <= daysInMonth; d++)
                  DropdownMenuItem(value: d, child: Text("$d")),
              ],
              onChanged: (v) {
                setState(() => day = v!);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
          },
          child: const Text("انصراف"),
        ),

        FilledButton(
          onPressed: () {
            Navigator.pop(context, Jalali(year, month, day));
          },
          child: const Text("تأیید"),
        ),
      ],
    );
  }
}
