import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/properties/presentation/providers/property_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/core/theme/app_colors.dart';
import 'package:sakan_app/core/utils/formatters.dart';
import 'package:sakan_app/features/reports/presentation/widgets/report_property_dialog.dart';
import 'package:sakan_app/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sakan_app/features/reviews/presentation/widgets/add_review_dialog.dart';
import 'package:sakan_app/features/reviews/presentation/providers/review_provider.dart';
import 'package:sakan_app/shared/models/user_model.dart';
import 'package:sakan_app/features/properties/presentation/screens/owner_profile_screen.dart';

import 'package:sakan_app/shared/widgets/auth_guard_dialog.dart';

class PropertyDetailScreen extends ConsumerWidget {
  final String propertyId;
  final Property? initialProperty;

  const PropertyDetailScreen({
    super.key,
    required this.propertyId,
    this.initialProperty,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final propertyAsync = ref.watch(propertyDetailsProvider(propertyId));

    return propertyAsync.when(
      data: (property) => _PropertyDetailContent(property: property),
      loading: () => initialProperty != null 
          ? _PropertyDetailContent(property: initialProperty!)
          : const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class _PropertyDetailContent extends ConsumerStatefulWidget {
  final Property property;

  const _PropertyDetailContent({required this.property});

  @override
  ConsumerState<_PropertyDetailContent> createState() => _PropertyDetailContentState();
}

class _PropertyDetailContentState extends ConsumerState<_PropertyDetailContent> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final property = widget.property;
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350, // زودنا الارتفاع شوية للفخامة
            pinned: true,
            stretch: true,
            flexibleSpace: FlexibleSpaceBar(
              background: property.images.isNotEmpty
                  ? Stack(
                      children: [
                        // السلايدر الأساسي
                        PageView.builder(
                          controller: _pageController,
                          itemCount: property.images.length,
                          physics: const BouncingScrollPhysics(),
                          onPageChanged: (index) {
                            setState(() => _currentIndex = index);
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showFullScreenImages(context, property.images, index),
                              child: Hero(
                                tag: 'property_image_$index',
                                child: Image.network(
                                  property.images[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                        // أسهم التنقل (لسهولة الاستخدام)
                        if (property.images.length > 1) ...[
                          Positioned(
                            left: 8,
                            top: 0,
                            bottom: 0,
                            width: 48,
                            child: Center(
                              child: IconButton(
                                icon: const CircleAvatar(
                                  backgroundColor: Colors.black26,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (AppFormatters.isRTL(context)) {
                                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  } else {
                                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  }
                                },
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 0,
                            bottom: 0,
                            width: 48,
                            child: Center(
                              child: IconButton(
                                icon: const CircleAvatar(
                                  backgroundColor: Colors.black26,
                                  child: Directionality(
                                    textDirection: TextDirection.ltr,
                                    child: Icon(
                                      Icons.arrow_forward_ios,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  if (AppFormatters.isRTL(context)) {
                                    _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  } else {
                                    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                                  }
                                },
                              ),
                            ),
                          ),
                        ],
                        // تدرج ظلي خلفي عشان الأيقونات والـ Dots تبان بوضوح
                        Positioned.fill(
                          child: IgnorePointer(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent,
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.5),
                                  ],
                                  stops: const [0.0, 0.2, 0.8, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),
                        // مؤشر الصفحات (Dots)
                        if (property.images.length > 1)
                          Positioned(
                            bottom: 20,
                            left: 0,
                            right: 0,
                            child: IgnorePointer(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                  property.images.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.symmetric(horizontal: 3),
                                    height: 6,
                                    width: _currentIndex == index ? 20 : 6,
                                    decoration: BoxDecoration(
                                      color: _currentIndex == index 
                                          ? AppColors.lime500 
                                          : Colors.white.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    )
                  : Container(color: Colors.grey[300], child: const Icon(Icons.image, size: 100)),
            ),
            actions: [
              Consumer(
                builder: (context, ref, _) {
                  final isFavorite = ref.watch(favoriteIdsProvider).contains(property.id);
                  return IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : null,
                    ),
                    onPressed: () {
                      final authState = ref.read(authProvider);
                      if (!authState.isAuthenticated) {
                        AuthGuardDialog.show(context);
                        return;
                      }
                      if (property.id != null) {
                        ref.read(favoriteToggleProvider.notifier).toggle(property.id!, isFavorite);
                      }
                    },
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: () {
                  final String text = '${property.title}\n'
                      '${AppFormatters.formatCurrency(property.price)} ${context.translate('egp')}\n'
                      '${property.city}, ${property.governorate}\n'
                      'https://aqaroeg.com/property/${property.id}';
                  Share.share(text);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'report') {
                    final authState = ref.read(authProvider);
                    if (!authState.isAuthenticated) {
                      AuthGuardDialog.show(context);
                      return;
                    }
                    showDialog(
                      context: context,
                      builder: (context) => ReportPropertyDialog(propertyId: property.id!),
                    );
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'report',
                    child: Row(
                      children: [
                        const Icon(Icons.report_problem_outlined, color: Colors.red),
                        const SizedBox(width: 8),
                        Text(context.translate('report_property')),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (property.isFeatured) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: AppColors.onGold, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            context.translate('featured').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.onGold,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${AppFormatters.formatCurrency(property.price)} ${context.translate('egp')}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Row(
                        children: [
                          Icon(
                            property.listingPurpose?.toLowerCase() == 'sale' ? Icons.sell_outlined : Icons.calendar_month_outlined,
                            size: 16,
                            color: AppColors.muted,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            context.translate(property.listingPurpose?.toLowerCase() ?? 'sale'),
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    property.title,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('${property.city}, ${property.governorate}', style: const TextStyle(color: Colors.grey)),
                      if (property.publishedAt != null) ...[
                        const Spacer(),
                        const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy', 'en_US').format(property.publishedAt!),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _FeatureItem(icon: Icons.king_bed_outlined, label: '${property.bedrooms} ${context.translate('beds')}'),
                      _FeatureItem(icon: Icons.bathtub_outlined, label: '${property.bathrooms} ${context.translate('baths')}'),
                      _FeatureItem(icon: Icons.square_foot, label: '${AppFormatters.formatNumber(property.area)} ${context.translate('area_unit') ?? 'm²'}'),
                      if (property.floor != null) _FeatureItem(icon: Icons.layers_outlined, label: '${context.translate('floor')} ${property.floor}'),
                      if (property.furnished) _FeatureItem(icon: Icons.chair_outlined, label: context.translate('furnished')),
                    ],
                  ),
                  const Divider(height: 48),
                  Text(context.translate('description'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(property.description, style: const TextStyle(height: 1.5)),
                  const Divider(height: 48),
                  Text(context.translate('location'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  if (property.location.coordinates[0] == 0.0 && property.location.coordinates[1] == 0.0)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off, size: 48, color: Colors.grey),
                          const SizedBox(height: 8),
                          Text(context.translate('location_not_available') ?? 'Location not available'),
                        ],
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => _openInMaps(property.location.coordinates[1], property.location.coordinates[0]),
                      child: SizedBox(
                        height: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              GoogleMap(
                                initialCameraPosition: CameraPosition(
                                  target: LatLng(property.location.coordinates[1], property.location.coordinates[0]),
                                  zoom: 14,
                                ),
                                markers: property.showExactLocation
                                    ? {
                                        Marker(
                                          markerId: const MarkerId('property'),
                                          position: LatLng(property.location.coordinates[1], property.location.coordinates[0]),
                                        )
                                      }
                                    : {},
                                circles: !property.showExactLocation
                                    ? {
                                        Circle(
                                          circleId: const CircleId('area'),
                                          center: LatLng(property.location.coordinates[1], property.location.coordinates[0]),
                                          radius: 500,
                                          fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
                                          strokeWidth: 2,
                                          strokeColor: Theme.of(context).colorScheme.secondary,
                                        )
                                      }
                                    : {},
                                scrollGesturesEnabled: false,
                                zoomGesturesEnabled: false,
                                rotateGesturesEnabled: false,
                                tiltGesturesEnabled: false,
                                myLocationButtonEnabled: false,
                              ),
                              // Overlay to ensure tap is captured even if map absorbs it
                              Container(color: Colors.transparent),
                              Positioned(
                                bottom: 8,
                                right: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.open_in_new, color: Colors.white, size: 12),
                                      const SizedBox(width: 4),
                                      Text(
                                        context.translate('open_in_maps') ?? 'Open in Maps',
                                        style: const TextStyle(color: Colors.white, fontSize: 10),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  _OwnerCard(owner: property.owner, propertyId: property.id ?? ''),
                  const SizedBox(height: 100), // Space for bottom button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5))],
        ),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _launchWhatsApp(property.owner?.phone),
                icon: const Icon(Icons.chat),
                label: Text(context.translate('whatsapp')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366), // Standard WhatsApp Green
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => launchUrl(Uri.parse('tel:${property.owner?.phone}')),
                icon: const Icon(Icons.phone),
                label: Text(context.translate('call')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _launchWhatsApp(String? phone) async {
    if (phone == null) return;
    final url = 'https://wa.me/$phone';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _openInMaps(double lat, double lng) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$lat,$lng';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

  void _showFullScreenImages(BuildContext context, List<String> images, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _FullScreenGallery(images: images, initialIndex: initialIndex),
      ),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const _FullScreenGallery({required this.images, required this.initialIndex});

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text('${_currentIndex + 1} / ${widget.images.length}', style: const TextStyle(color: Colors.white)),
      ),
      body: PageView.builder(
        controller: _controller,
        itemCount: widget.images.length,
        onPageChanged: (index) => setState(() => _currentIndex = index),
        itemBuilder: (context, index) {
          return InteractiveViewer(
            minScale: 0.5,
            maxScale: 4.0,
            child: Center(
              child: Hero(
                tag: 'property_image_$index',
                child: Image.network(
                  widget.images[index],
                  fit: BoxFit.contain,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _FeatureItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _OwnerCard extends ConsumerWidget {
  final User? owner;
  final String propertyId;

  const _OwnerCard({this.owner, required this.propertyId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: Text(owner?.name?[0] ?? 'O', style: TextStyle(color: Theme.of(context).colorScheme.onSecondary)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(owner?.name ?? context.translate('property_owner'),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (owner?.id != null) ...[
                  const SizedBox(height: 4),
                  Consumer(
                    builder: (context, ref, _) {
                      final ratingAsync = ref.watch(userRatingProvider(owner!.id));
                      return ratingAsync.when(
                        data: (rating) => Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text('${(rating['average'] as num).toStringAsFixed(1)} (${rating['count']})',
                                style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                      );
                    },
                  ),
                ],
                if (owner?.isVerified == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(context.translate('verified_owner'),
                        style: const TextStyle(color: Colors.green, fontSize: 12)),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              TextButton(
                onPressed: owner == null
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => OwnerProfileScreen(owner: owner!)),
                        );
                      },
                child: Text(context.translate('view_profile')),
              ),
              TextButton.icon(
                icon: const Icon(Icons.star_border, size: 18),
                label: Text(context.translate('add_review') ?? 'Add Review'),
                onPressed: owner?.id == null
                    ? null
                    : () {
                        final authState = ref.read(authProvider);
                        if (!authState.isAuthenticated) {
                          AuthGuardDialog.show(context);
                          return;
                        }
                        showDialog(
                          context: context,
                          builder: (_) => AddReviewDialog(propertyId: propertyId, ownerId: owner!.id),
                        );
                      },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
