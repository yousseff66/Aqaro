import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/properties/presentation/providers/property_provider.dart';
import 'package:sakan_app/shared/widgets/property_card.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';
import 'package:sakan_app/features/properties/presentation/screens/create_listing_screen.dart';
import 'package:sakan_app/features/notifications/presentation/providers/notification_provider.dart';
import 'package:sakan_app/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:sakan_app/core/theme/app_colors.dart';
import 'dart:async';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

import 'package:sakan_app/shared/widgets/auth_guard_dialog.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Widget _buildFilterButton(BuildContext context, WidgetRef ref, String? value, String label, bool isSelected) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          ref.read(homePurposeFilterProvider.notifier).state = value;
          ref.read(propertyListProvider.notifier).fetchProperties(refresh: true, listingPurpose: value);
          // Explicitly invalidate featured properties to ensure they sync with the new filter
          ref.invalidate(featuredPropertiesProvider);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            boxShadow: isSelected 
              ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ] 
              : [],
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? AppColors.carbon900 : AppColors.muted,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertiesAsync = ref.watch(propertyListProvider);
    final featuredAsync = ref.watch(featuredPropertiesProvider);
    final purposeFilter = ref.watch(homePurposeFilterProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(
        title: context.translate('app_title'),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadAsync = ref.watch(unreadCountProvider);
              final count = unreadAsync.maybeWhen(data: (c) => c, orElse: () => 0);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                        constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                        child: Text(
                          count > 9 ? '9+' : count.toString(),
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(propertyListProvider.notifier).fetchProperties(
                refresh: true,
                listingPurpose: ref.read(homePurposeFilterProvider),
              );
          ref.invalidate(featuredPropertiesProvider);
        },
        child: ListView(
          children: [
            // Quick Filter Tabs
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.divider.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    _buildFilterButton(context, ref, null, context.translate('all') ?? 'All', purposeFilter == null),
                    _buildFilterButton(context, ref, 'Rent', context.translate('for_rent') ?? 'For Rent', purposeFilter == 'Rent'),
                    _buildFilterButton(context, ref, 'Sale', context.translate('for_sale') ?? 'For Sale', purposeFilter == 'Sale'),
                  ],
                ),
              ),
            ),
            // Featured Properties Section
            featuredAsync.when(
              data: (featuredProperties) {
                if (featuredProperties.isEmpty) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            context.translate('featured_properties'),
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: -0.5),
                          ),
                          Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.primary, size: 20),
                        ],
                      ),
                    ),
                    FeaturedSlider(featuredProperties: featuredProperties),
                  ],
                );
              },
              loading: () => const SizedBox(
                height: 280,
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => const SizedBox.shrink(),
            ),

            // Latest Listings Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                context.translate('latest_listings'),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            propertiesAsync.when(
              data: (properties) {
                if (properties.isEmpty) {
                  return Center(child: Text(context.translate('no_properties_found')));
                }
                return Column(
                  children: [
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: properties.length,
                      itemBuilder: (context, index) {
                        final property = properties[index];
                        return PropertyCard(
                          property: property,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PropertyDetailScreen(propertyId: property.id!),
                            ),
                          ),
                        );
                      },
                    ),
                    if (properties.length >= 10)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: TextButton(
                          onPressed: () => ref.read(propertyListProvider.notifier).loadMore(),
                          child: Text(context.translate('load_more')),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(child: Text('Error: $error')),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final authState = ref.read(authProvider);
          if (!authState.isAuthenticated) {
            AuthGuardDialog.show(context);
            return;
          }
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateListingScreen()),
          );
        },
        label: Text(context.translate('add_listing')),
        icon: const Icon(Icons.add),
      ),
    );
  }
}

class FeaturedSlider extends StatefulWidget {
  final List featuredProperties;
  const FeaturedSlider({super.key, required this.featuredProperties});

  @override
  State<FeaturedSlider> createState() => _FeaturedSliderState();
}

class _FeaturedSliderState extends State<FeaturedSlider> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: 0);
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < widget.featuredProperties.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 330,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.featuredProperties.length,
            onPageChanged: (index) => setState(() => _currentPage = index),
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 0.0;
                  if (_pageController.position.haveDimensions) {
                    value = index.toDouble() - (_pageController.page ?? 0);
                    value = (value * 0.05).clamp(-1.0, 1.0);
                  }
                  
                  // تأثير الـ Scale والـ Rotation الخفيف للمودرن ديزاين
                  return Transform.scale(
                    scale: 1.0 - (value.abs() * 0.8),
                    child: Opacity(
                      opacity: (1.0 - (value.abs() * 0.5)).clamp(0.7, 1.0),
                      child: child,
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      if (_currentPage == index)
                        BoxShadow(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                          blurRadius: 20,
                          spreadRadius: -5,
                          offset: const Offset(0, 10),
                        ),
                    ],
                  ),
                  child: PropertyCard(
                    property: widget.featuredProperties[index],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PropertyDetailScreen(
                          propertyId: widget.featuredProperties[index].id!,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicators المودرن
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.featuredProperties.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 6,
              width: _currentPage == index ? 24 : 8,
              decoration: BoxDecoration(
                color: _currentPage == index 
                    ? Theme.of(context).colorScheme.primary 
                    : Theme.of(context).colorScheme.primary.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
                boxShadow: _currentPage == index ? [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 4,
                  )
                ] : [],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
