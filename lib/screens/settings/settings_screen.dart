import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smartfactory/config/theme.dart';
import 'package:smartfactory/models/profile.dart';
import 'package:smartfactory/providers/auth_provider.dart';
import 'package:smartfactory/repositories/auth_repository.dart';
import 'package:smartfactory/utils/format_utils.dart';
import 'package:smartfactory/widgets/common/error_state.dart';
import 'package:smartfactory/widgets/common/loading_state.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: profileAsync.when(
        loading: () => const LoadingState(),
        error: (err, _) => ErrorState(error: err),
        data: (profile) {
          if (profile == null) return const SizedBox();
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Profile card
                _ProfileCard(profile: profile),
                const SizedBox(height: 16),

                // Admin section
                if (profile.role == 'admin') ...[
                  _UserManagementSection(),
                  const SizedBox(height: 16),
                ],

                // Sign out
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.logout, color: AppColors.error),
                    title: const Text(
                      '退出登录',
                      style: TextStyle(color: AppColors.error),
                    ),
                    onTap: () async {
                      await ref
                          .read(authNotifierProvider.notifier)
                          .signOut();
                    },
                  ),
                ),

                const SizedBox(height: 32),
                Text(
                  'SmartFactory v1.0.0',
                  style: const TextStyle(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileCard extends ConsumerStatefulWidget {
  final Profile profile;

  const _ProfileCard({required this.profile});

  @override
  ConsumerState<_ProfileCard> createState() => _ProfileCardState();
}

class _ProfileCardState extends ConsumerState<_ProfileCard> {
  final _nameCtrl = TextEditingController();
  final _deptCtrl = TextEditingController();
  bool _editing = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.text = widget.profile.fullName ?? '';
    _deptCtrl.text = widget.profile.department ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _deptCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    widget.profile.displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.profile.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        widget.profile.email,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          FormatUtils.roleLabel(widget.profile.role),
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(_editing ? Icons.close : Icons.edit_outlined),
                  onPressed: () => setState(() {
                    _editing = !_editing;
                    if (!_editing) {
                      _nameCtrl.text = widget.profile.fullName ?? '';
                      _deptCtrl.text = widget.profile.department ?? '';
                    }
                  }),
                ),
              ],
            ),
            if (_editing) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: '姓名',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _deptCtrl,
                decoration: const InputDecoration(
                  labelText: '部门',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                              CircularProgressIndicator(color: Colors.white),
                        )
                      : const Text('保存'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(currentProfileProvider.notifier).updateProfile({
        'full_name': _nameCtrl.text.trim().isEmpty
            ? null
            : _nameCtrl.text.trim(),
        'department': _deptCtrl.text.trim().isEmpty
            ? null
            : _deptCtrl.text.trim(),
      });
      if (mounted) setState(() => _editing = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _UserManagementSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profilesAsync = ref.watch(allProfilesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: AppColors.primary),
                SizedBox(width: 8),
                Text(
                  '用户管理',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            profilesAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('加载失败: $e'),
              data: (profiles) => Column(
                children: profiles
                    .map((p) => _UserTile(profile: p))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserTile extends ConsumerWidget {
  final Profile profile;

  const _UserTile({required this.profile});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.primaryLight,
        child: Text(
          profile.displayName.substring(0, 1).toUpperCase(),
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(profile.displayName),
      subtitle: Text(profile.email),
      trailing: DropdownButton<String>(
        value: profile.role,
        underline: const SizedBox(),
        isDense: true,
        items: const [
          DropdownMenuItem(value: 'admin', child: Text('管理员')),
          DropdownMenuItem(value: 'leader', child: Text('项目负责人')),
          DropdownMenuItem(value: 'qc', child: Text('质检员')),
          DropdownMenuItem(
              value: 'technician', child: Text('技术员')),
        ],
        onChanged: (newRole) async {
          if (newRole == null || newRole == profile.role) return;
          await ref
              .read(authRepositoryProvider)
              .updateProfile(profile.id, {'role': newRole});
          ref.invalidate(allProfilesProvider);
        },
      ),
    );
  }
}
