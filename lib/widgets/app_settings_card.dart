import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:karnamaft/utils/app_settings.dart';

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

      if (!mounted) return;

      setState(() {
        lettersPath = letters;
        camScannerPath1 = path1;
        camScannerPath2 = path2;
        readWithoutGallerySave = readWithoutGallery;
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
