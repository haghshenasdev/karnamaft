import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karnamaft/utils/app_settings.dart';
import 'package:karnamaft/offline/offline_sync_service.dart';

class AppSettingsCard extends StatefulWidget {
  const AppSettingsCard({super.key});

  @override
  State<AppSettingsCard> createState() => _AppSettingsCardState();
}

class _AppSettingsCardState extends State<AppSettingsCard> {
  String? lettersPath;
  String camScannerPath1 = '';
  String camScannerPath2 = '';

  bool readWithoutGallerySave = false;
  bool offlineEnabled = false;
  String offlineRootPath = '';
  DateTime? offlineLastSync;
  bool syncingOffline = false;
  double syncProgress = 0;
  String syncMessage = '';

  bool loading = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final letters = await AppSettings.getSavedLettersPath();

      final path1 = await AppSettings.getCamScannerPath1();
      final path2 = await AppSettings.getCamScannerPath2();

      final readWithoutGallery = await AppSettings.getReadWithoutGallerySave();
      final offline = await AppSettings.getOfflineEnabled();
      final offlinePath = await AppSettings.getOfflineRootPath();
      final lastSync = await AppSettings.getOfflineLastSync();

      if (!mounted) return;

      setState(() {
        lettersPath = letters;
        camScannerPath1 = path1;
        camScannerPath2 = path2;
        readWithoutGallerySave = readWithoutGallery;
        offlineEnabled = offline;
        offlineRootPath = offlinePath;
        offlineLastSync = lastSync;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        loading = false;
      });

      _showMessage('خطا در خواندن تنظیمات\n$e');
    }
  }

  Future<void> _pickLettersDirectory() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null || path.isEmpty) {
      return;
    }

    try {
      await AppSettings.setLettersDirectory(path);

      if (!mounted) return;

      setState(() {
        lettersPath = path;
      });

      _showMessage('مسیر نامه‌ها ذخیره شد');
    } catch (e) {
      _showMessage('خطا در ذخیره مسیر\n$e');
    }
  }

  Future<void> _pickCamScannerDirectories() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null || path.isEmpty) {
      return;
    }

    // اگر مسیر اول خالی است، آن را مسیر اول قرار بده
    if (camScannerPath1.isEmpty) {
      await AppSettings.setCamScannerDirectories(
        path1: path,
        path2: camScannerPath2,
      );

      if (!mounted) return;

      setState(() {
        camScannerPath1 = path;
      });

      _showMessage('مسیر اول CamScanner ذخیره شد');

      return;
    }

    // در غیر این صورت مسیر دوم را تغییر بده
    await AppSettings.setCamScannerDirectories(
      path1: camScannerPath1,
      path2: path,
    );

    if (!mounted) return;

    setState(() {
      camScannerPath2 = path;
    });

    _showMessage('مسیر دوم CamScanner ذخیره شد');
  }

  Future<void> _changeCamScannerPath1() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null || path.isEmpty) {
      return;
    }

    await AppSettings.setCamScannerDirectories(
      path1: path,
      path2: camScannerPath2,
    );

    if (!mounted) return;

    setState(() {
      camScannerPath1 = path;
    });

    _showMessage('مسیر اول CamScanner ذخیره شد');
  }

  Future<void> _changeCamScannerPath2() async {
    final path = await FilePicker.platform.getDirectoryPath();

    if (path == null || path.isEmpty) {
      return;
    }

    await AppSettings.setCamScannerDirectories(
      path1: camScannerPath1,
      path2: path,
    );

    if (!mounted) return;

    setState(() {
      camScannerPath2 = path;
    });

    _showMessage('مسیر دوم CamScanner ذخیره شد');
  }

  Future<void> _changeOfflineEnabled(bool value) async {
    try {
      await AppSettings.setOfflineEnabled(value);
      if (!mounted) return;
      setState(() => offlineEnabled = value);
      _showMessage(value
          ? 'حالت آفلاین فعال شد؛ برای دریافت اطلاعات همگام‌سازی را اجرا کنید.'
          : 'حالت آفلاین غیرفعال شد. اطلاعات محلی حذف نمی‌شوند.');
    } catch (e) {
      _showMessage('خطا در تغییر حالت آفلاین: $e');
    }
  }

  Future<void> _pickOfflineDirectory() async {
    try {
      final path = await FilePicker.platform.getDirectoryPath();
      if (path == null || path.isEmpty) return;
      await AppSettings.setOfflineRootPath(path);
      if (!mounted) return;
      setState(() => offlineRootPath = path);
      _showMessage('مسیر آفلاین ذخیره شد. مسیر جدید از همگام‌سازی بعدی استفاده می‌شود.');
    } catch (e) {
      _showMessage('انتخاب پوشه در این دستگاه پشتیبانی نشد. در اندروید از مسیر پیش‌فرض خصوصی برنامه استفاده کنید.\n$e');
    }
  }

  Future<void> _syncOfflineNow() async {
    if (syncingOffline) return;
    setState(() {
      syncingOffline = true;
      syncProgress = 0;
      syncMessage = 'آماده‌سازی همگام‌سازی...';
    });
    try {
      await OfflineSyncService.sync(onProgress: (done, total, message) {
        if (!mounted) return;
        setState(() {
          syncProgress = total == 0 ? 0 : (done / total).clamp(0.0, 1.0);
          syncMessage = message;
        });
      });
      final last = await AppSettings.getOfflineLastSync();
      if (mounted) setState(() => offlineLastSync = last);
      _showMessage('همگام‌سازی اطلاعات تمام شد.');
    } catch (e) {
      if (mounted) setState(() => syncMessage = 'همگام‌سازی ناموفق بود: $e');
      _showMessage('خطا در همگام‌سازی. اطلاعات قبلی محلی حذف نشده‌اند.\n$e');
    } finally {
      if (mounted) setState(() => syncingOffline = false);
    }
  }

  Future<void> _changeReadWithoutGallerySave(bool value) async {
    setState(() {
      saving = true;
    });

    try {
      await AppSettings.setReadWithoutGallerySave(value);

      if (!mounted) return;

      setState(() {
        readWithoutGallerySave = value;
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('خطا در ذخیره تنظیمات\n$e');
    } finally {
      if (mounted) {
        setState(() {
          saving = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _displayPath(String? value) {
    if (value == null || value.isEmpty) {
      return 'تنظیم نشده';
    }

    return value;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xffe4e8f0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: loading
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //----------------------------------
                  // Header
                  //----------------------------------
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.settings, color: Colors.blue),
                      ),

                      const SizedBox(width: 12),

                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'تنظیمات برنامه',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'مسیر فایل‌ها و تنظیمات اسکن',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  //----------------------------------
                  // Letters Path
                  //----------------------------------
                  _SettingItem(
                    icon: Icons.folder,
                    title: 'مسیر ذخیره نامه‌ها',
                    value: _displayPath(lettersPath),
                    onTap: _pickLettersDirectory,
                  ),

                  const Divider(height: 24),

                  //----------------------------------
                  // CamScanner Path 1
                  //----------------------------------
                  _SettingItem(
                    icon: Icons.document_scanner,
                    title: 'مسیر اول CamScanner',
                    value: camScannerPath1,
                    onTap: _changeCamScannerPath1,
                  ),

                  const Divider(height: 24),

                  //----------------------------------
                  // CamScanner Path 2
                  //----------------------------------
                  _SettingItem(
                    icon: Icons.document_scanner,
                    title: 'مسیر دوم CamScanner',
                    value: camScannerPath2,
                    onTap: _changeCamScannerPath2,
                  ),

                  const Divider(height: 24),

                  //----------------------------------
                  // Offline mode
                  //----------------------------------
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.teal.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.cloud_off_outlined, color: Colors.teal.shade700),
                    ),
                    title: const Text(
                      'حالت کار آفلاین',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'در صورت فعال بودن، فهرست‌های ذخیره‌شده روی دستگاه هنگام قطع اینترنت نمایش داده می‌شوند.',
                    ),
                    value: offlineEnabled,
                    onChanged: saving || syncingOffline ? null : _changeOfflineEnabled,
                  ),
                  if (offlineEnabled) ...[
                    const SizedBox(height: 8),
                    _SettingItem(
                      icon: Icons.folder_copy_outlined,
                      title: 'محل ذخیره اطلاعات آفلاین',
                      value: _displayPath(offlineRootPath),
                      onTap: syncingOffline ? () {} : _pickOfflineDirectory,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: syncingOffline ? null : _pickOfflineDirectory,
                            icon: const Icon(Icons.folder_open),
                            label: const Text('انتخاب پوشه'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: syncingOffline ? null : _syncOfflineNow,
                            icon: syncingOffline
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.sync),
                            label: Text(syncingOffline ? 'در حال همگام‌سازی' : 'همگام‌سازی اکنون'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (syncingOffline || syncMessage.isNotEmpty) ...[
                      LinearProgressIndicator(
                        value: syncingOffline ? (syncProgress > 0 ? syncProgress.clamp(0.0, 1.0) : null) : syncProgress,
                      ),
                      const SizedBox(height: 6),
                      Text(syncMessage, style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                    ],
                    Text(
                      offlineLastSync == null
                          ? 'هنوز همگام‌سازی موفقی انجام نشده است.'
                          : 'آخرین همگام‌سازی: ${offlineLastSync!.toLocal()}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                  const Divider(height: 24),

                  //----------------------------------
                  // Scan Mode
                  //----------------------------------
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,

                    secondary: Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.photo_library_outlined,
                        color: Colors.orange.shade700,
                      ),
                    ),

                    title: const Text(
                      'خواندن بدون ذخیره در گالری',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),

                    subtitle: const Text(
                      'اسکن را مستقیماً از مسیر خصوصی CamScanner بخوان',
                    ),

                    value: readWithoutGallerySave,

                    onChanged: saving ? null : _changeReadWithoutGallerySave,
                  ),
                ],
              ),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.blueGrey),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            const Icon(Icons.chevron_left, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
