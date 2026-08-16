import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/core/providers/app_mode_provider.dart';
import 'package:sakan_app/core/theme/app_colors.dart';

import 'package:sakan_app/shared/widgets/auth_guard_dialog.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';

class ModeToggleAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;

  const ModeToggleAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
  }) : assert(title != null || titleWidget != null);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isHosting = mode == AppMode.hosting;
    final authState = ref.watch(authProvider);

    return AppBar(
      centerTitle: true,
      // العنوان في المنتصف وبخط عريض وشكله بريميوم
      title: titleWidget ?? Text(
        title!,
        style: const TextStyle(
          fontWeight: FontWeight.w900, 
          letterSpacing: -0.8,
          fontSize: 20,
        ),
      ),
      // الجرس بقا على اليمين (في الـ leading بتاع الـ RTL)
      leadingWidth: 70, 
      leading: actions != null && actions!.isNotEmpty 
          ? Center(child: actions!.first) 
          : null,
      actions: [
        // زرار المود بقا "رقيق" وصغير وشكله شيك على الشمال
        Padding(
          padding: const EdgeInsetsDirectional.only(end: 12),
          child: Center(
            child: SizedBox(
              height: 28, // صغرنا الارتفاع جداً عشان يبقا رقيق
              child: TextButton(
                onPressed: () {
                  if (!isHosting && !authState.isAuthenticated) {
                    AuthGuardDialog.show(context);
                    return;
                  }
                  ref.read(appModeProvider.notifier).state =
                      isHosting ? AppMode.renting : AppMode.hosting;
                },
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.carbon900.withAlpha(30),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isHosting ? Icons.search : Icons.home_work,
                      color: AppColors.carbon900,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isHosting
                          ? context.translate('switch_to_renting')
                          : context.translate('switch_to_hosting'),
                      style: const TextStyle(
                        color: AppColors.carbon900, 
                        fontSize: 9, // أصغر خط ممكن وواضح
                        fontWeight: FontWeight.w900
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
