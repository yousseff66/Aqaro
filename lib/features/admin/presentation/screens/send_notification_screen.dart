import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/data/repositories/admin_repository.dart';

class SendNotificationScreen extends ConsumerStatefulWidget {
  const SendNotificationScreen({super.key});

  @override
  ConsumerState<SendNotificationScreen> createState() => _SendNotificationScreenState();
}

class _SendNotificationScreenState extends ConsumerState<SendNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _category = 'all';
  bool _isLoading = false;

  final Map<String, String> _categoryLabels = {
    'all': 'كل المستخدمين',
    'property_owners': 'أصحاب العقارات',
    'new_users': 'المستخدمين الجدد (آخر 7 أيام)',
    'pending_payment': 'أصحاب عقارات في انتظار الدفع',
  };

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الإرسال'),
        content: Text('هل أنت متأكد من إرسال هذا الإشعار لـ "${_categoryLabels[_category]}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إرسال', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      final result = await ref.read(adminRepositoryProvider).sendPushNotification(
            title: _titleController.text.trim(),
            body: _bodyController.text.trim(),
            category: _category,
          );

      if (mounted) {
        final successCount = result['successCount'] ?? 0;
        final failureCount = result['failureCount'] ?? 0;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم الإرسال بنجاح لـ $successCount جهاز، فشل الإرسال لـ $failureCount أجهزة'),
            backgroundColor: Colors.green,
          ),
        );
        
        _titleController.clear();
        _bodyController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في الإرسال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                value: _category,
                decoration: const InputDecoration(
                  labelText: 'الفئة المستهدفة',
                  border: OutlineInputBorder(),
                ),
                items: _categoryLabels.entries.map((e) {
                  return DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'عنوان الإشعار',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'العنوان مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _bodyController,
                decoration: const InputDecoration(
                  labelText: 'محتوى الإشعار',
                  border: OutlineInputBorder(),
                ),
                maxLines: 4,
                validator: (value) =>
                    (value == null || value.isEmpty) ? 'المحتوى مطلوب' : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: (_isLoading ||
                        _titleController.text.isEmpty ||
                        _bodyController.text.isEmpty)
                    ? null
                    : _sendNotification,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator()
                    : const Text('إرسال الإشعار', style: TextStyle(fontSize: 16)),
              ),
            ],
        ),
      ),
    );
  }
}
