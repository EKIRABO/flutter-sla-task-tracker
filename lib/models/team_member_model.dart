class TeamMember {
  const TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String role;
  final String email;
  final String? avatarUrl;

  factory TeamMember.fromMap(Map<String, Object?> map) {
    return TeamMember(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      email: map['email'] as String,
      avatarUrl: map['avatar_url'] as String?,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'role': role,
    'email': email,
    'avatar_url': avatarUrl,
  };
}
