import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_profile.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  final UserProfile userProfile;
  final Future<bool> Function(UserProfile profile) onProfileUpdated;
  final VoidCallback onLogout;

  static const _primaryColor = Color(0xFF3157D5);

  String _displayValue(String? value, {String fallback = 'Belum tersedia'}) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          children: [
            _ProfileHeader(
              name: _displayValue(
                userProfile.name,
                fallback: 'Nama belum diisi',
              ),
              email: _displayValue(userProfile.email),
              role: userProfile.role,
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Informasi Akun'),
            const SizedBox(height: 10),
            _AccountDetails(
              name: _displayValue(
                userProfile.name,
                fallback: 'Nama belum diisi',
              ),
              email: _displayValue(userProfile.email),
              phone: _displayValue(
                userProfile.phone,
                fallback: 'Nomor telepon belum diisi',
              ),
              role: userProfile.role,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _editProfile(context),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profil'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              color: const Color(0xFFE9EDFF),
              elevation: 0,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: _primaryColor, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Perubahan nama dan nomor telepon hanya tersimpan '
                        'secara lokal di perangkat ini dan belum disinkronkan '
                        'ke server.',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Pengaturan'),
            const SizedBox(height: 10),
            _SettingsCard(
              children: [
                _SettingsTile(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Pengaturan Akun',
                  subtitle: 'Kelola preferensi akun',
                  onTap: () => _showUnavailableDialog(
                    context,
                    'Pengaturan Akun',
                    'Pengaturan akun belum tersedia pada aplikasi ini.',
                  ),
                ),
                const Divider(height: 1, indent: 56),
                _SettingsTile(
                  icon: Icons.info_outline,
                  title: 'Tentang SIP Mobile',
                  subtitle: 'Informasi aplikasi',
                  onTap: () => _showAboutDialog(context),
                ),
                const Divider(height: 1, indent: 56),
                const _SettingsTile(
                  icon: Icons.verified_outlined,
                  title: 'Versi Aplikasi',
                  subtitle: '1.0.0+1',
                  showChevron: false,
                ),
              ],
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              key: const Key('profile_logout_button'),
              onPressed: () => _confirmLogout(context),
              icon: const Icon(Icons.logout),
              label: const Text('Keluar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFB3261E),
                minimumSize: const Size.fromHeight(52),
                side: const BorderSide(color: Color(0xFFE6B8B5)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editProfile(BuildContext context) async {
    final updatedProfile = await showDialog<UserProfile>(
      context: context,
      builder: (_) => _EditProfileDialog(userProfile: userProfile),
    );
    if (updatedProfile == null) return;

    var saved = false;
    try {
      saved = await onProfileUpdated(updatedProfile);
    } on Exception {
      saved = false;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            saved
                ? 'Profil disimpan di perangkat ini; belum disinkronkan ke server.'
                : 'Profil gagal disimpan. Silakan coba lagi.',
          ),
        ),
      );
  }

  Future<void> _showUnavailableDialog(
    BuildContext context,
    String title,
    String message,
  ) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Mengerti'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SIP Mobile',
      applicationVersion: '1.0.0+1',
      applicationIcon: const Icon(
        Icons.local_library,
        color: _primaryColor,
        size: 36,
      ),
      children: const [
        Text('Aplikasi mobile untuk membantu pengelolaan perpustakaan.'),
      ],
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.logout, color: Color(0xFFB3261E)),
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Anda akan kembali ke halaman masuk dan data profil lokal akan '
          'dihapus dari state aplikasi. Autentikasi server belum tersedia.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFB3261E),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );

    if (shouldLogout == true) onLogout();
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.role,
  });

  final String name;
  final String email;
  final String? role;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3157D5), Color(0xFF5878E8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 42,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_outline,
              size: 46,
              color: Color(0xFF3157D5),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            name,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            email,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFE9EDFF), fontSize: 14),
          ),
          if (role != null && role!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                role!.trim(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  const _AccountDetails({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  final String name;
  final String email;
  final String phone;
  final String? role;

  @override
  Widget build(BuildContext context) {
    return _SettingsCard(
      children: [
        _DetailRow(
          icon: Icons.badge_outlined,
          label: 'Nama lengkap',
          value: name,
        ),
        const Divider(height: 1, indent: 56),
        _DetailRow(icon: Icons.email_outlined, label: 'Email', value: email),
        const Divider(height: 1, indent: 56),
        _DetailRow(
          icon: Icons.phone_outlined,
          label: 'Nomor telepon',
          value: phone,
        ),
        if (role != null && role!.trim().isNotEmpty) ...[
          const Divider(height: 1, indent: 56),
          _DetailRow(
            icon: Icons.admin_panel_settings_outlined,
            label: 'Peran pengguna',
            value: role!.trim(),
          ),
        ],
      ],
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.userProfile});

  final UserProfile userProfile;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.userProfile.name ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.userProfile.phone ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Profil'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                key: const Key('profile_name_field'),
                controller: _nameController,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama lengkap',
                  prefixIcon: Icon(Icons.badge_outlined),
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
                key: const Key('profile_phone_field'),
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nomor telepon (opsional)',
                  prefixIcon: Icon(Icons.phone_outlined),
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
              const SizedBox(height: 12),
              const Text(
                'Email dan peran tidak dapat diubah di sini.',
                style: TextStyle(fontSize: 12, color: Color(0xFF687386)),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop(
              widget.userProfile.withEditableDetails(
                name: _nameController.text,
                phone: _phoneController.text,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE9ECF2)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.showChevron = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Icon(icon, color: const Color(0xFF3157D5)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Color(0xFF687386), fontSize: 12),
      ),
      trailing: showChevron
          ? const Icon(Icons.chevron_right, color: Color(0xFF687386))
          : null,
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF3157D5), size: 21),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF687386),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
