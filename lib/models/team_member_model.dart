
class TeamMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? avatarUrl;

  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.avatarUrl,
  });

  // Kenia's method: Convert SQLite data into a TeamMember.
  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatar_url'] as String?,
    );
  }

  // Kenia's method: Convert TeamMember into database data.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }

  // Bior's method: Convert a database map into a TeamMember.
  factory TeamMember.fromMap(Map<String, Object?> map) {
    return TeamMember(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  // Bior's method: Convert TeamMember into a database map.
  Map<String, Object?> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'email': email,
      'avatar_url': avatarUrl,
    };
  }
}
