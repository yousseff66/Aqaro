import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sakan_app/features/payment/presentation/providers/payment_provider.dart';

import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

class PaymentHistoryScreen extends ConsumerWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(myPaymentsProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(title: context.translate('payments')),
      body: Builder(
        builder: (context) {
          try {
            return RefreshIndicator(
              onRefresh: () => ref.refresh(myPaymentsProvider.future),
              child: paymentsAsync.when(
                data: (payments) {
                  try {
                    if (payments.isEmpty) {
                      return Center(child: Text(context.translate('no_payments_yet') ?? 'No payment history found.'));
                    }
                    return ListView.separated(
                      itemCount: payments.length,
                      separatorBuilder: (context, index) => const Divider(),
                      itemBuilder: (context, index) {
                        try {
                          final payment = payments[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getStatusColor(payment.status).withOpacity(0.1),
                              child: Icon(_getStatusIcon(payment.status), color: _getStatusColor(payment.status)),
                            ),
                            title: Text('${payment.amount} ${context.translate('egp')}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(payment.property?.title ?? context.translate('property')),
                                Text(
                                  payment.property?.listingType == 'Featured'
                                      ? (context.translate('featured_listing') ?? 'Featured')
                                      : (context.translate('standard_listing') ?? 'Normal'),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                if (payment.isRenewal)
                                  Text(context.translate('renewal_payment') ?? 'Renewal',
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                if (payment.createdAt != null)
                                  Text(intl.DateFormat('MMM dd, yyyy - hh:mm a', 'en_US').format(payment.createdAt!)),
                              ],
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(payment.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                payment.status,
                                style: TextStyle(
                                  color: _getStatusColor(payment.status),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        } catch (e, stack) {
                          debugPrint('=== ERROR IN itemBuilder at index $index ===');
                          debugPrint('Error: $e');
                          debugPrint('Stack: $stack');
                          return ListTile(title: Text('Error rendering item $index: $e'));
                        }
                      },
                    );
                  } catch (e, stack) {
                    debugPrint('=== ERROR IN data builder ===');
                    debugPrint('Error: $e');
                    debugPrint('Stack: $stack');
                    return Center(child: Text('Error: $e'));
                  }
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            );
          } catch (e, stack) {
            debugPrint('=== ERROR IN outer build ===');
            debugPrint('Error: $e');
            debugPrint('Stack: $stack');
            return Center(child: Text('Outer Error: $e'));
          }
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
      case 'verified':
        return Icons.check_circle;
      case 'pending':
        return Icons.history;
      case 'failed':
      case 'rejected':
        return Icons.error;
      default:
        return Icons.payment;
    }
  }
}
