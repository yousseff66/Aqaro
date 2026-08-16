import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/shared/models/user_model.dart';

class UsersManagementScreen extends ConsumerWidget {
  const UsersManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(allUsersProvider);
    final currentUser = ref.watch(authProvider).user;
    final actionState = ref.watch(adminActionProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(allUsersProvider.future),
      child: usersAsync.when(
          data: (users) {
            if (users.isEmpty) return Center(child: Text(context.translate('no_users_found')));
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                final user = users[index];
                final isMe = user.id == currentUser?.id;

                return Opacity(
                  opacity: user.isBanned ? 0.6 : 1.0,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: user.isBanned ? Colors.grey : null,
                      child: Text(user.name[0].toUpperCase()),
                    ),
                    title: Row(
                      children: [
                        Text(user.name),
                        if (isMe)
                          Container(
                            margin: const EdgeInsetsDirectional.only(start: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              context.translate('me') ?? 'Me',
                              style: const TextStyle(fontSize: 10, color: Colors.blue),
                            ),
                          ),
                        if (user.isBanned)
                          const Padding(
                            padding: EdgeInsetsDirectional.only(start: 8.0),
                            child: Icon(Icons.block, color: Colors.red, size: 16),
                          ),
                      ],
                    ),
                    subtitle: Text(
                      '${user.email} • ${user.role}',
                      style: TextStyle(color: user.isBanned ? Colors.red : null),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'edit_role') {
                          _showChangeRoleDialog(context, ref, user);
                        } else if (val == 'toggle_ban') {
                          _showToggleBanConfirmation(context, ref, user);
                        } else if (val == 'delete') {
                          _showDeleteConfirmation(context, ref, user);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'edit_role',
                          child: Text(context.translate('change_role') ?? 'Change Role'),
                        ),
                        if (!isMe) ...[
                          PopupMenuItem(
                            value: 'toggle_ban',
                            child: Text(user.isBanned
                                ? (context.translate('unblock_user') ?? 'Unblock')
                                : (context.translate('block_user') ?? 'Block')),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text(
                              context.translate('delete'),
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      );
  }

  void _showChangeRoleDialog(BuildContext context, WidgetRef ref, User user) {
    final newRole = user.role == 'Admin' ? 'User' : 'Admin';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('change_role') ?? 'Change Role'),
        content: Text(
          context.translate('change_role_confirmation') ?? 'Change ${user.name}\'s role from ${user.role} to $newRole?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionProvider.notifier).updateUserRole(user.id, newRole);
              if (context.mounted) {
                final state = ref.read(adminActionProvider);
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('role_updated') ?? 'Role updated')));
                }
              }
            },
            child: Text(context.translate('confirm') ?? 'Confirm'),
          ),
        ],
      ),
    );
  }

  void _showToggleBanConfirmation(BuildContext context, WidgetRef ref, User user) {
    final willBan = !user.isBanned;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(willBan ? (context.translate('block_user') ?? 'Block User') : (context.translate('unblock_user') ?? 'Unblock User')),
        content: Text(
          willBan
              ? (context.translate('block_user_confirmation') ?? 'Block ${user.name}? They won\'t be able to log in.')
              : (context.translate('unblock_user_confirmation') ?? 'Unblock ${user.name}?'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionProvider.notifier).toggleBanUser(user.id);
              if (context.mounted) {
                final state = ref.read(adminActionProvider);
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: willBan ? Colors.red : Colors.green),
            child: Text(willBan ? (context.translate('block_user') ?? 'Block') : (context.translate('unblock_user') ?? 'Unblock')),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, User user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('delete_user') ?? 'Delete User'),
        content: Text(
          context.translate('delete_user_confirmation') ?? 'Delete ${user.name} permanently? This will also delete all their properties and data.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(adminActionProvider.notifier).deleteUser(user.id);
              if (context.mounted) {
                final state = ref.read(adminActionProvider);
                if (state.hasError) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${state.error}')));
                }
              }
            },
            child: Text(context.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
