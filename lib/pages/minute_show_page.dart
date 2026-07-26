import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/models/minute_model.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/widgets/show/record_field.dart';

import '../widgets/show/record_info_card.dart';
import '../widgets/show/record_preview.dart';
import '../widgets/show/record_text.dart';
import '../widgets/show/record_title.dart';

class MinuteShowPage extends StatefulWidget {
  final int id;

  const MinuteShowPage({super.key, required this.id});

  @override
  State<MinuteShowPage> createState() => _MinuteShowPageState();
}

class _MinuteShowPageState extends State<MinuteShowPage> {
  //--------------------------------------------------
  // Service
  //--------------------------------------------------

  final MinuteService _service = const MinuteService();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool loading = true;

  String? error;

  MinuteModel? minute;

  //--------------------------------------------------
  // Init
  //--------------------------------------------------

  @override
  void initState() {
    super.initState();

    loadData();
  }

  //--------------------------------------------------
  // Load
  //--------------------------------------------------

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await _service.show(widget.id);

      if (!mounted) return;

      setState(() {
        minute = result;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
        error = e.toString();
      });
    }
  }

  //--------------------------------------------------
  // Date
  //--------------------------------------------------

  String formatDate(DateTime? date) {
    if (date == null) {
      return "-";
    }

    return DateFormat("yyyy/MM/dd HH:mm").format(date);
  }

  //--------------------------------------------------
  // UI
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    //--------------------------------------------------
    // Loading
    //--------------------------------------------------

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("نمایش رکورد")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    //--------------------------------------------------
    // Error
    //--------------------------------------------------

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text("نمایش رکورد")),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 70, color: Colors.red),

                const SizedBox(height: 20),

                Text(error!, textAlign: TextAlign.center),

                const SizedBox(height: 20),

                FilledButton.icon(
                  onPressed: loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text("تلاش مجدد"),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final item = minute!;

    //--------------------------------------------------
    // Success
    //--------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(title: const Text("نمایش رکورد"), centerTitle: false),

      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              //--------------------------------------------------
              // Preview
              //--------------------------------------------------
              RecordPreview(file: item.file),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Title
              //--------------------------------------------------
              RecordTitle(title: item.title),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Text
              //--------------------------------------------------
              RecordText(text: item.text),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Information Card
              //--------------------------------------------------
              RecordInfoCard(
                children: [
                  if (item.id > 0)
                    RecordField(title: "شناسه", value: item.id.toString()),

                  if (item.date != null)
                    RecordField(title: "تاریخ", value: formatDate(item.date)),

                  if (item.typer_id != null)
                    RecordField(
                      title: "تایپیست",
                      value: item.typer_id.toString(),
                    ),

                  if (item.task_id != null)
                    RecordField(title: "وظیفه", value: item.task_id.toString()),

                  if (item.created_at != null)
                    RecordField(
                      title: "ایجاد شده",
                      value: formatDate(item.created_at),
                    ),

                  if (item.updated_at != null)
                    RecordField(
                      title: "آخرین بروزرسانی",
                      value: formatDate(item.updated_at),
                    ),
                ],
              ),

              const SizedBox(height: 24),

              //--------------------------------------------------
              // Actions
              //--------------------------------------------------
              FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text("بازگشت"),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
