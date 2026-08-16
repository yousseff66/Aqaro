import 'package:flutter/material.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/auth/presentation/screens/login_screen.dart';

class AuthGuardDialog extends StatelessWidget {
  final String title;
  final String message;

  const AuthGuardDialog({
    super.key,
    required this.title,
    required this.message,
  });

  static Future<void> show(BuildContext context, {String? title, String? message}) {
    return showDialog(
      context: context,
      builder: (context) => AuthGuardDialog(
        title: title ?? context.translate('auth_required_title') ?? 'Authentication Required',
        message: message ?? context.translate('auth_required_message') ?? 'Please login to access this feature.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(context.translate('cancel') ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: Text(context.translate('login') ?? 'Login'),
        ),
      ],
    );
  }
}
