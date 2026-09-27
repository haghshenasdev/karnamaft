class LetterTimelineItem {
  final String type;
  final String title;
  final String description;
  final DateTime? createdAt;
  final String? icon;
  final String? color;
  final String? event;
  final String? user;
  final List<LetterTimelineChange> changes;

  const LetterTimelineItem({
    required this.type,
    required this.title,
    required this.description,
    this.createdAt,
    this.icon,
    this.color,
    this.event,
    this.user,
    this.changes = const [],
  });

  factory LetterTimelineItem.fromJson(Map<String, dynamic> json) {
    final changes = <LetterTimelineChange>[];
    final raw = json['changes'];
    if (raw is Map) {
      raw.forEach((key, value) {
        if (value is Map) {
          changes.add(
            LetterTimelineChange(
              field: key.toString(),
              label: value['label']?.toString() ?? key.toString(),
              oldValue: value['old']?.toString(),
              newValue: value['new']?.toString(),
            ),
          );
        }
      });
    }

    return LetterTimelineItem(
      type: json['type']?.toString() ?? 'activity',
      title: json['title']?.toString() ?? 'رویداد',
      description: json['description']?.toString() ?? '',
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'].toString()),
      icon: json['icon']?.toString(),
      color: json['color']?.toString(),
      event: json['event']?.toString(),
      user: json['user']?.toString(),
      changes: changes,
    );
  }
}

class LetterTimelineChange {
  final String field;
  final String label;
  final String? oldValue;
  final String? newValue;

  const LetterTimelineChange({
    required this.field,
    required this.label,
    this.oldValue,
    this.newValue,
  });
}
