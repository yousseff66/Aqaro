import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/reports/presentation/providers/report_provider.dart';

class ReportPropertyDialog extends ConsumerStatefulWidget {
  final String propertyId;

  const ReportPropertyDialog({super.key, required this.propertyId});

  @override
  ConsumerState<ReportPropertyDialog> createState() => _ReportPropertyDialogState();
}

class _ReportPropertyDialogState extends ConsumerState<ReportPropertyDialog> {
  final _formKey = GlobalKey<FormState>();
  String _selectedReason = 'Scam';
  final _descriptionController = TextEditingController();

  final List<String> _reasons = [
    'Scam',
    'FakePhotos',
    'Broker',
    'Spam',
    'AlreadyRented',
    'Other',
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      await ref.read(reportProvider.notifier).submitReport(
            propertyId: widget.propertyId,
            reason: _selectedReason,
            description: _descriptionController.text.trim(),
          );
      if (mounted) {
        final state = ref.read(reportProvider);
        if (!state.hasError) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.translate('report_submitted_successfully'))),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reportProvider);

    return AlertDialog(
      title: Text(context.translate('report_property')),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: _selectedReason,
                decoration: InputDecoration(
                  labelText: context.translate('reason'),
                ),
                items: _reasons.map((reason) {
                  return DropdownMenuItem(
                    value: reason,
                    child: Text(context.translate('report_reason_$reason')),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedReason = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: context.translate('description'),
                  hintText: context.translate('report_description_hint'),
                ),
                maxLines: 3,
                textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: state.isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(context.translate('cancel')),
        ),
        ElevatedButton(
          onPressed: state.isLoading ? null : _submit,
          child: state.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(context.translate('submit')),
        ),
      ],
    );
  }
}
