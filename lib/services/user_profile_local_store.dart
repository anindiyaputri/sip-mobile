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
