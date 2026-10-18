import 'package:flutter/material.dart';

import '../models/library_models.dart';
import '../services/user_account_store.dart';
import 'access_denied_page.dart';

class UserAccountsPage extends StatefulWidget {
  const UserAccountsPage({
    super.key,
    required this.session,
    required this.members,
    required this.accountStore,
  });

  final AuthenticatedSession session;
  final List<Member> members;
  final UserAccountStore accountStore;

  @override
  State<UserAccountsPage> createState() => _UserAccountsPageState();
}

class _UserAccountsPageState extends State<UserAccountsPage> {
  late final UserAccountStore _store = widget.accountStore;
  List<UserAccount> _accounts = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.session.role == UserRole.admin) _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    try {
      final accounts = await _store.listAccounts(widget.session);
      if (!mounted) return;
      setState(() {
        _accounts = accounts;
        _isLoading = false;
      });
    } on Exception catch (error) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage('Daftar akun gagal dimuat: $error');
    }
  }

  Future<void> _createAccount() async {
    final draft = await _showAccountDialog();
    if (!mounted || draft == null) return;
    await _save(() async {
      await _store.createAccount(
        session: widget.session,
        login: draft.login,
        password: draft.password!,
        role: draft.role,
        memberId: draft.memberId,
      );
    });
  }

  Future<void> _editAccount(UserAccount account) async {
    final draft = await _showAccountDialog(existing: account);
    if (!mounted || draft == null) return;
    await _save(() async {
      await _store.updateAccount(
        session: widget.session,
        userId: account.id,
        role: draft.role,
        memberId: draft.memberId,
        newPassword: draft.password,
      );
    });
  }

  Future<void> _deleteAccount(UserAccount account) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus akun?'),
        content: Text('Akun ${account.login} tidak dapat digunakan lagi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    await _save(
      () => _store.deleteAccount(session: widget.session, userId: account.id),
    );
  }

  Future<_AccountDraft?> _showAccountDialog({UserAccount? existing}) {
    return showDialog<_AccountDraft>(
      context: context,
      builder: (context) => _AccountDialog(
        existing: existing,
        accounts: _accounts,
        members: widget.members,
      ),
    );
  }

  Future<void> _save(Future<void> Function() action) async {
    setState(() => _isSaving = true);
    try {
      await action();
      await _loadAccounts();
    } on Exception catch (error) {
      if (mounted) _showMessage('Perubahan akun gagal disimpan: $error');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (widget.session.role != UserRole.admin) {
      return const AccessDeniedPage();
    }
    return Scaffold(
      appBar: AppBar(title: const Text('Data User')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
          ? const Center(child: Text('Belum ada akun pengguna.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Akun disimpan secara lokal pada perangkat ini.',
                  style: TextStyle(color: Color(0xFF667085)),
                ),
                const SizedBox(height: 12),
                for (final account in _accounts)
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.account_circle_outlined),
                      title: Text(account.login),
                      subtitle: Text(
                        '${account.role.label}'
                        '${account.memberId == null ? '' : ' • ID Anggota ${account.memberId}'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        enabled: !_isSaving,
                        tooltip: 'Tindakan akun',
                        onSelected: (action) {
                          if (action == 'edit') _editAccount(account);
                          if (action == 'delete') _deleteAccount(account);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text('Ubah akses'),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Hapus akun'),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isSaving ? null : _createAccount,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Tambah Akun'),
      ),
    );
  }
}

class _AccountDraft {
  const _AccountDraft({
    required this.login,
    required this.password,
    required this.role,
    required this.memberId,
  });

  final String login;
  final String? password;
  final UserRole role;
  final int? memberId;
}

class _AccountDialog extends StatefulWidget {
  const _AccountDialog({
    required this.accounts,
    required this.members,
    this.existing,
  });

  final List<UserAccount> accounts;
  final List<Member> members;
  final UserAccount? existing;

  @override
  State<_AccountDialog> createState() => _AccountDialogState();
}

class _AccountDialogState extends State<_AccountDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _loginController;
  final _passwordController = TextEditingController();
  late UserRole _role;
  int? _memberId;

  @override
  void initState() {
    super.initState();
    _loginController = TextEditingController(
      text: widget.existing?.login ?? '',
    );
    _role = widget.existing?.role ?? UserRole.siswa;
    _memberId = widget.existing?.memberId;
  }

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final linkedMemberIds = widget.accounts
        .where((account) => account.id != widget.existing?.id)
        .map((account) => account.memberId)
        .whereType<int>()
        .toSet();
    final availableMembers = widget.members
        .where(
          (member) =>
              !linkedMemberIds.contains(member.id) ||
              member.id == widget.existing?.memberId,
        )
        .toList();

    return AlertDialog(
      title: Text(widget.existing == null ? 'Tambah akun' : 'Ubah akun'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _loginController,
                enabled: widget.existing == null,
                decoration: const InputDecoration(
                  labelText: 'Email atau username',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Email/username wajib diisi.'
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: widget.existing == null
                      ? 'Kata sandi (minimal 8 karakter)'
                      : 'Kata sandi baru (opsional)',
                ),
                validator: (value) {
                  if (widget.existing == null && (value?.length ?? 0) < 8) {
                    return 'Kata sandi harus terdiri dari minimal 8 karakter.';
                  }
                  if (value != null && value.isNotEmpty && value.length < 8) {
                    return 'Kata sandi harus terdiri dari minimal 8 karakter.';
                  }
                  return null;
                },
              ),
              DropdownButtonFormField<UserRole>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Peran'),
                items: [
                  for (final role in UserRole.values)
                    DropdownMenuItem(value: role, child: Text(role.label)),
                ],
                onChanged: (role) {
                  if (role != null) setState(() => _role = role);
                },
              ),
              DropdownButtonFormField<int?>(
                initialValue: _memberId,
                decoration: const InputDecoration(
                  labelText: 'Tautkan ke anggota',
                ),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('Tidak ditautkan'),
                  ),
                  for (final member in availableMembers)
                    DropdownMenuItem<int?>(
                      value: member.id,
                      child: Text('${member.name} (ID ${member.id})'),
                    ),
                ],
                onChanged: (memberId) => setState(() => _memberId = memberId),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              _AccountDraft(
                login: _loginController.text.trim(),
                password: _passwordController.text.isEmpty
                    ? null
                    : _passwordController.text,
                role: _role,
                memberId: _memberId,
              ),
            );
          },
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}
