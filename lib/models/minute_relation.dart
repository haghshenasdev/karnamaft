class MinuteUser {
  final int id;
  final String name;
  final String? avatarUrl;

  const MinuteUser({required this.id, required this.name, this.avatarUrl});

  factory MinuteUser.fromJson(Map<String, dynamic> json) {
    return MinuteUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      avatarUrl: json['avatar_url'],
    );
  }
}

class TaskCreator {
  final int id;
  final String name;

  const TaskCreator({required this.id, required this.name});

  factory TaskCreator.fromJson(Map<String, dynamic> json) {
    return TaskCreator(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class OrganModel {
  final int id;
  final String name;

  const OrganModel({required this.id, required this.name});

  factory OrganModel.fromJson(Map<String, dynamic> json) {
    return OrganModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}

class GroupModel {
  final int id;
  final String name;

  const GroupModel({required this.id, required this.name});

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(id: json['id'] ?? 0, name: json['name'] ?? '');
  }
}
