import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/presentation/providers/admin_provider.dart';

class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final range = ref.watch(dashboardDateRangeProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminStatsProvider.future),
      child: statsAsync.when(
          data: (stats) => SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.translate('overview') ?? 'Overview',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(range.start != null
                            ? intl.DateFormat('dd/MM/yyyy').format(range.start!)
                            : (context.translate('start_date') ?? 'Start Date')),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: range.start ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            ref.read(dashboardDateRangeProvider.notifier).state =
                                DashboardDateRange(start: picked, end: range.end);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(range.end != null
                            ? intl.DateFormat('dd/MM/yyyy').format(range.end!)
                            : (context.translate('end_date') ?? 'End Date')),
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: range.end ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            ref.read(dashboardDateRangeProvider.notifier).state =
                                DashboardDateRange(start: range.start, end: picked);
                          }
                        },
                      ),
                    ),
                    if (range.start != null || range.end != null)
                      IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () => ref.read(dashboardDateRangeProvider.notifier).state =
                            const DashboardDateRange(),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.5,
                  children: [
                    _StatCard(
                      title: context.translate('total_users') ?? 'Total Users',
                      value: stats.totalUsers.toString(),
                      icon: Icons.people,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                    _StatCard(
                      title: context.translate('properties') ?? 'Properties',
                      value: stats.totalProperties.toString(),
                      icon: Icons.home,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatCard(
                      title: context.translate('pending') ?? 'Pending Properties',
                      value: stats.pendingProperties.toString(),
                      icon: Icons.pending_actions,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: context.translate('pending_payments') ?? 'Pending Payments',
                      value: stats.pendingPayments.toString(),
                      icon: Icons.payment,
                      color: Colors.orange,
                    ),
                    _StatCard(
                      title: context.translate('revenue') ?? 'Revenue',
                      value: '${stats.totalRevenue.toStringAsFixed(0)} ${context.translate('egp')}',
                      icon: Icons.attach_money,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    _StatCard(
                      title: context.translate('active_reports') ?? 'Active Reports',
                      value: stats.activeReports.toString(),
                      icon: Icons.report,
                      color: Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  context.translate('quick_actions') ?? 'Quick Actions',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.orange,
                    child: Icon(Icons.approval, color: Colors.white),
                  ),
                  title: Text(context.translate('review_pending_listings') ?? 'Review Pending Listings'),
                  subtitle: Text('${stats.pendingProperties} ${context.translate('properties_waiting_approval')}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to Pending Listings
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(Icons.report, color: Colors.white),
                  ),
                  title: Text(context.translate('property_reports') ?? 'Property Reports'),
                  subtitle: Text('${stats.activeReports} ${context.translate('active_reports_description') ?? 'Active reports'}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    // Navigate to Reports
                  },
                ),
              ],
            ),
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
