import 'dart:typed_data';

class NoteExportResult {
  final Uint8List bytes;
  final String fileName;
  final String mimeType;

  const NoteExportResult({
    required this.bytes,
    required this.fileName,
    required this.mimeType,
  });

  bool get isPdf => mimeType == 'application/pdf';
  bool get isImage => mimeType.startsWith('image/');
}