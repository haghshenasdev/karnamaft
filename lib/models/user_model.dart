class UserModel {
  final int id;
  final String name;
  final String email;
  final String avatar;
  final List<String> roles;
  final List<String> permissions;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.avatar,
    this.roles = const [],
    this.permissions = const [],
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json["id"] ?? 0,
      name: json["name"] ?? "",
      email: json["email"] ?? "",
      avatar: (json["avatar"] ?? json["avatar_url"] ?? "").toString(),
      roles: (json["roles"] as List? ?? []).map((e) => e.toString()).toList(),
      permissions: (json["permissions"] as List? ?? []).map((e) => e.toString()).toList(),
    );
  }

  bool can(String permission) => permissions.contains(permission);

  UserModel copyWith({
    String? name,
    String? email,
    String? avatar,
    List<String>? roles,
    List<String>? permissions,
  }) => UserModel(
    id: id,
    name: name ?? this.name,
    email: email ?? this.email,
    avatar: avatar ?? this.avatar,
    roles: roles ?? this.roles,
    permissions: permissions ?? this.permissions,
  );
}
