import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/main.dart';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

import 'package:sakan_app/features/auth/presentation/screens/about_screen.dart';
import 'package:sakan_app/features/auth/presentation/screens/login_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(
        title: context.translate('profile'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? context.translate('guest_user'),
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text(user?.email ?? ''),
            const SizedBox(height: 32),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.language),
                    title: Text(context.translate('language')),
                    trailing: Text(locale.languageCode == 'ar' ? 'العربية' : 'English'),
                    onTap: () {
                      final newLang = locale.languageCode == 'ar' ? 'en' : 'ar';
                      ref.read(localeProvider.notifier).setLocale(newLang);
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_android),
                    title: Text(context.translate('change_phone')),
                    subtitle: Text(user?.phone ?? ''),
                    onTap: () => _showChangePhoneDialog(context, ref),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dark_mode_outlined),
                    title: Text(context.translate('theme')),
                    trailing: Switch(
                      value: themeMode == ThemeMode.dark,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.history),
                    title: Text(context.translate('payments')),
                    onTap: () {
                      // TODO: Navigate to Payment History
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline),
                    title: Text(context.translate('about_sakan')),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const AboutScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (authState.isAuthenticated)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: Text(
                    context.translate('logout'),
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              )
            else
              Card(
                child: ListTile(
                  leading: const Icon(Icons.login, color: Colors.green),
                  title: Text(
                    context.translate('login'),
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
                ),
              ),
            if (authState.isAuthenticated) ...[
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.grey),
                  title: Text(
                    context.translate('delete_account'),
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                  onTap: () => _showDeleteAccountDialog(context, ref),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('delete_account_title') ?? 'Delete Account'),
        content: Text(context.translate('delete_account_confirmation') ?? 'Are you sure you want to delete your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.translate('cancel') ?? 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // إغلاق الديالوج
              
              // إظهار Loading
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (context) => const Center(child: CircularProgressIndicator()),
              );

              final result = await ref.read(authProvider.notifier).deleteAccount();
              
              if (context.mounted) {
                Navigator.pop(context); // إغلاق الـ Loading
                
                if (result['success'] == true) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.translate('account_deleted') ?? 'Account deleted')),
                  );
                  // الرجوع للهوم بعد المسح
                  Navigator.of(context).popUntil((route) => route.isFirst);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Error')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(context.translate('delete') ?? 'Delete'),
          ),
        ],
      ),
    );
  }

  void _showChangePhoneDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('change_phone')),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(hintText: '01xxxxxxxxx'),
            textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
            validator: (value) {
              if (value == null || !RegExp(r'^01[0125][0-9]{8}$').hasMatch(value)) {
                return context.translate('invalid_egyptian_phone');
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final result = await ref.read(authProvider.notifier).changePhone(controller.text.trim());
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(result['success'] == true
                            ? context.translate('phone_updated')
                            : result['message'])),
                  );
                }
              }
            },
            child: Text(context.translate('save')),
          ),
        ],
      ),
    );
  }
}
