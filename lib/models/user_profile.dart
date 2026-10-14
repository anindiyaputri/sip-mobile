class UserProfile {
  const UserProfile({
    required this.email,
    this.id,
    this.name,
    this.phone,
    this.photoPath,
    this.role,
  });

  final String email;
  final String? id;
  final String? name;
  final String? phone;
  final String? photoPath;
  final String? role;

  UserProfile withEditableDetails({
    required String name,
    required String phone,
  }) {
    final trimmedName = name.trim();
    final trimmedPhone = phone.trim();
    return UserProfile(
      id: id,
      email: email,
      name: trimmedName.isEmpty ? null : trimmedName,
      phone: trimmedPhone.isEmpty ? null : trimmedPhone,
      photoPath: photoPath,
      role: role,
    );
  }

  UserProfile withProfilePhoto(String path) {
    return UserProfile(
      id: id,
      email: email,
      name: name,
      phone: phone,
      photoPath: path,
      role: role,
    );
  }
}
