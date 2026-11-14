import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/state/auth_provider.dart';
import '../state/admin_provider.dart';

class AdminUsersView extends ConsumerStatefulWidget {
  const AdminUsersView({super.key});

  @override
  ConsumerState<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends ConsumerState<AdminUsersView> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Kelola Pengguna',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF6366F1),
          indicatorWeight: 3,
          labelColor: const Color(0xFF6366F1),
          unselectedLabelColor: const Color(0xFF64748B),
          labelStyle: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: const [
            Tab(text: '🧒 Anak-Anak'),
            Tab(text: '👨‍👩‍👧 Orang Tua / Admin'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUserDialog(context, ref),
        backgroundColor: const Color(0xFF6366F1),
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: Text(
          'Tambah Pengguna',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _UserListTab(isChild: true),
          const _UserListTab(isChild: false),
        ],
      ),
    );
  }

  void _showCreateUserDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    int selectedRole = 1; // 0 = Admin, 1 = Child
    final repo = ref.read(adminRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Tambah Pengguna Baru',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Nama Lengkap *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email / Username *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password *',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Peran:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Anak'),
                        selected: selectedRole == 1,
                        onSelected: (val) => setDialogState(() => selectedRole = 1),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Orang Tua'),
                        selected: selectedRole == 0,
                        onSelected: (val) => setDialogState(() => selectedRole = 0),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  final email = emailController.text.trim();
                  final password = passwordController.text.trim();
                  if (name.isEmpty || email.isEmpty || password.isEmpty) return;

                  await repo.createUser({
                    'name': name,
                    'email': email,
                    'password': password,
                    'role': selectedRole,
                  });
                  ref.invalidate(adminUsersListProvider);
                  if (context.mounted) Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Tambah'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _UserListTab extends ConsumerWidget {
  final bool isChild;
  const _UserListTab({required this.isChild});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersListProvider);
    final repo = ref.read(adminRepositoryProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.refresh(adminUsersListProvider),
      child: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text('Gagal memuat pengguna: $err'),
          ),
        ),
        data: (allUsers) {
          final users = allUsers.where((u) {
            final role = u['role']?.toString().toLowerCase();
            if (isChild) {
              return role == 'child' || role == '1';
            } else {
              return role == 'admin' || role == '0';
            }
          }).toList();

          if (users.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  isChild ? 'Belum ada akun anak.' : 'Belum ada akun orang tua.',
                  style: GoogleFonts.plusJakartaSans(color: const Color(0xFF64748B)),
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final id = user['id']?.toString() ?? '';
              final name = user['name'] as String? ?? 'User';
              final email = user['email'] as String? ?? '';
              final avatarUrl = user['avatarUrl'] as String?;
              final totalPoints = (user['totalPoints'] as num?)?.toInt() ?? 0;
              final currentStreak = (user['currentStreak'] as num?)?.toInt() ?? 0;

              return Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    // Avatar with upload photo button
                    GestureDetector(
                      onTap: () => _pickAndUploadAvatar(context, ref, id),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 26,
                            backgroundColor: isChild ? const Color(0xFF8B5CF6) : const Color(0xFF6366F1),
                            backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                                ? NetworkImage(
                                    avatarUrl.startsWith('http')
                                        ? avatarUrl
                                        : '${ApiConstants.baseHost}$avatarUrl',
                                  )
                                : null,
                            child: avatarUrl == null || avatarUrl.isEmpty
                                ? Text(
                                    name.isNotEmpty ? name[0] : '?',
                                    style: const TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
                                  )
                                : null,
                          ),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 14, color: Color(0xFF6366F1)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            email,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: const Color(0xFF64748B),
                            ),
                          ),
                          if (isChild) ...[
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFEF3C7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '★ $totalPoints poin',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFD97706),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF1F2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '🔥 $currentStreak hari',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFE11D48),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, size: 20, color: Color(0xFF94A3B8)),
                      onSelected: (val) async {
                        if (val == 'edit') {
                          _showEditUserDialog(context, ref, id, name);
                        } else if (val == 'delete') {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Nonaktifkan Pengguna?'),
                              content: Text('Yakin ingin menonaktifkan akun "$name"?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Nonaktifkan', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await repo.deleteUser(id);
                            ref.invalidate(adminUsersListProvider);
                          }
                        }
                      },
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit Nama / Password')),
                        const PopupMenuItem(value: 'delete', child: Text('Nonaktifkan', style: TextStyle(color: Colors.red))),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _pickAndUploadAvatar(BuildContext context, WidgetRef ref, String userId) async {
    final picker = ImagePicker();
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil dari Kamera'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null) return;
    final image = await picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
    if (image == null) return;

    final repo = ref.read(adminRepositoryProvider);
    try {
      await repo.uploadAvatar(userId, image.path);
      ref.invalidate(adminUsersListProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto profil berhasil diperbarui!')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal upload foto: $e')),
        );
      }
    }
  }

  void _showEditUserDialog(BuildContext context, WidgetRef ref, String id, String currentName) {
    final nameController = TextEditingController(text: currentName);
    final passwordController = TextEditingController();
    final repo = ref.read(adminRepositoryProvider);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Edit Pengguna',
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: 'Password Baru (Kosongkan jika tidak diubah)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              final newPassword = passwordController.text.trim();
              final payload = <String, dynamic>{'name': newName};
              if (newPassword.isNotEmpty) {
                payload['password'] = newPassword;
              }
              await repo.updateUser(id, payload);
              ref.invalidate(adminUsersListProvider);
              if (context.mounted) Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}
