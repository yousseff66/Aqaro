import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/core/providers/app_mode_provider.dart';
import 'package:sakan_app/core/theme/app_colors.dart';

import 'package:sakan_app/shared/widgets/auth_guard_dialog.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';

class BottomNavBar extends ConsumerWidget {
  final int currentIndex;
  final Function(int) onTap;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(appModeProvider);
    final isHosting = mode == AppMode.hosting;
    final authState = ref.watch(authProvider);

    return NavigationBarTheme(
      data: NavigationBarThemeData(
        indicatorColor: AppColors.lime500,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(color: AppColors.carbon900, fontWeight: FontWeight.bold, fontSize: 12);
          }
          return const TextStyle(color: AppColors.muted, fontSize: 12);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.carbon900);
          }
          return const IconThemeData(color: AppColors.muted);
        }),
      ),
      child: NavigationBar(
        backgroundColor: AppColors.white,
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          if (!authState.isAuthenticated) {
            final isFavorites = !isHosting && index == 2;
            if (isFavorites) {
              AuthGuardDialog.show(context);
              return;
            }
          }
          onTap(index);
        },
        destinations: isHosting ? _buildHostingDestinations(context) : _buildRentingDestinations(context),
      ),
    );
  }

  List<NavigationDestination> _buildRentingDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: context.translate('home'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.search),
        selectedIcon: const Icon(Icons.search),
        label: context.translate('search'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.favorite_border),
        selectedIcon: const Icon(Icons.favorite),
        label: context.translate('favorites'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.translate('profile'),
      ),
    ];
  }

  List<NavigationDestination> _buildHostingDestinations(BuildContext context) {
    return [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: context.translate('dashboard'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.payment_outlined),
        selectedIcon: const Icon(Icons.payment),
        label: context.translate('payments'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.notifications_outlined),
        selectedIcon: const Icon(Icons.notifications),
        label: context.translate('notifications'),
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: context.translate('profile'),
      ),
    ];
  }
}
