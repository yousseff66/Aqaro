import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sakan_app/features/payment/data/models/payment_model.dart';

class PaymentsReviewScreen extends ConsumerStatefulWidget {
  const PaymentsReviewScreen({super.key});

  @override
  ConsumerState<PaymentsReviewScreen> createState() => _PaymentsReviewScreenState();
}

class _PaymentsReviewScreenState extends ConsumerState<PaymentsReviewScreen> {
  String _selectedStatus = 'Pending';

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(adminActionProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });

    final paymentsAsync = ref.watch(allPaymentsProvider);
    final actionState = ref.watch(adminActionProvider);

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(allPaymentsProvider),
              child: paymentsAsync.when(
                data: (payments) {
                  final filteredPayments = _selectedStatus == 'All'
                      ? payments
                      : payments.where((p) => p.status == _selectedStatus).toList();

                  if (filteredPayments.isEmpty) {
                    return ListView(
                      children: [
                        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                        Center(
                          child: Column(
                            children: [
                              Icon(Icons.payments_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                _getNoPaymentsMessage(context),
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: filteredPayments.length,
                    itemBuilder: (context, index) {
                      return _PaymentCard(
                        payment: filteredPayments[index],
                        isLoading: actionState.isLoading,
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ),
        ],
      );
  }

  Widget _buildFilterBar() {
    final statuses = ['All', 'Pending', 'Approved', 'Rejected'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: statuses.map((status) {
          final isSelected = _selectedStatus == status;
          final label = status == 'All'
              ? (context.translate('all') ?? 'All')
              : (context.translate(status.toLowerCase()) ?? status);
          return Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: ChoiceChip(
              label: Text(label),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _selectedStatus = status);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getNoPaymentsMessage(BuildContext context) {
    switch (_selectedStatus) {
      case 'Pending':
        return context.translate('no_pending_payments') ?? 'No pending payments';
      case 'Approved':
        return context.translate('no_approved_payments') ?? 'No approved payments';
      case 'Rejected':
        return context.translate('no_rejected_payments') ?? 'No rejected payments';
      default:
        return context.translate('no_payments_yet');
    }
  }
}

class _PaymentCard extends ConsumerWidget {
  final Payment payment;
  final bool isLoading;

  const _PaymentCard({required this.payment, required this.isLoading});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(payment.user?.name ?? 'Unknown User', style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(payment.paymentMethod),
            trailing: _StatusBadge(status: payment.status),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(payment.property?.title ?? 'Unknown Property', maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      Text(
                        '${payment.amount} EGP',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                      ),
                    ],
                  ),
                ),
                if (payment.isRenewal)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.amber[100], borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      context.translate('renewal_payment') ?? 'Renewal',
                      style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (payment.receiptImage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: GestureDetector(
                onTap: () => _showFullScreenImage(context, payment.receiptImage!),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    payment.receiptImage!,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      height: 150,
                      color: Colors.grey[200],
                      child: const Icon(Icons.broken_image, color: Colors.grey),
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  payment.createdAt != null ? intl.DateFormat('MMM dd, yyyy HH:mm').format(payment.createdAt!) : '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                if (payment.status == 'Pending')
                  Row(
                    children: [
                      TextButton(
                        onPressed: isLoading ? null : () => _showRejectDialog(context, ref, payment.id!),
                        child: Text(context.translate('reject') ?? 'Reject', style: const TextStyle(color: Colors.red)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: isLoading ? null : () => _showApproveDialog(context, ref, payment.id!),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                        child: Text(context.translate('approve') ?? 'Approve'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(child: Image.network(url)),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showApproveDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('approve_payment') ?? 'Approve Payment'),
        content: Text(context.translate('approve_payment_confirmation') ?? 'Are you sure you want to approve this payment?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              await ref.read(adminActionProvider.notifier).approvePayment(id);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('payment_approved') ?? 'Payment Approved')));
              }
            },
            child: Text(context.translate('approve') ?? 'Approve', style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context, WidgetRef ref, String id) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.translate('reject_payment') ?? 'Reject Payment'),
        content: TextField(
          controller: controller,
          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
          decoration: InputDecoration(hintText: context.translate('rejection_reason_optional') ?? 'Rejection reason (optional)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(context.translate('cancel'))),
          TextButton(
            onPressed: () async {
              await ref.read(adminActionProvider.notifier).rejectPayment(
                    id,
                    reviewNote: controller.text.trim().isEmpty ? null : controller.text.trim(),
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('payment_rejected') ?? 'Payment Rejected')));
              }
            },
            child: Text(context.translate('reject') ?? 'Reject', style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'Pending':
        color = Colors.orange;
        break;
      case 'Approved':
        color = Colors.green;
        break;
      case 'Rejected':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color)),
      child: Text(
        context.translate(status.toLowerCase()) ?? status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
