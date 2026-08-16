import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/favorites/presentation/providers/favorite_provider.dart';
import 'package:sakan_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sakan_app/features/auth/presentation/screens/login_screen.dart';
import 'package:sakan_app/core/theme/app_colors.dart';
import 'package:sakan_app/core/utils/formatters.dart';

import 'package:sakan_app/shared/widgets/auth_guard_dialog.dart';

class PropertyCard extends ConsumerWidget {
  final Property property;
  final VoidCallback? onTap;

  const PropertyCard({super.key, required this.property, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(favoriteIdsProvider).contains(property.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                if (property.images.isNotEmpty)
                  Image.network(
                    property.images.first,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 180,
                      color: AppColors.divider,
                      child: const Icon(Icons.broken_image, size: 50),
                    ),
                  )
                else
                  Container(
                    height: 180,
                    color: AppColors.divider,
                    child: const Icon(Icons.image, size: 50),
                  ),
                if (property.isFeatured)
                  PositionedDirectional(
                    top: 12,
                    start: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.gold,
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.stars, color: AppColors.onGold, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            context.translate('featured').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.onGold,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                PositionedDirectional(
                  top: 12,
                  end: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.carbon900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.translate(property.listingPurpose.toLowerCase()).toUpperCase(),
                      style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 12,
                  start: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.carbon900.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${AppFormatters.formatCurrency(property.price)} ${context.translate('egp')}',
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                PositionedDirectional(
                  bottom: 8,
                  end: 8,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                      ],
                    ),
                    child: IconButton(
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : AppColors.muted,
                        size: 20,
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
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // يخلي العمود ياخد أقل مساحة ممكنة
                children: [
                  Text(
                    property.title,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), // صغرنا الخط سنة
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2), // قللنا المسافة
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: AppColors.muted),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${property.city}, ${property.governorate}',
                          style: const TextStyle(color: AppColors.muted, fontSize: 11),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: _buildAttribute(context, Icons.king_bed_outlined, '${property.bedrooms}')),
                      Expanded(child: _buildAttribute(context, Icons.bathtub_outlined, '${property.bathrooms}')),
                      Expanded(child: _buildAttribute(context, Icons.square_foot_outlined, '${AppFormatters.formatNumber(property.area)}')),
                    ],
                  ),
                  if (property.publishedAt != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.muted),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('dd/MM/yyyy', 'en_US').format(property.publishedAt!),
                          style: const TextStyle(fontSize: 11, color: AppColors.muted),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAttribute(BuildContext context, IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Theme.of(context).colorScheme.secondary),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
