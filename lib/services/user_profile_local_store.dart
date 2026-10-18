import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_application_1/models/user_profile.dart';

class UserProfileLocalStore {
  Future<UserProfile> load(String email) async {
    final preferences = await SharedPreferences.getInstance();
    final json = preferences.getString(_keyFor(email));
    if (json == null) return UserProfile(email: email);

    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Data profil lokal memiliki format salah.');
    }

    final name = decoded['name'];
    final phone = decoded['phone'];
    final photoPath = decoded['photoPath'];
    final id = decoded['id'];
    final role = decoded['role'];
    if ((name != null && name is! String) ||
        (phone != null && phone is! String) ||
        (photoPath != null && photoPath is! String) ||
        (id != null && id is! String) ||
        (role != null && role is! String)) {
      throw const FormatException('Data profil lokal memiliki format salah.');
    }

    return UserProfile(
      email: email,
      id: id as String?,
      name: name as String?,
      phone: phone as String?,
      photoPath: photoPath as String?,
      role: role as String?,
    );
  }

  Future<UserProfile> loadForLogin(String email) async {
    final profile = await load(email);
    return UserProfile(
      id: profile.id,
      email: email.trim(),
      name: profile.name,
      phone: profile.phone,
      photoPath: profile.photoPath,
      role: profile.role,
    );
  }

  Future<bool> save(UserProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(
      _keyFor(profile.email),
      jsonEncode({
        'name': profile.name,
        'phone': profile.phone,
        'photoPath': profile.photoPath,
        'id': profile.id,
        'role': profile.role,
      }),
    );
  }

  String _keyFor(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final encodedEmail = base64Url.encode(utf8.encode(normalizedEmail));
    return 'sip_mobile_profile_$encodedEmail';
  }
}
