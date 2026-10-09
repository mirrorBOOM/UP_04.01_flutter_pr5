enum Role {
  client(1, 'Клиент'),
  trainer(2, 'Тренер'),
  admin(3, 'Администратор');

  final int level;
  final String label;
  const Role(this.level, this.label);

  static Role fromString(String? val) {
    return switch (val?.toLowerCase()) {
      'admin' => Role.admin,
      'trainer' => Role.trainer,
      _ => Role.client,
    };
  }
}

class AppUser {
  final int id;
  final String username;
  final String fullName;
  final Role role;

  const AppUser({
    required this.id,
    required this.username,
    required this.fullName,
    required this.role,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'fullName': fullName,
    'role': role.name,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'] as int? ?? 0,
    username: json['username'] as String? ?? '',
    fullName: json['fullName'] as String? ?? '',
    role: Role.fromString(json['role'] as String?),
  );
}