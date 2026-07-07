class CategoryModel {
  final String id;

  final String title;

  final String? parentId;

  final String icon;

  final int useCount;

  final List<CategoryModel> children;

  const CategoryModel({
    required this.id,
    required this.title,
    this.parentId,
    required this.icon,
    this.useCount = 0,
    this.children = const [],
  });

  bool get hasChildren => children.isNotEmpty;

  CategoryModel copyWith({
    String? id,
    String? title,
    String? parentId,
    String? icon,
    int? useCount,
    List<CategoryModel>? children,
  }) {
    return CategoryModel(
      id: id ?? this.id,
      title: title ?? this.title,
      parentId: parentId ?? this.parentId,
      icon: icon ?? this.icon,
      useCount: useCount ?? this.useCount,
      children: children ?? this.children,
    );
  }

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: json["id"].toString(),
      title: json["title"] ?? "",
      parentId: json["parent_id"]?.toString(),
      icon: json["icon"] ?? "folder",
      useCount: json["use_count"] ?? 0,
      children: (json["children"] as List<dynamic>? ?? [])
          .map((e) => CategoryModel.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "title": title,
      "parent_id": parentId,
      "icon": icon,
      "use_count": useCount,
      "children": children.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return title;
  }

  @override
  bool operator ==(Object other) {
    return other is CategoryModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}