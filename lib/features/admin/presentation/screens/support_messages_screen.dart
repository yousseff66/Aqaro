import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/api/dio_client.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';

final supportMessagesProvider = FutureProvider.autoDispose<List<dynamic>>((ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.get('/support/admin');
  return response.data as List<dynamic>;
});

class SupportMessagesScreen extends ConsumerWidget {
  const SupportMessagesScreen({super.key});

  Future<void> _resolveMessage(BuildContext context, WidgetRef ref, String id) async {
    try {
      final dio = ref.read(dioProvider);
      await dio.patch('/support/admin/$id/resolve');
      ref.invalidate(supportMessagesProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('resolved_success') ?? 'Message marked as resolved')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${context.translate('error')}: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final messagesAsync = ref.watch(supportMessagesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.translate('support_messages') ?? 'Support Messages'),
      ),
      body: messagesAsync.when(
        data: (messages) {
          if (messages.isEmpty) {
            return Center(child: Text(context.translate('no_messages_yet') ?? 'No support messages currently'));
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(supportMessagesProvider),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isResolved = msg['status'] == 'resolved';
                final user = msg['user'] ?? {};

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ExpansionTile(
                    title: Text(
                      msg['subject'] ?? context.translate('no_subject'),
                      style: TextStyle(
                        fontWeight: isResolved ? FontWeight.normal : FontWeight.bold,
                        color: isResolved ? Colors.grey : Colors.black,
                      ),
                    ),
                    subtitle: Text(
                      user['name'] ?? user['email'] ?? context.translate('guest_user'),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                    trailing: isResolved
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : const Icon(Icons.info, color: Colors.orange),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              msg['message'] ?? '',
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Text('${context.translate('phone')}: ${user['phone'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            Text('${context.translate('email_label')}: ${user['email'] ?? 'N/A'}', style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                            const SizedBox(height: 16),
                            if (!isResolved)
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.done),
                                  label: Text(context.translate('mark_as_resolved') ?? 'Mark as Resolved'),
                                  onPressed: () => _resolveMessage(context, ref, msg['_id']),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                context.translate('error_loading_messages') ?? 'خطأ في تحميل الرسائل',
                textAlign: TextAlign.center,
              ),
            ),
          );
        },
      ),
    );
  }
}
