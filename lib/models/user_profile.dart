class UserProfile {
  const UserProfile({
    required this.email,
    this.id,
    this.name,
    this.phone,
    this.role,
  });

  final String email;
  final String? id;
  final String? name;
  final String? phone;
  final String? role;
}
