import 'package:flutter/material.dart';

import 'package:flutter_application_1/models/user_profile.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
  });

  final UserProfile userProfile;
  final Future<bool> Function(UserProfile profile) onProfileUpdated;

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final _formKey = GlobalKey<FormState>();
  late UserProfile _userProfile;
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _userProfile = widget.userProfile;
    _nameController = TextEditingController(text: _userProfile.name ?? '');
    _phoneController = TextEditingController(text: _userProfile.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _cancelChanges() {
    _nameController.text = _userProfile.name ?? '';
    _phoneController.text = _userProfile.phone ?? '';
    FocusScope.of(context).unfocus();
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Perubahan yang belum disimpan dibatalkan.'),
        ),
      );
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final updatedProfile = _userProfile.withEditableDetails(
      name: _nameController.text,
      phone: _phoneController.text,
    );

    setState(() => _isSaving = true);
    var saved = false;
    try {
      saved = await widget.onProfileUpdated(updatedProfile);
    } on Exception {
      saved = false;
    }
    if (!mounted) return;

    setState(() {
      _isSaving = false;
      if (saved) _userProfile = updatedProfile;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Pengaturan akun disimpan di perangkat ini.'
                : 'Pengaturan akun gagal disimpan. Silakan coba lagi.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan Akun'),
        leading: IconButton(
          tooltip: 'Kembali ke Profil',
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              const Text(
                'Informasi Akun',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              _ReadOnlyAccountField(
                icon: Icons.email_outlined,
                label: 'Email Login',
                value: _userProfile.email,
                helperText: 'Email tidak dapat diubah melalui pengaturan ini.',
              ),
              if (_userProfile.role != null &&
                  _userProfile.role!.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                _ReadOnlyAccountField(
                  icon: Icons.admin_panel_settings_outlined,
                  label: 'Peran pengguna',
                  value: _userProfile.role!.trim(),
                ),
              ],
              const SizedBox(height: 24),
              const Text(
                'Edit Profil',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Perubahan disimpan secara lokal di perangkat dan tidak '
                'disinkronkan ke server.',
                style: TextStyle(color: Color(0xFF687386), fontSize: 13),
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('account_settings_name_field'),
                controller: _nameController,
                enabled: !_isSaving,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama lengkap wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                key: const Key('account_settings_phone_field'),
                controller: _phoneController,
                enabled: !_isSaving,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon (opsional)',
                  prefixIcon: Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final phone = value?.trim() ?? '';
                  if (phone.isNotEmpty &&
                      !RegExp(r'^\+?[0-9 -]{7,20}$').hasMatch(phone)) {
                    return 'Masukkan nomor telepon yang valid';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSaving ? null : _cancelChanges,
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSaving ? null : _saveChanges,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Simpan'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReadOnlyAccountField extends StatelessWidget {
  const _ReadOnlyAccountField({
    required this.icon,
    required this.label,
    required this.value,
    this.helperText,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      child: Text(value),
    );
  }
}
