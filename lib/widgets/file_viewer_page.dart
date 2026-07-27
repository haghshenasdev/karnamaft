import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class FileViewerPage extends StatefulWidget {
  final String title;
  final String fileName;
  final Future<Uint8List?> future;

  const FileViewerPage({
    super.key,
    required this.title,
    required this.fileName,
    required this.future,
  });

  @override
  State<FileViewerPage> createState() => _FileViewerPageState();
}

class _FileViewerPageState extends State<FileViewerPage> {
  late Future<Uint8List?> _future;

  final PhotoViewController _photoController = PhotoViewController();

  final PdfViewerController _pdfController = PdfViewerController();

  double _rotation = 0;

  @override
  void initState() {
    super.initState();
    _future = widget.future;
  }

  bool get isImage {
    final ext = widget.fileName.toLowerCase().split('.').last;

    return const ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'].contains(ext);
  }

  bool get isPdf {
    final name = widget.fileName.toLowerCase();
    return name.contains(".pdf");
  }

  bool get isWord {
    return widget.fileName.toLowerCase().endsWith(".doc") ||
        widget.fileName.toLowerCase().endsWith(".docx");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: "بارگذاری مجدد",
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _future = widget.future;
              });
            },
          ),
        ],
      ),

      body: Stack(
        children: [
          FutureBuilder<Uint8List?>(
            future: _future,
            builder: (context, snapshot) {
              //--------------------------------------
              // Loading
              //--------------------------------------

              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }

              //--------------------------------------
              // Error
              //--------------------------------------

              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 80,
                        ),

                        const SizedBox(height: 16),

                        Text(
                          snapshot.error.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),

                        const SizedBox(height: 24),

                        FilledButton.icon(
                          onPressed: () {
                            setState(() {
                              _future = widget.future;
                            });
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text("تلاش مجدد"),
                        ),
                      ],
                    ),
                  ),
                );
              }

              //--------------------------------------
              // Empty
              //--------------------------------------

              if (snapshot.data == null) {
                return const Center(
                  child: Text(
                    "فایل یافت نشد.",
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                );
              }

              final bytes = snapshot.data!;
              //--------------------------------------
              // Image
              //--------------------------------------

              if (isImage) {
                return Transform.rotate(
                  angle: _rotation,
                  child: PhotoView(
                    controller: _photoController,
                    imageProvider: MemoryImage(bytes),
                    minScale: PhotoViewComputedScale.contained,
                    initialScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 4,
                    backgroundDecoration: const BoxDecoration(
                      color: Colors.black,
                    ),
                    heroAttributes: PhotoViewHeroAttributes(
                      tag: widget.fileName,
                    ),
                  ),
                );
              }

              //--------------------------------------
              // PDF
              //--------------------------------------

              if (isPdf || isPdfBytes(bytes)) {
                return SfPdfViewer.memory(
                  bytes,
                  controller: _pdfController,
                  canShowScrollHead: true,
                  canShowScrollStatus: true,
                  enableDoubleTapZooming: true,
                );
              }

              //--------------------------------------
              // Word
              //--------------------------------------

              if (isWord) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.description,
                              color: Colors.blue,
                              size: 90,
                            ),

                            const SizedBox(height: 20),

                            const Text(
                              "نمایش فایل Word",
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 12),

                            const Text(
                              "در حال حاضر نمایش مستقیم فایل Word پشتیبانی نمی‌شود.",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }

              //--------------------------------------
              // Unknown
              //--------------------------------------

              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.insert_drive_file, size: 90),

                          const SizedBox(height: 20),

                          Text(
                            widget.fileName,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),

                          const SizedBox(height: 12),

                          const Text(
                            "پیش‌نمایش برای این نوع فایل وجود ندارد.",
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ), //--------------------------------------
          // Floating Toolbar
          //--------------------------------------
          Positioned(
            left: 0,
            right: 0,
            bottom: 20,
            child: SafeArea(
              child: Center(
                child: Material(
                  color: Colors.black.withOpacity(0.85),
                  elevation: 10,
                  borderRadius: BorderRadius.circular(40),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        //----------------------------------
                        // Share
                        //----------------------------------
                        IconButton(
                          tooltip: "اشتراک گذاری",
                          onPressed: () async {
                            final bytes = await _future;

                            if (bytes != null) {
                              _share(bytes);
                            }
                          },
                          icon: const Icon(Icons.share, color: Colors.white),
                        ),

                        //----------------------------------
                        // Print
                        //----------------------------------
                        IconButton(
                          tooltip: "چاپ",
                          onPressed: () async {
                            final bytes = await _future;

                            if (bytes != null) {
                              await _print(bytes);
                            }
                          },
                          icon: const Icon(Icons.print, color: Colors.white),
                        ),

                        if (isImage) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 6),

                          //----------------------------------
                          // Zoom In
                          //----------------------------------
                          IconButton(
                            tooltip: "بزرگنمایی",
                            onPressed: _zoomIn,
                            icon: const Icon(
                              Icons.zoom_in,
                              color: Colors.white,
                            ),
                          ),

                          //----------------------------------
                          // Zoom Out
                          //----------------------------------
                          IconButton(
                            tooltip: "کوچک نمایی",
                            onPressed: _zoomOut,
                            icon: const Icon(
                              Icons.zoom_out,
                              color: Colors.white,
                            ),
                          ),

                          //----------------------------------
                          // Rotate
                          //----------------------------------
                          IconButton(
                            tooltip: "چرخش",
                            onPressed: _rotate,
                            icon: const Icon(
                              Icons.rotate_right,
                              color: Colors.white,
                            ),
                          ),
                        ],

                        if (isPdf) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 1,
                            height: 28,
                            color: Colors.white24,
                          ),
                          const SizedBox(width: 6),

                          //----------------------------------
                          // Previous Page
                          //----------------------------------
                          IconButton(
                            tooltip: "صفحه قبل",
                            onPressed: _nextPage,
                            icon: const Icon(
                              Icons.chevron_left,
                              color: Colors.white,
                            ),
                          ),

                          //----------------------------------
                          // Next Page
                          //----------------------------------
                          IconButton(
                            tooltip: "صفحه بعد",
                            onPressed: _previousPage,
                            icon: const Icon(
                              Icons.chevron_right,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _zoomIn() {
    if (isImage) {
      _photoController.scale = (_photoController.scale ?? 1) * 1.25;
    }

    if (isPdf) {
      _pdfController.zoomLevel += 0.25;
    }
  }

  void _zoomOut() {
    if (isImage) {
      _photoController.scale = (_photoController.scale ?? 1) / 1.25;
    }

    if (isPdf) {
      if (_pdfController.zoomLevel > 1) {
        _pdfController.zoomLevel -= 0.25;
      }
    }
  }

  void _rotate() {
    setState(() {
      _rotation += 3.1415926535 / 2;
    });
  }

  void _nextPage() {
    if (!isPdf) return;

    _pdfController.nextPage();
  }

  void _previousPage() {
    if (!isPdf) return;

    _pdfController.previousPage();
  }

  // void _fitScreen() {
  //   if (isImage) {
  //     _photoController.scale = PhotoViewComputedScale.contained as double?;
  //   }

  //   if (isPdf) {
  //     _pdfController.zoomLevel = 1;
  //   }
  // }

  Future<void> _share(Uint8List bytes) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile.fromData(bytes, name: widget.fileName)]),
    );
  }

  Future<void> _print(Uint8List bytes) async {
    if (isPdf) {
      //--------------------------------------
      // Print PDF
      //--------------------------------------

      await Printing.layoutPdf(
        onLayout: (_) async => bytes,
        name: widget.fileName,
      );

      return;
    }

    if (isImage) {
      //--------------------------------------
      // Convert Image -> PDF
      //--------------------------------------

      final image = pw.MemoryImage(bytes);

      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (_) {
            return pw.Center(child: pw.Image(image, fit: pw.BoxFit.contain));
          },
        ),
      );

      await Printing.layoutPdf(
        onLayout: (_) async => pdf.save(),
        name: widget.fileName,
      );

      return;
    }

    //--------------------------------------
    // Unsupported
    //--------------------------------------

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("چاپ این نوع فایل پشتیبانی نمی‌شود.")),
    );
  }

  bool isPdfBytes(Uint8List bytes) {
    if (bytes.length < 4) return false;

    return bytes[0] == 0x25 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x44 &&
        bytes[3] == 0x46;
  }
}
