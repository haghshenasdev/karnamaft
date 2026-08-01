import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/letter_model.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/user_chip_list.dart';
import 'package:persian_datetime_picker/persian_datetime_picker.dart';
import 'package:provider/provider.dart';

import '../widgets/minute_file_editor.dart';
import '../widgets/record_chip_list.dart';
import '../widgets/show/record_field.dart';
import '../widgets/show/record_info_card.dart';
import '../widgets/show/record_preview.dart';
import '../widgets/show/record_text.dart';
import '../widgets/show/record_title.dart';

class LetterShowPage extends StatefulWidget {
  final int id;
  final String title;

  const LetterShowPage({super.key, required this.id, required this.title});

  @override
  State<LetterShowPage> createState() => _LetterShowPageState();
}

class _LetterShowPageState extends State<LetterShowPage> {
  UserController get user => context.read<UserController>();

  //--------------------------------------------------
  // Service
  //--------------------------------------------------

  final LetterService _service = const LetterService();

  //--------------------------------------------------
  // State
  //--------------------------------------------------

  bool loading = true;
  bool editing = false;

  String? error;

  LetterModel? letter;

  String? selectedFile;
  String? newUploadFile;

  late TextEditingController subjectController;
  late TextEditingController descriptionController;
  late TextEditingController summaryController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    summaryController.dispose();
    super.dispose();
    dateController.dispose();
  }

  Future<void> loadData() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await _service.show(widget.id);

      if (!mounted) return;

      setState(() {
        letter = result;

        selectedFile = result.file;

        subjectController = TextEditingController(text: result.subject);

        descriptionController = TextEditingController(text: result.description);

        summaryController = TextEditingController(text: result.summary);
        dateController = TextEditingController(
          text: result.created_at != null
              ? DateFormat("yyyy-MM-dd").format(result.created_at!)
              : "",
        );

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

  @override
  Widget build(BuildContext context) {
    //--------------------------------------------------
    // Loading
    //--------------------------------------------------

    if (loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    //--------------------------------------------------
    // Error
    //--------------------------------------------------

    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
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

    final item = letter!;

    //--------------------------------------------------
    // Success
    //--------------------------------------------------

    return Scaffold(
      backgroundColor: const Color(0xfff5f6fa),

      appBar: AppBar(
        title: Text(widget.title),

        actions: [
          IconButton(
            icon: Icon(editing ? Icons.close : Icons.edit),
            onPressed: () {
              setState(() {
                editing = !editing;
              });
            },
          ),
        ],
      ),

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
              RecordPreview(
                id: item.id,
                title: item.subject,
                file: item.file,
                getFile: _service.getFile,
              ),
              const SizedBox(height: 20),

              if (editing)
                Column(
                  children: [
                    MinuteFileEditor(
                      file: selectedFile,

                      onChanged: (value) {
                        setState(() {
                          newUploadFile = value;
                        });
                      },
                    ),

                    const SizedBox(height: 20),
                  ],
                ),

              //--------------------------------------------------
              // Subject
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: subjectController,
                      decoration: const InputDecoration(
                        labelText: "موضوع",
                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordTitle(title: item.subject),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Description
              //--------------------------------------------------
              editing
                  ? TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 10,
                      decoration: const InputDecoration(
                        labelText: "توضیحات",
                        border: OutlineInputBorder(),
                      ),
                    )
                  : RecordText(text: item.description),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // Summary
              //--------------------------------------------------
              if (editing)
                TextField(
                  controller: summaryController,
                  minLines: 2,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: "خلاصه",
                    border: OutlineInputBorder(),
                  ),
                )
              else if ((item.summary ?? "").isNotEmpty)
                RecordText(text: item.summary),

              const SizedBox(height: 20),

              //--------------------------------------------------
              // اطلاعات
              //--------------------------------------------------
              RecordInfoCard(
                children: [
                  RecordField(title: "شناسه", value: item.id.toString()),
                  if (item.created_at != null)
                    editing
                        ? TextField(
                            controller: dateController,

                            readOnly: true,

                            onTap: selectDate,

                            decoration: InputDecoration(
                              labelText: "تاریخ",

                              border: const OutlineInputBorder(),

                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_month),
                                onPressed: selectDate,
                              ),
                            ),
                          )
                        : RecordField(
                            title: "تاریخ",
                            value: DateHelper.toDate(item.created_at),
                          ),

                  RecordField(title: "وضعیت", value: item.recordStatus.title),

                  RecordField(title: "نوع", value: item.kindTitle ?? "-"),

                  if (item.organ != null)
                    RecordField(title: "گیرنده", value: item.organ!.name),

                  if (item.daftar != null)
                    RecordField(title: "دفتر", value: item.daftar!.name),
                ],
              ),

              const SizedBox(height: 16),

              //--------------------------------------------------
              // Customers
              //--------------------------------------------------
              if (item.customers.isNotEmpty)
                RecordChipList(
                  title: "صاحب حقیقی",
                  icon: Icons.people_outline,
                  items: item.customers.map((e) => e.name).toList(),
                ),

              //--------------------------------------------------
              // Organs Owner
              //--------------------------------------------------
              if (item.organsOwner.isNotEmpty)
                RecordChipList(
                  title: "صاحب حقوقی",
                  icon: Icons.account_balance_outlined,
                  items: item.organsOwner.map((e) => e.name).toList(),
                ),

              if (item.cartables.isNotEmpty)
                UserChipList(
                  title: "کارپوشه",
                  icon: Icons.account_circle_outlined,
                  users: item.cartables,
                  token: user.token,
                ),
              //--------------------------------------------------
              // Projects
              //--------------------------------------------------
              if (item.projects.isNotEmpty)
                RecordChipList(
                  title: "دستورکار ها",
                  icon: Icons.folder_outlined,
                  items: item.projects.map((e) => e.name).toList(),
                ),

              //--------------------------------------------------
              // User
              //--------------------------------------------------
              if (item.user != null)
                Container(
                  margin: const EdgeInsets.only(top: 12),

                  padding: const EdgeInsets.all(12),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xffe5e9f2)),
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 38,

                        backgroundColor: const Color(0xffe9eef6),

                        backgroundImage:
                            (item.user!.avatarUrl != null &&
                                item.user!.avatarUrl!.isNotEmpty)
                            ? NetworkImage(
                                "https://hajideligani.ir/api/get_avatar/${item.user!.avatarUrl}",
                                headers: {
                                  "Authorization": "Bearer ${user.token}",
                                },
                              )
                            : null,

                        child:
                            (item.user!.avatarUrl == null ||
                                item.user!.avatarUrl!.isEmpty)
                            ? const Icon(
                                Icons.person,
                                size: 32,
                                color: Colors.grey,
                              )
                            : null,
                      ),

                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              "ثبت کننده",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              item.user!.name,

                              maxLines: 2,

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 28),

              //--------------------------------------------------
              // Buttons
              //--------------------------------------------------
              if (editing)
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: save,
                        icon: const Icon(Icons.save),
                        label: const Text("ذخیره"),
                      ),
                    ),

                    const SizedBox(width: 12),

                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            editing = false;
                          });
                        },
                        child: const Text("انصراف"),
                      ),
                    ),
                  ],
                )
              else
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

  Future<void> save() async {
    if (letter == null) {
      return;
    }

    final model = letter!.copyWith(
      subject: subjectController.text.trim(),
      description: descriptionController.text.trim(),
      summary: summaryController.text.trim(),
      file: letter!.file,
    );

    setState(() {
      loading = true;
    });

    try {
      final result = await _service.update(
        letter!.id,
        model,
        uploadFile: newUploadFile,
      );

      if (!mounted) return;

      setState(() {
        letter = result;

        selectedFile = result.file;

        editing = false;

        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("نامه با موفقیت ذخیره شد.")));
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> selectDate() async {
    DateTime initial = letter?.created_at ?? DateTime.now();

    final jalali = await showJalaliDropdownDialog(
      context,
      initialDate: Jalali.fromDateTime(initial),
    );

    if (jalali == null) {
      return;
    }

    final gregorian = jalali.toDateTime();

    setState(() {
      dateController.text = DateFormat("yyyy-MM-dd").format(gregorian);
    });
  }
}
