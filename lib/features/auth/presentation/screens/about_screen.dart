import 'package:flutter/material.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('about_sakan') ?? 'About Aqaro'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  Image.asset(
                    'assets/branding/icon/icon_mark_light.png',
                    height: 100,
                    errorBuilder: (context, error, stackTrace) => const Icon(Icons.apartment, size: 100, color: Color(0xFFC6FF3D)),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aqaro',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC6FF3D),
                    ),
                  ),
                  const Text('Version 1.0.0'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            _buildSection(
              context,
              title: context.translate('about_sakan') ?? 'About Aqaro',
              content: context.translate('about_desc') ?? '',
            ),
            
            _buildSection(
              context,
              title: context.translate('our_mission') ?? 'Our Mission',
              content: context.translate('our_mission_desc') ?? '',
            ),
            
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.money_off,
              title: context.translate('free_listings_title') ?? '100% Free Ads',
              description: context.translate('free_listings_desc') ?? '',
            ),
            
            const SizedBox(height: 16),
            _buildFeatureCard(
              context,
              icon: Icons.rocket_launch,
              title: context.translate('featured_ads_title') ?? 'Sell & Rent Faster',
              description: context.translate('featured_ads_desc') ?? '',
              isPrimary: true,
            ),
            
            const SizedBox(height: 32),
            Center(
              child: Column(
                children: [
                  Text(
                    context.translate('contact_us') ?? 'Contact Us',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('support@aqaro.app'),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(BuildContext context, {required String title, required String content}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: const Color(0xFFC6FF3D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final color = isPrimary ? const Color(0xFFC6FF3D) : theme.cardColor;
    final textColor = isPrimary ? Colors.black : theme.textTheme.bodyLarge?.color;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPrimary ? null : Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isPrimary ? Colors.black : const Color(0xFFC6FF3D), size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textColor?.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
