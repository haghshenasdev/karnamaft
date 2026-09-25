class CartableModel {
  final int id;
  final int letterId;
  final bool checked;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final CartableLetter? letter;

  const CartableModel({
    required this.id,
    required this.letterId,
    required this.checked,
    this.createdAt,
    this.updatedAt,
    this.letter,
  });

  factory CartableModel.fromJson(Map<String, dynamic> json) {
    return CartableModel(
      id: json['id'] ?? 0,
      letterId: json['letter_id'] ?? 0,
      checked: json['checked'] == true || json['checked'] == 1,
      createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
      updatedAt: json['updated_at'] == null ? null : DateTime.tryParse(json['updated_at'].toString()),
      letter: json['letter'] == null ? null : CartableLetter.fromJson(json['letter']),
    );
  }
}
class CartableLetter {
  final int id;
  final String subject;
  final DateTime? createdAt;
  final String? organ;
  final String? daftar;
  final List<String> customers;
  final List<String> projects;

  const CartableLetter({
    required this.id, required this.subject, this.createdAt, this.organ,
    this.daftar, this.customers = const [], this.projects = const [],
  });

  factory CartableLetter.fromJson(Map<String,dynamic> json) => CartableLetter(
    id: json['id'] ?? 0,
    subject: json['subject'] ?? '',
    createdAt: json['created_at'] == null ? null : DateTime.tryParse(json['created_at'].toString()),
    organ: json['organ']?['name']?.toString(),
    daftar: json['daftar']?['name']?.toString(),
    customers: (json['customers'] as List? ?? []).map((e)=>e['name'].toString()).toList(),
    projects: (json['projects'] as List? ?? []).map((e)=>e['name'].toString()).toList(),
  );
}
