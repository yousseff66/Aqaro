import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:sakan_app/shared/widgets/property_card.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

import 'package:sakan_app/shared/widgets/guest_prompt_card.dart';
import 'package:dio/dio.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (!authState.isAuthenticated) {
      return Scaffold(
        appBar: ModeToggleAppBar(
          title: context.translate('my_favorites'),
        ),
        body: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Center(
            child: GuestPromptCard(),
          ),
        ),
      );
    }

    final favoritesAsync = ref.watch(favoritesListProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(
        title: context.translate('my_favorites') ?? 'My Favorites',
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(favoritesListProvider),
        child: favoritesAsync.when(
          data: (properties) {
            if (properties.isEmpty) {
              return ListView(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.7,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_border, size: 80, color: Colors.grey),
                          const SizedBox(height: 16),
                          Text(context.translate('no_favorites') ?? 'No favorites yet'),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              itemCount: properties.length,
              itemBuilder: (context, index) {
                final property = properties[index];
                if (property.id == null) {
                  return const SizedBox.shrink();
                }
                return PropertyCard(
                  property: property,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailScreen(propertyId: property.id!),
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, stack) {
            final isAuthError = e is DioException && e.response?.statusCode == 401;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Text(
                      isAuthError
                          ? (context.translate('session_expired') ?? 'انتهت صلاحية الجلسة، برجاء تسجيل الدخول مرة أخرى')
                          : (context.translate('something_went_wrong') ?? 'حدث خطأ ما، حاول مرة أخرى'),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (isAuthError) {
                        ref.read(authProvider.notifier).logout();
                      } else {
                        ref.invalidate(favoritesListProvider);
                      }
                    },
                    child: Text(
                      isAuthError ? (context.translate('login') ?? 'تسجيل الدخول') : 'Retry',
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}