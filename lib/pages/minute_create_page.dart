import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/models/login_request.dart';
import 'package:karnamaft/models/minute_relation.dart';
import 'package:karnamaft/models/minutes_group_model.dart';
import 'package:karnamaft/models/minutes_group_service.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/minute_ps_service.dart';
import 'package:karnamaft/services/minute_service.dart';
import 'package:karnamaft/services/organ_service.dart';
import 'package:karnamaft/services/scan_service.dart';
import 'package:karnamaft/services/task_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/minute_file_editor.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';
import 'package:karnamaft/widgets/show/record_info_card.dart';
import 'package:karnamaft/widgets/show/record_field.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

import '../models/minute_model.dart';

class MinuteCreatePage extends StatefulWidget {
  final Uint8List? initialFileBytes;
  final String? initialFileName;

  const MinuteCreatePage({
    super.key,
    this.initialFileBytes,
    this.initialFileName,
  });

  @override
  State<MinuteCreatePage> createState() => _MinuteCreatePageState();
}

class _MinuteCreatePageState extends State<MinuteCreatePage>
    with WidgetsBindingObserver {
  final MinuteService _service = const MinuteService();

  Uint8List? selectedFileBytes;
  CancelToken? _processCancelToken;

  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final titleController = TextEditingController();

  final textController = TextEditingController();

  final dateController = TextEditingController();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  String? selectedFile;
  final MinutePsService _psService = const MinutePsService();
  bool processingFile = false;

  String processingMessage = "";

  bool saving = false;
  bool waitingForScan = false;

  DateTime selectedDate = DateTime.now();

  List<OrganModel> selectedOrgans = [];

  TaskCreator? selectedTask;

  List<MinutesGroupModel> selectedGroups = [];

  String? error;

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    titleController.dispose();

    textController.dispose();

    dateController.dispose();

    super.dispose();
  }

  @override
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    dateController.text = DateFormat("yyyy-MM-dd").format(selectedDate);

    if (widget.initialFileBytes != null) {
      selectedFileBytes = widget.initialFileBytes;
      selectedFile = widget.initialFileName;

      Future.microtask(() {
        if (mounted) {
          processSelectedFile();
        }
      });
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (!waitingForScan || !ScanService.isWaitingForScan) {
      return;
    }

    waitingForScan = false;

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("در حال یافتن فایل اسکن شده...")),
    );

    try {
      final file = await ScanService.processReturnedScan();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('۳ - نتیجه: $file')));

      if (!mounted) {
        return;
      }

      if (file == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("فایلی از اسکن پیدا نشد")));

        return;
      }

      setState(() {
        selectedFile = file;
        selectedFileBytes = null;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("فایل اسکن شده اضافه شد")));

      await processSelectedFile();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در دریافت فایل اسکن شده\n$e")),
      );
    }
  }

  Future<void> startScan() async {
    try {
      waitingForScan = true;

      await ScanService.startScan();
    } catch (e) {
      waitingForScan = false;
      ScanService.cancel();

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("خطا در باز کردن اسکنر\n$e")));
    }
  }

  //--------------------------------------------------
  // Date
  //--------------------------------------------------

  Future<void> selectDate() async {
    final jalali = await showJalaliDropdownDialog(
      context,

      initialDate: Jalali.fromDateTime(selectedDate),
    );

    if (jalali == null) {
      return;
    }

    final gregorian = jalali.toDateTime();

    setState(() {
      selectedDate = gregorian;

      dateController.text = DateFormat("yyyy-MM-dd").format(gregorian);
    });
  }

  //--------------------------------------------------
  // Save
  //--------------------------------------------------

  Future<void> save() async {
    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("عنوان الزامی است")));

      return;
    }

    setState(() {
      saving = true;

      error = null;
    });

    try {
      final model = MinuteModel(
        id: 0,

        title: titleController.text,

        text: textController.text,

        date: selectedDate,

        file: selectedFile,
        task_id: selectedTask?.id,
        organs: selectedOrgans,
        group: selectedGroups,
      );

      final result = await _service.create(
        model,
        uploadFile: selectedFile,
        uploadBytes: selectedFileBytes,
        uploadFileName: widget.initialFileName,
      );

      if (!mounted) return;

      Navigator.pop(context, result);
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(title: const Text("ایجاد صورتجلسه"), centerTitle: false),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,

          children: [
            //--------------------------------------------------
            // File
            //--------------------------------------------------
            MinuteFileEditor(
              file: selectedFile,

              onChanged: (value) {
                setState(() {
                  selectedFile = value;
                  selectedFileBytes = null;
                });

                if (value != null) {
                  Future.microtask(() {
                    processSelectedFile();
                  });
                }
              },

              onBytesChanged: (bytes) {
                selectedFileBytes = bytes;

                if (bytes != null) {
                  Future.microtask(() {
                    processSelectedFile();
                  });
                }
              },

              onScan: startScan,
            ),

            const SizedBox(height: 12),

            if (processingFile)
              Container(
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),

                child: Row(
                  children: [
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),

                    const SizedBox(width: 16),

                    Expanded(child: Text(processingMessage)),

                    IconButton(
                      tooltip: "لغو پردازش",
                      icon: const Icon(Icons.cancel, color: Colors.red),
                      onPressed: cancelProcessing,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            //--------------------------------------------------
            // Title
            //--------------------------------------------------
            TextField(
              controller: titleController,
              minLines: 1,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "عنوان",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: const Icon(Icons.title),
                suffixIcon: titleController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          titleController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Text
            //--------------------------------------------------
            TextField(
              controller: textController,
              minLines: 5,
              maxLines: 15,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: "متن صورتجلسه",
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 120),
                  child: Icon(Icons.notes),
                ),
                suffixIcon: textController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          textController.clear();
                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Information
            //--------------------------------------------------
            RecordInfoCard(
              children: [
                TextField(
                  controller: dateController,

                  readOnly: true,

                  onTap: selectDate,

                  decoration: InputDecoration(
                    labelText: "تاریخ",

                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month),

                      onPressed: selectDate,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "جلسه",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: selectTask,
                        ),
                      ],
                    ),

                    if (selectedTask != null)
                      Chip(
                        label: Text(selectedTask!.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            selectedTask = null;
                          });
                        },
                      ),
                  ],
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "امضا کنندگان",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: selectSigner,
                        ),
                      ],
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedOrgans.map((e) {
                        return Chip(
                          label: Text(e.name),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              selectedOrgans.removeWhere((x) => x.id == e.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          "دسته بندی",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.add_circle),
                          onPressed: selectGroup,
                        ),
                      ],
                    ),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: selectedGroups.map((e) {
                        return Chip(
                          label: Text(e.name),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              selectedGroups.removeWhere((x) => x.id == e.id);
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 25),

            if (error != null)
              Container(
                padding: const EdgeInsets.all(12),

                margin: const EdgeInsets.only(bottom: 16),

                decoration: BoxDecoration(
                  color: Colors.red.shade50,

                  borderRadius: BorderRadius.circular(12),
                ),

                child: Text(error!, style: const TextStyle(color: Colors.red)),
              ),

            //--------------------------------------------------
            // Save Button
            //--------------------------------------------------
            SizedBox(
              height: 52,

              child: FilledButton.icon(
                icon: saving
                    ? const SizedBox(
                        width: 22,

                        height: 22,

                        child: CircularProgressIndicator(
                          strokeWidth: 2,

                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),

                label: Text(saving ? "در حال ثبت..." : "ثبت صورتجلسه"),

                onPressed: saving ? null : save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> processSelectedFile() async {
    _processCancelToken = CancelToken();

    setState(() {
      processingFile = true;
      processingMessage = "در حال خواندن متن فایل...";
      error = null;
    });

    try {
      final result = await _psService.processFile(
        filePath: selectedFile,
        bytes: selectedFileBytes,
        fileName: widget.initialFileName ?? "note.png",
        cancelToken: _processCancelToken,
      );

      if (!mounted) return;

      setState(() {
        titleController.text = result.title;

        textController.text = result.text;

        processingMessage = "پردازش فایل با موفقیت انجام شد";
      });
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        setState(() {
          processingMessage = "پردازش لغو شد";
        });

        return;
      }

      setState(() {
        processingMessage = "خطا در پردازش فایل";

        error = e.toString();
      });
    } catch (e) {
      setState(() {
        processingMessage = "خطا در پردازش فایل";

        error = e.toString();
      });
    } finally {
      _processCancelToken = null;

      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        setState(() {
          processingFile = false;

          processingMessage = "";
        });
      });
    }
  }

  Future<void> selectTask() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const TaskService(),
        config: const SelectDialogConfig(
          title: "انتخاب جلسه",
          multiSelect: false,
          historyKey: "minute_tasks",
        ),
      ),
    );

    if (result == null) return;

    final item = result as RecordItem;

    setState(() {
      selectedTask = TaskCreator(id: item.id, name: item.title);
    });
  }

  Future<void> selectSigner() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const OrganService(),
        config: const SelectDialogConfig(
          title: "انتخاب امضا کنندگان",
          multiSelect: true,
          historyKey: "minute_signers",
        ),
      ),
    );

    if (result == null) return;

    final items = result as List<RecordItem>;

    setState(() {
      for (final item in items) {
        if (selectedOrgans.every((e) => e.id != item.id)) {
          selectedOrgans.add(OrganModel(id: item.id, name: item.title));
        }
      }
    });
  }

  Future<void> selectGroup() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const MinutesGroupService(),
        config: const SelectDialogConfig(
          title: "انتخاب دسته بندی",
          multiSelect: true,
          historyKey: "minute_groups",
        ),
      ),
    );

    if (result == null) return;

    final items = result as List<RecordItem>;

    setState(() {
      for (final item in items) {
        if (selectedGroups.every((e) => e.id != item.id)) {
          selectedGroups.add(MinutesGroupModel(id: item.id, name: item.title));
        }
      }
    });
  }

  void cancelProcessing() {
    _processCancelToken?.cancel("User cancelled");

    setState(() {
      processingFile = false;

      processingMessage = "پردازش لغو شد";
    });
  }
}
