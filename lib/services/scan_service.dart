import 'dart:async';
import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;

import '../utils/app_settings.dart';

class ScanService {
  ScanService._();

  static DateTime? _scanStartTime;

  //------------------------------------------------------------
  // شروع فرآیند اسکن
  //------------------------------------------------------------

  static Future<void> startScan() async {
    _scanStartTime = DateTime.now();

    // بررسی تنظیمات
    final readWithoutGallerySave =
        await AppSettings.getReadWithoutGallerySave();

    AndroidIntent intent;

    if (readWithoutGallerySave) {
      // حالت بدون ذخیره در گالری
      // باز کردن مستقیم دوربین CamScanner
      intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.intsig.camscanner',
        componentName: 'com.intsig.camscanner.capture.CaptureActivity',
      );
    } else {
      // حالت معمولی
      // باز کردن صفحه اصلی CamScanner
      intent = const AndroidIntent(
        action: 'android.intent.action.MAIN',
        package: 'com.intsig.camscanner',
        componentName:
            'com.intsig.camscanner.mainmenu.mainactivity.MainActivity',
      );
    }

    await intent.launch();
  }

  //------------------------------------------------------------
  // هنگام برگشت از CamScanner
  //------------------------------------------------------------

  static Future<String?> processReturnedScan() async {
    if (_scanStartTime == null) {
      return null;
    }

    final files = await _findScannedFiles();

    if (files.isEmpty) {
      return null;
    }

    // اولین صفحه یا آخرین فایل؟
    // فعلا اولین فایل را برمی‌گردانیم
    final file = files.first;

    _scanStartTime = null;

    return file.path;
  }
  //------------------------------------------------------------
  // پیدا کردن فایل‌های جدید CamScanner
  //------------------------------------------------------------

  static Future<List<File>> _findScannedFiles() async {
    final readWithoutGallerySave =
        await AppSettings.getReadWithoutGallerySave();

    final directories = <Directory>[];

    if (readWithoutGallerySave) {
      // مسیر خصوصی CamScanner
      directories.add(Directory(AppSettings.camScannerPrivateImagePath));
    } else {
      // مسیرهای معمولی
      directories.addAll(await AppSettings.getCamScannerDirectories());
    }

    final files = <File>[];

    for (final dir in directories) {
      if (!await dir.exists()) {
        continue;
      }

      await for (final entity in dir.list(
        recursive: true,
        followLinks: false,
      )) {
        if (entity is! File) {
          continue;
        }

        final ext = path.extension(entity.path).toLowerCase();

        if (ext == '.jpg' || ext == '.jpeg' || ext == '.png' || ext == '.pdf') {
          final modified = await entity.lastModified();

          // فقط فایل‌هایی که بعد از شروع اسکن ساخته شده‌اند
          if (modified.isAfter(_scanStartTime!)) {
            files.add(entity);
          }
        }
      }
    }

    if (files.isEmpty) {
      return [];
    }

    // مرتب سازی از قدیمی به جدید
    files.sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    /*
      CamScanner گاهی چند فایل را با چند ثانیه فاصله ذخیره می‌کند.

      مثال:

      page1.jpg  10:00:01
      page2.jpg  10:00:03
      page3.jpg  10:00:05

      همه اینها یک اسکن هستند.

      ولی فایل خیلی قدیمی نباید وارد شود.
    */

    final latestTime = await files.last.lastModified();

    final result = <File>[];

    for (final file in files) {
      final time = await file.lastModified();

      final difference = latestTime.difference(time).inSeconds;

      // فایل‌هایی که حداکثر ۳۰ ثانیه با آخرین فایل فاصله دارند
      if (difference <= 30) {
        result.add(file);
      }
    }

    // محدودیت زمانی کلی عملیات اسکن
    if (DateTime.now().difference(_scanStartTime!).inMinutes > 10) {
      return [];
    }

    return result;
  }
  //------------------------------------------------------------
  // آیا فرآیند اسکن در حال انجام است؟
  //------------------------------------------------------------

  static bool get isWaitingForScan {
    return _scanStartTime != null;
  }

  //------------------------------------------------------------
  // شماره نامه فعلی
  //------------------------------------------------------------

  //------------------------------------------------------------
  // زمان شروع اسکن
  //------------------------------------------------------------

  static DateTime? get scanStartTime {
    return _scanStartTime;
  }

  //------------------------------------------------------------
  // لغو عملیات اسکن
  //------------------------------------------------------------

  static void cancel() {
    _scanStartTime = null;
  }

  //------------------------------------------------------------
  // پاک کردن فایل قدیمی هم نام
  //------------------------------------------------------------

  
}
