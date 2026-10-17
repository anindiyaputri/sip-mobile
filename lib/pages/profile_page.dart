import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:flutter_application_1/models/user_profile.dart';
import 'package:flutter_application_1/pages/account_settings_page.dart';
import 'package:flutter_application_1/services/user_profile_photo_store.dart';

enum _ProfilePhotoSource { camera, gallery, device }

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.userProfile,
    required this.onProfileUpdated,
    required this.onLogout,
  });

  final UserProfile userProfile;
  final Future<bool> Function(UserProfile profile) onProfileUpdated;
  final VoidCallback onLogout;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _primaryColor = Color(0xFF3157D5);
  final _imagePicker = ImagePicker();
  final _photoStore = UserProfilePhotoStore();
  String? _photoPath;
  bool _isChangingPhoto = false;

  String _displayValue(String? value, {String fallback = 'Belum tersedia'}) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();

  UserProfile get userProfile => widget.userProfile;
  Future<bool> Function(UserProfile profile) get onProfileUpdated =>
      widget.onProfileUpdated;
  VoidCallback get onLogout => widget.onLogout;

  @override
  void initState() {
    super.initState();
    _photoPath = userProfile.photoPath;
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userProfile.photoPath != userProfile.photoPath) {
      _photoPath = userProfile.photoPath;
    }
  }

  Future<void> _changeProfilePhoto() async {
    final source = await showModalBottomSheet<_ProfilePhotoSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Ambil foto menggunakan kamera'),
              onTap: () =>
                  Navigator.of(context).pop(_ProfilePhotoSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Pilih foto dari galeri'),
              onTap: () =>
                  Navigator.of(context).pop(_ProfilePhotoSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text('Pilih foto dari perangkat'),
              onTap: () =>
                  Navigator.of(context).pop(_ProfilePhotoSource.device),
            ),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;

    setState(() => _isChangingPhoto = true);
    try {
      final sourcePath = switch (source) {
        _ProfilePhotoSource.camera => (await _imagePicker.pickImage(
          source: ImageSource.camera,
        ))?.path,
        _ProfilePhotoSource.gallery => (await _imagePicker.pickImage(
          source: ImageSource.gallery,
        ))?.path,
        _ProfilePhotoSource.device => await _pickImageFromDevice(),
      };
      if (sourcePath == null || !mounted) return;

      final persistentPath = await _photoStore.savePickedImage(
        email: userProfile.email,
        sourcePath: sourcePath,
      );
      final updatedProfile = userProfile.withProfilePhoto(persistentPath);
      final saved = await onProfileUpdated(updatedProfile);
      if (!mounted) return;

      if (!saved) {
        _showPhotoMessage('Foto profil gagal disimpan. Silakan coba lagi.');
        return;
      }
      setState(() => _photoPath = persistentPath);
    } on PlatformException catch (error) {
      if (!mounted) return;
      _showPhotoMessage(
        'Akses kamera, galeri, atau file perangkat gagal: '
        '${error.message ?? error.code}',
      );
    } on FileSystemException catch (error) {
      if (!mounted) return;
      _showPhotoMessage('File foto tidak dapat disimpan: ${error.message}');
    } on Exception catch (error) {
      if (!mounted) return;
      _showPhotoMessage('Foto profil gagal diperbarui: $error');
    } finally {
      if (mounted) setState(() => _isChangingPhoto = false);
    }
  }

  Future<String?> _pickImageFromDevice() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const [
        'jpg',
        'jpeg',
        'png',
        'gif',
        'webp',
        'bmp',
        'heic',
        'heif',
      ],
      dialogTitle: 'Pilih foto profil',
    );
    if (file == null) return null;

    final path = file.path;
    if (path == null || path.isEmpty) {
      throw const FormatException(
        'Lokasi file foto yang dipilih tidak dapat dibaca.',
      );
    }
    return path;
  }

  void _showPhotoMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

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
              photoPath: _photoPath,
              isChangingPhoto: _isChangingPhoto,
              onChangePhoto: _changeProfilePhoto,
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
                  key: const Key('profile_account_settings'),
                  icon: Icons.manage_accounts_outlined,
                  title: 'Pengaturan Akun',
                  subtitle: 'Lihat dan perbarui informasi akun',
                  onTap: () => _openAccountSettings(context),
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

  Future<void> _openAccountSettings(BuildContext context) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => AccountSettingsPage(
          userProfile: userProfile,
          onProfileUpdated: onProfileUpdated,
        ),
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
          'Anda akan kembali ke halaman masuk. Nama dan nomor telepon tetap '
          'tersimpan secara lokal di perangkat ini.',
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
    required this.photoPath,
    required this.isChangingPhoto,
    required this.onChangePhoto,
  });

  final String name;
  final String email;
  final String? role;
  final String? photoPath;
  final bool isChangingPhoto;
  final VoidCallback onChangePhoto;

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
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: photoPath == null || photoPath!.isEmpty
                    ? const Icon(
                        Icons.person_outline,
                        size: 46,
                        color: Color(0xFF3157D5),
                      )
                    : Image.file(
                        key: const Key('profile_photo_image'),
                        File(photoPath!),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.person_outline,
                              size: 46,
                              color: Color(0xFF3157D5),
                            ),
                      ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: Colors.white,
                  shape: const CircleBorder(),
                  child: IconButton(
                    key: const Key('profile_photo_button'),
                    tooltip: 'Ganti foto profil',
                    onPressed: isChangingPhoto ? null : onChangePhoto,
                    constraints: const BoxConstraints.tightFor(
                      width: 34,
                      height: 34,
                    ),
                    padding: EdgeInsets.zero,
                    icon: isChangingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(
                            Icons.camera_alt_outlined,
                            size: 19,
                            color: Color(0xFF3157D5),
                          ),
                  ),
                ),
              ),
            ],
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
    super.key,
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
