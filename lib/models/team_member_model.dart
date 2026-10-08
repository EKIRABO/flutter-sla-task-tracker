class TeamMember {
  final String id;
  final String name;
  final String role;
  final String email;
  final String? avatarUrl;

  TeamMember({
    required this.id,
    required this.name,
    required this.role,
    required this.email,
    this.avatarUrl,
  });
  
// Convert SQLite dynmic database map back into a dart object
factory TeamMember.fromJson(Map<String, dynamic> json) => TeamMember(
  id: json['id'] as String,
  name: json['name'] as String,
  role: json['role'] as String,
  email: json['email'] as String,
  avatarUrl: json['avatar_url'] as String?,
);

// Convert Dart object attributes into a plain map for insertion into SQLite
Map<String, dynamic> toJson() => {
  'id': id,
  'name': name,
  'role': role,
  'email': email,
  'avatar_url': avatarUrl,
    };
}