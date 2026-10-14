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
    if ((name != null && name is! String) ||
        (phone != null && phone is! String)) {
      throw const FormatException('Data profil lokal memiliki format salah.');
    }

    return UserProfile(
      email: email,
      name: name as String?,
      phone: phone as String?,
    );
  }

  Future<UserProfile> loadForLogin(String email) async {
    final profile = await load(email);
    final normalizedEmail = email.trim().toLowerCase();
    final normalizedName = profile.name?.trim().toLowerCase();
    final shouldInitializeAdminName =
        normalizedEmail == 'admin@gmail.com' &&
        (normalizedName == null ||
            normalizedName.isEmpty ||
            normalizedName == 'nama belum diisi');

    if (!shouldInitializeAdminName) return profile;

    final adminProfile = UserProfile(
      id: profile.id,
      email: email.trim(),
      name: 'Admin',
      phone: profile.phone,
      role: profile.role,
    );
    final saved = await save(adminProfile);
    if (!saved) {
      throw StateError('Nama Admin gagal disimpan di perangkat ini.');
    }
    return adminProfile;
  }

  Future<bool> save(UserProfile profile) async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.setString(
      _keyFor(profile.email),
      jsonEncode({'name': profile.name, 'phone': profile.phone}),
    );
  }

  String _keyFor(String email) {
    final normalizedEmail = email.trim().toLowerCase();
    final encodedEmail = base64Url.encode(utf8.encode(normalizedEmail));
    return 'sip_mobile_profile_$encodedEmail';
  }
}
