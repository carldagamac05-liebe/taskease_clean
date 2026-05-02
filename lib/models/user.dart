class User {
  final int id;
  final String fullname;
  final String email;
  final String? passwordHash;
  final DateTime createdAt;
  final DateTime? lastLogin;

  User({
    required this.id,
    required this.fullname,
    required this.email,
    this.passwordHash,
    required this.createdAt,
    this.lastLogin,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullname: json['fullname'] ?? json['full_name'] ?? '',
      email: json['email'] ?? '',
      passwordHash: json['password_hash'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      lastLogin: json['last_login'] != null
          ? DateTime.parse(json['last_login'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullname': fullname,
      'email': email,
      'created_at': createdAt.toIso8601String(),
      'last_login': lastLogin?.toIso8601String(),
    };
  }

  String get initials {
    final parts = fullname.split(' ');
    if (parts.isEmpty) return '';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  String toString() {
    return 'User(id: $id, fullname: $fullname, email: $email)';
  }
}
