class RecordFile {
  final String id;
  final String title;
  final String extension;
  final String url;

  const RecordFile({
    required this.id,
    required this.title,
    required this.extension,
    required this.url,
  });

  String get fileName {
    final clean = title.trim().isEmpty ? 'file' : title.trim();
    final ext = extension.trim().replaceFirst('.', '');
    return ext.isEmpty ? clean : '$clean.$ext';
  }

  factory RecordFile.fromJson(Map<String, dynamic> json) => RecordFile(
    id: json['id']?.toString() ?? '',
    title: json['title']?.toString() ?? 'فایل',
    extension: json['extension']?.toString() ?? '',
    url: json['url']?.toString() ?? '',
  );
}
