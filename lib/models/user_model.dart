class User {
  final int? id;
  final String username;
  final String passwordHash;
  final bool isAdmin;
  final bool isOnline;

  User({
    this.id,
    required this.username,
    required this.passwordHash,
    this.isAdmin = false,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password_hash': passwordHash,
      'is_admin': isAdmin,
      'is_online': isOnline,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      passwordHash: map['password_hash'],
      isAdmin: map['is_admin'] ?? false,
      isOnline: map['is_online'] ?? false,
    );
  }

  User copyWith({int? id, String? username, String? passwordHash, bool? isAdmin, bool? isOnline}) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      passwordHash: passwordHash ?? this.passwordHash,
      isAdmin: isAdmin ?? this.isAdmin,
      isOnline: isOnline ?? this.isOnline,
    );
  }
}
