import 'package:flutter/material.dart';
import 'package:karnamaft/widgets/record_files_card.dart';
import 'package:karnamaft/services/file_service.dart';
import 'package:karnamaft/widgets/record_share_dialog.dart';
import 'package:intl/intl.dart';
import 'package:karnamaft/controllers/user_controller.dart';
import 'package:karnamaft/models/letter_model.dart';
import 'package:karnamaft/models/record_item.dart';
import 'package:karnamaft/models/select_dialog_config.dart';
import 'package:karnamaft/services/letter_service.dart';
import 'package:karnamaft/pages/letter_timeline_page.dart';
import 'package:karnamaft/services/organ_service.dart';
import 'package:karnamaft/services/project_service.dart';
import 'package:karnamaft/utils/date_helper.dart';
import 'package:karnamaft/widgets/jalali_dropdown_dialog.dart';
import 'package:karnamaft/widgets/select_record_dialog.dart';
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

  int? selectedStatus;
  int? selectedKind;
  LetterOrgan? selectedCustomer;
  LetterDaftar? selecteddaftar;
  int? selectedPeiroowLetterId;
  String? selectedPeiroowLetterTitle;
  List<LetterProject> selectedProjects = [];

  late TextEditingController subjectController;
  late TextEditingController descriptionController;
  late TextEditingController summaryController;
  late TextEditingController dateController;

  @override
  void initState() {
    super.initState();

    // قبل از رسیدن پاسخ API کنترلرها را مقداردهی می‌کنیم
    // تا در حالت خطا dispose یا build باعث LateInitializationError نشود.
    subjectController = TextEditingController();
    descriptionController = TextEditingController();
    summaryController = TextEditingController();
    dateController = TextEditingController();

    loadData();
  }

  @override
  void dispose() {
    subjectController.dispose();
    descriptionController.dispose();
    summaryController.dispose();
    dateController.dispose();
    super.dispose();
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

        subjectController.text = result.subject;

        selectedStatus = result.status;
        selectedKind = result.kind;

        selectedCustomer = result.organ;
        selecteddaftar = result.daftar;
        selectedPeiroowLetterId = result.peiroowLetterId;
        selectedPeiroowLetterTitle = result.peiroowLetter?.subject;
        selectedProjects = List<LetterProject>.from(result.projects);

        descriptionController.text = result.description ?? "";
        summaryController.text = result.summary ?? "";
        dateController.text = result.created_at != null
            ? DateHelper.toDate(result.created_at)
            : "";

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

  Future<void> _shareRecord() async {
    final item = letter;
    if (item == null) return;
    await showRecordShareDialog(
      context,
      title: 'نامه',
      fields: [
        ShareField(label: 'شناسه', value: '${item.id}'),
        ShareField(label: 'موضوع', value: item.subject),
        ShareField(label: 'توضیحات', value: item.description ?? ''),
        ShareField(label: 'خلاصه', value: item.summary ?? ''),
        ShareField(label: 'نوع', value: item.kindTitle ?? ''),
        ShareField(label: 'وضعیت', value: item.status?.toString() ?? ''),
        ShareField(label: 'گیرنده', value: item.organ?.name ?? ''),
        ShareField(label: 'دفتر', value: item.daftar?.name ?? ''),
        ShareField(label: 'پیرو نامه', value: item.peiroowLetter?.subject ?? ''),
        ShareField(label: 'تاریخ ثبت', value: DateHelper.toDateTime(item.created_at)),
      ],
      files: item.files.map((f) => ShareFile(
        name: f.fileName,
        load: () => FileService.download(f.url),
      )).toList(),
    );
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
            tooltip: 'تاریخچه و Timeline',
            icon: const Icon(Icons.timeline_rounded),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => LetterTimelinePage(
                    letterId: item.id,
                    title: 'تاریخچه ${widget.title}',
                  ),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'اشتراک‌گذاری',
            icon: const Icon(Icons.share_outlined),
            onPressed: () => _shareRecord(),
          ),
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

              RecordFilesCard(files: item.files),

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

                  //--------------------------------------------------
                  // وضعیت
                  //--------------------------------------------------
                  const SizedBox(height: 12),
                  if (editing)
                    DropdownButtonFormField<int>(
                      value: selectedStatus,
                      decoration: const InputDecoration(
                        labelText: "وضعیت",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("بایگانی")),
                        DropdownMenuItem(value: 1, child: Text("اتمام")),
                        DropdownMenuItem(
                          value: 2,
                          child: Text("در حال پیگیری"),
                        ),
                        DropdownMenuItem(
                          value: 3,
                          child: Text("غیرقابل پیگیری"),
                        ),
                        DropdownMenuItem(value: 4, child: Text("جدید")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value;
                        });
                      },
                    )
                  else
                    RecordField(title: "وضعیت", value: item.recordStatus.title),

                  const SizedBox(height: 12),

                  //--------------------------------------------------
                  // نوع نامه
                  //--------------------------------------------------
                  if (editing)
                    DropdownButtonFormField<int>(
                      value: selectedKind,
                      decoration: const InputDecoration(
                        labelText: "نوع نامه",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.mail_outline),
                      ),
                      items: const [
                        DropdownMenuItem(value: 0, child: Text("وارده")),
                        DropdownMenuItem(value: 1, child: Text("صادره")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedKind = value;
                        });
                      },
                    )
                  else
                    RecordField(title: "نوع", value: item.kindTitle ?? "-"),

                  const SizedBox(height: 12),

                  if (editing)
                    InkWell(
                      onTap: selectCustomer,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "گیرنده",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
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
                    )
                  else if (item.organ != null)
                    RecordField(title: "گیرنده", value: item.organ!.name),

                  const SizedBox(height: 12),
                  
                  if (editing)
                    InkWell(
                      onTap: selectdaftar,
                      borderRadius: BorderRadius.circular(12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: "دفتر",
                          border: OutlineInputBorder(),
                          suffixIcon: Icon(Icons.arrow_drop_down),
                        ),
                        child: Text(
                          selecteddaftar?.name ?? "انتخاب دفتر",
                          style: TextStyle(
                            color: selecteddaftar == null
                                ? Colors.grey
                                : Colors.black87,
                          ),
                        ),
                      ),
                    )
                  else if (item.daftar != null)
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
              // پیرو نامه
              //--------------------------------------------------
              if (editing)
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'پیرو نامه',
                    prefixIcon: Icon(Icons.reply_outlined),
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          selectedPeiroowLetterTitle ?? 'بدون پیرو نامه',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        tooltip: 'انتخاب',
                        onPressed: selectPeiroowLetter,
                        icon: const Icon(Icons.search),
                      ),
                      if (selectedPeiroowLetterId != null)
                        IconButton(
                          tooltip: 'حذف',
                          onPressed: () => setState(() {
                            selectedPeiroowLetterId = null;
                            selectedPeiroowLetterTitle = null;
                          }),
                          icon: const Icon(Icons.close),
                        ),
                    ],
                  ),
                )
              else if (item.peiroowLetter != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.reply_outlined),
                  title: const Text('پیرو نامه'),
                  subtitle: Text(item.peiroowLetter!.subject),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => LetterShowPage(
                        id: item.peiroowLetter!.id,
                        title: item.peiroowLetter!.subject,
                      ),
                    ),
                  ),
                ),

              //--------------------------------------------------
              // Projects / دستورکارها
              //--------------------------------------------------
              if (editing)
                Card(
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            const Expanded(
                              child: Text(
                                "دستورکارها",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              tooltip: "افزودن دستورکار",
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: selectProjects,
                            ),
                          ],
                        ),
                        if (selectedProjects.isEmpty)
                          const Text("دستورکاری انتخاب نشده است."),
                        if (selectedProjects.isNotEmpty)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedProjects.map((project) {
                              return Chip(
                                avatar: const Icon(Icons.folder_outlined, size: 18),
                                label: Text(project.name),
                                deleteIcon: const Icon(Icons.close, size: 18),
                                onDeleted: () => setState(() {
                                  selectedProjects.removeWhere((x) => x.id == project.id);
                                }),
                              );
                            }).toList(),
                          ),
                      ],
                    ),
                  ),
                )
              else if (item.projects.isNotEmpty)
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

  Future<void> selectPeiroowLetter() async {
    final result = await showDialog<RecordItem>(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const LetterService(),
        config: const SelectDialogConfig(
          title: 'انتخاب پیرو نامه',
          multiSelect: false,
          historyKey: 'letter_peiroow',
        ),
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      selectedPeiroowLetterId = result.id;
      selectedPeiroowLetterTitle = result.title;
    });
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
      status: selectedStatus,
      kind: selectedKind,
      peiroowLetterId: selectedPeiroowLetterId,
      clearPeiroowLetter: selectedPeiroowLetterId == null,
      peiroowLetter: selectedPeiroowLetterId == null
          ? null
          : LetterReference(id: selectedPeiroowLetterId!, subject: selectedPeiroowLetterTitle ?? ''),
      daftar: selecteddaftar,
      organ: selectedCustomer,
      projects: selectedProjects,
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

        selectedStatus = result.status;
        selectedKind = result.kind;

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

  Future<void> selectProjects() async {
    final result = await showDialog(
      context: context,
      builder: (_) => SelectRecordDialog(
        service: const ProjectService(),
        config: const SelectDialogConfig(
          title: "انتخاب دستورکارها",
          multiSelect: true,
          historyKey: "letter_projects",
        ),
      ),
    );

    if (result == null) return;

    final items = result as List<RecordItem>;
    setState(() {
      selectedProjects = items
          .map((e) => LetterProject(id: e.id, name: e.title))
          .toList();
    });
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
      dateController.text = DateHelper.toDate(gregorian);
    });
  }

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

    if (result == null) return;

    setState(() {
      selectedCustomer = LetterOrgan(id: result.id, name: result.title);
    });
  }

  Future<void> selectdaftar() async {
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

    if (result == null) return;

    setState(() {
      selecteddaftar = LetterDaftar(id: result.id, name: result.title);
    });
  }
}
