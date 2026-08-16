import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/reports/data/models/report_model.dart';
import 'package:sakan_app/features/reports/data/repositories/report_repository.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';

final allReportsProvider = FutureProvider.autoDispose<List<PropertyReport>>((ref) async {
  return ref.read(reportRepositoryProvider).getAllReports();
});

class ReportsManagementScreen extends ConsumerWidget {
  const ReportsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(allReportsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.refresh(allReportsProvider.future),
      child: reportsAsync.when(
          data: (reports) {
            if (reports.isEmpty) return Center(child: Text(context.translate('no_reports_found')));
            return ListView.separated(
              itemCount: reports.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final report = reports[index];
                return ListTile(
                  title: Text(report.reason),
                  subtitle: Text('${context.translate('title')}: ${report.property?.title ?? 'Unknown'}\n${context.translate('reporter') ?? 'Reporter'}: ${report.reporter?.name ?? 'Unknown'}'),
                  isThreeLine: true,
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(report.status).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      context.translate(report.status.toLowerCase()),
                      style: TextStyle(color: _getStatusColor(report.status), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                  onTap: () => _showReportDetails(context, ref, report),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Reviewed':
        return Colors.green;
      case 'Pending':
        return Colors.orange;
      case 'Rejected':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void _showReportDetails(BuildContext context, WidgetRef ref, PropertyReport report) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.translate('report_details'), style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('${context.translate('reason')}: ${report.reason}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${context.translate('description')}: ${report.description}'),
            const Divider(height: 32),
            if (report.property != null)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.translate('view_reported_property')),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PropertyDetailScreen(
                        propertyId: report.property!.id!,
                        initialProperty: report.property,
                      ),
                    ),
                  );
                },
              ),
            const SizedBox(height: 24),
            if (report.status == 'Pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStatusDialog(context, ref, report.id!, 'Rejected');
                      },
                      child: Text(context.translate('reject') ?? 'Reject'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showStatusDialog(context, ref, report.id!, 'Reviewed');
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                      child: Text(context.translate('mark_as_reviewed') ?? 'Mark as Reviewed'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            if (report.property != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showDeleteConfirmation(context, ref, report.id!);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                  child: Text(context.translate('delete_reported_property') ?? 'Delete Reported Property'),
                ),
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showStatusDialog(BuildContext context, WidgetRef ref, String id, String status) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(status == 'Reviewed' 
            ? (context.translate('mark_as_reviewed') ?? 'Mark as Reviewed') 
            : (context.translate('reject_report') ?? 'Reject Report')),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: context.translate('rejection_reason_optional') ?? 'Review note (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(context, ref, id, status, reviewNote: controller.text.trim().isEmpty ? null : controller.text.trim());
            },
            child: Text(context.translate(status.toLowerCase()) ?? status),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('delete_reported_property') ?? 'Delete Property'),
        content: Text(context.translate('delete_property_confirmation') ?? 'Are you sure? This property will be permanently deleted.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(reportRepositoryProvider).deleteReportedProperty(id);
                ref.invalidate(allReportsProvider);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            },
            child: Text(context.translate('delete'), style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _updateStatus(BuildContext context, WidgetRef ref, String id, String status, {String? reviewNote}) async {
    try {
      await ref.read(reportRepositoryProvider).updateReportStatus(id, status, reviewNote: reviewNote);
      ref.invalidate(allReportsProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }
}
