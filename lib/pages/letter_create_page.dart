import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/models/letter_model.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/services/organ_service.dart';
import 'package:karnamaft/services/scan_service.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/minute_file_editor.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';

class LetterCreatePage extends StatefulWidget {
  const LetterCreatePage({super.key});

  @override
  State<LetterCreatePage> createState() => _LetterCreatePageState();
}

class _LetterCreatePageState extends State<LetterCreatePage>
    with WidgetsBindingObserver {
  //--------------------------------------------------
  // Service
  //--------------------------------------------------

  final LetterService _service = const LetterService();

  //--------------------------------------------------
  // Controllers
  //--------------------------------------------------

  final subjectController = TextEditingController();
  final descriptionController = TextEditingController();
  final summaryController = TextEditingController();
  final dateController = TextEditingController();

  //--------------------------------------------------
  // File
  //--------------------------------------------------

  String? selectedFile;
  Uint8List? selectedFileBytes;

  //--------------------------------------------------
  // Selected information
  //--------------------------------------------------

  DateTime selectedDate = DateTime.now();

  int selectedStatus = 4;

  int selectedKind = 0;

  LetterOrgan? selectedCustomer;

  LetterDaftar? selectedDaftar;

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool saving = false;

  bool waitingForScan = false;

  String? error;

  //--------------------------------------------------
  // Init
  //--------------------------------------------------

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    dateController.text = DateFormat("yyyy-MM-dd").format(selectedDate);
  }

  //--------------------------------------------------
  // Dispose
  //--------------------------------------------------

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    subjectController.dispose();
    descriptionController.dispose();
    summaryController.dispose();
    dateController.dispose();

    super.dispose();
  }

  //--------------------------------------------------
  // Scan lifecycle
  //--------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state != AppLifecycleState.resumed) {
      return;
    }

    if (!waitingForScan) {
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
    } catch (e) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطا در دریافت فایل اسکن شده\n$e")),
      );
    }
  }

  //--------------------------------------------------
  // Scan
  //--------------------------------------------------

  Future<void> startScan() async {
    try {
      waitingForScan = true;

      await ScanService.startScan();
    } catch (e) {
      waitingForScan = false;

      if (!mounted) {
        return;
      }

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
  // Select Customer / Organ
  //--------------------------------------------------

  Future<void> selectCustomer() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) {
        return SelectRecordDialog(
          service: const OrganService(),
          config: const SelectDialogConfig(
            title: "انتخاب گیرنده",
            multiSelect: false,
            historyKey: "letter_owner",
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedCustomer = LetterOrgan(id: result.id, name: result.title);
    });
  }

  //--------------------------------------------------
  // Select Daftar
  //--------------------------------------------------

  Future<void> selectDaftar() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) {
        return SelectRecordDialog(
          service: const OrganService(),
          config: const SelectDialogConfig(
            title: "انتخاب دفتر",
            multiSelect: false,
            historyKey: "letter_daftar",
          ),
          initialFilters: {"organ_type_id": "20"},
        );
      },
    );

    if (result == null) {
      return;
    }

    setState(() {
      selectedDaftar = LetterDaftar(id: result.id, name: result.title);
    });
  }

  //--------------------------------------------------
  // Save
  //--------------------------------------------------

  Future<void> save() async {
    //--------------------------------------------------
    // Validation
    //--------------------------------------------------

    if (subjectController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("موضوع نامه الزامی است")));

      return;
    }

    //--------------------------------------------------
    // Loading
    //--------------------------------------------------

    setState(() {
      saving = true;
      error = null;
    });

    try {
      //--------------------------------------------------
      // Model
      //--------------------------------------------------

      final model = LetterModel(
        id: 0,

        subject: subjectController.text.trim(),

        description: descriptionController.text.trim(),

        summary: summaryController.text.trim(),

        file: selectedFile,

        status: selectedStatus,

        kind: selectedKind,

        user: null,

        type: null,

        //--------------------------------------------------
        // گیرنده
        //--------------------------------------------------
        organ: selectedCustomer,

        //--------------------------------------------------
        // دفتر
        //--------------------------------------------------
        daftar: selectedDaftar,

        customers: const [],

        organsOwner: const [],

        cartables: const [],

        projects: const [],

        created_at: selectedDate,

        updated_at: null,
      );

      //--------------------------------------------------
      // API
      //--------------------------------------------------

      final result = await _service.create(model, uploadFile: selectedFile);

      if (!mounted) {
        return;
      }

      //--------------------------------------------------
      // Success
      //--------------------------------------------------

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("نامه با موفقیت ثبت شد.")));

      Navigator.pop(context, result);
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        error = e.toString();
      });
    } finally {
      if (!mounted) {
        return;
      }

      setState(() {
        saving = false;
      });
    }
  }

  //--------------------------------------------------
  // Build
  //--------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(title: const Text("ایجاد نامه"), centerTitle: false),

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
              },

              onBytesChanged: (bytes) {
                setState(() {
                  selectedFileBytes = bytes;
                });
              },

              onScan: startScan,
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Subject
            //--------------------------------------------------
            TextField(
              controller: subjectController,

              minLines: 1,

              maxLines: 4,

              onChanged: (_) {
                setState(() {});
              },

              decoration: InputDecoration(
                labelText: "موضوع",

                alignLabelWithHint: true,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                prefixIcon: const Icon(Icons.title),

                suffixIcon: subjectController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          subjectController.clear();

                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Description
            //--------------------------------------------------
            TextField(
              controller: descriptionController,

              minLines: 5,

              maxLines: 15,

              onChanged: (_) {
                setState(() {});
              },

              decoration: InputDecoration(
                labelText: "توضیحات نامه",

                alignLabelWithHint: true,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 120),

                  child: Icon(Icons.description_outlined),
                ),

                suffixIcon: descriptionController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          descriptionController.clear();

                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Summary
            //--------------------------------------------------
            TextField(
              controller: summaryController,

              minLines: 3,

              maxLines: 8,

              onChanged: (_) {
                setState(() {});
              },

              decoration: InputDecoration(
                labelText: "خلاصه",

                alignLabelWithHint: true,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),

                prefixIcon: const Padding(
                  padding: EdgeInsets.only(bottom: 60),

                  child: Icon(Icons.summarize_outlined),
                ),

                suffixIcon: summaryController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          summaryController.clear();

                          setState(() {});
                        },
                      ),
              ),
            ),

            const SizedBox(height: 20),

            //--------------------------------------------------
            // Information
            //--------------------------------------------------
            _buildInformationCard(),

            const SizedBox(height: 25),

            //--------------------------------------------------
            // Error
            //--------------------------------------------------
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
            // Save
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

                label: Text(saving ? "در حال ثبت..." : "ثبت نامه"),

                onPressed: saving ? null : save,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //--------------------------------------------------
  // Information Card
  //--------------------------------------------------

  Widget _buildInformationCard() {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(color: const Color(0xffe5e9f2)),
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,

        children: [
          //--------------------------------------------------
          // Title
          //--------------------------------------------------
          const Text(
            "اطلاعات نامه",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // Date
          //--------------------------------------------------
          TextField(
            controller: dateController,

            readOnly: true,

            onTap: selectDate,

            decoration: InputDecoration(
              labelText: "تاریخ ثبت",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              prefixIcon: const Icon(Icons.calendar_month),

              suffixIcon: IconButton(
                icon: const Icon(Icons.edit_calendar),

                onPressed: selectDate,
              ),
            ),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // Status
          //--------------------------------------------------
          DropdownButtonFormField<int>(
            value: selectedStatus,

            decoration: InputDecoration(
              labelText: "وضعیت",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              prefixIcon: const Icon(Icons.flag_outlined),
            ),

            items: const [
              DropdownMenuItem(value: 0, child: Text("بایگانی")),

              DropdownMenuItem(value: 1, child: Text("اتمام")),

              DropdownMenuItem(value: 2, child: Text("در حال پیگیری")),

              DropdownMenuItem(value: 3, child: Text("غیرقابل پیگیری")),

              DropdownMenuItem(value: 4, child: Text("جدید")),
            ],

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedStatus = value;
              });
            },
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // Kind
          //--------------------------------------------------
          DropdownButtonFormField<int>(
            value: selectedKind,

            decoration: InputDecoration(
              labelText: "نوع نامه",

              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),

              prefixIcon: const Icon(Icons.mail_outline),
            ),

            items: const [
              DropdownMenuItem(value: 0, child: Text("وارده")),

              DropdownMenuItem(value: 1, child: Text("صادره")),
            ],

            onChanged: (value) {
              if (value == null) {
                return;
              }

              setState(() {
                selectedKind = value;
              });
            },
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // Customer / Receiver
          //--------------------------------------------------
          InkWell(
            onTap: selectCustomer,

            borderRadius: BorderRadius.circular(12),

            child: InputDecorator(
              decoration: InputDecoration(
                labelText: "گیرنده",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                prefixIcon: const Icon(Icons.business_outlined),

                suffixIcon: selectedCustomer == null
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          setState(() {
                            selectedCustomer = null;
                          });
                        },
                      ),
              ),

              child: Text(
                selectedCustomer?.name ?? "انتخاب گیرنده",

                style: TextStyle(
                  color: selectedCustomer == null
                      ? Colors.grey
                      : Colors.black87,
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          //--------------------------------------------------
          // Daftar
          //--------------------------------------------------
          InkWell(
            onTap: selectDaftar,

            borderRadius: BorderRadius.circular(12),

            child: InputDecorator(
              decoration: InputDecoration(
                labelText: "دفتر",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),

                prefixIcon: const Icon(Icons.account_balance_outlined),

                suffixIcon: selectedDaftar == null
                    ? const Icon(Icons.arrow_drop_down)
                    : IconButton(
                        icon: const Icon(Icons.clear),

                        onPressed: () {
                          setState(() {
                            selectedDaftar = null;
                          });
                        },
                      ),
              ),

              child: Text(
                selectedDaftar?.name ?? "انتخاب دفتر",

                style: TextStyle(
                  color: selectedDaftar == null ? Colors.grey : Colors.black87,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
