import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/reviews/presentation/providers/review_provider.dart';

class AddReviewDialog extends ConsumerStatefulWidget {
  final String propertyId;
  final String ownerId;

  const AddReviewDialog({
    super.key,
    required this.propertyId,
    required this.ownerId,
  });

  @override
  ConsumerState<AddReviewDialog> createState() => _AddReviewDialogState();
}

class _AddReviewDialogState extends ConsumerState<AddReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  String _getErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }
      if (data is String) return data;
    }
    return context.translate('error_occurred') ?? 'حدث خطأ، حاول مرة أخرى';
  }

  Future<void> _submit() async {
    if (_rating == 0) return;

    await ref.read(reviewSubmitProvider.notifier).submit(
          propertyId: widget.propertyId,
          rating: _rating,
          comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
          ownerId: widget.ownerId,
        );

    if (mounted) {
      final state = ref.read(reviewSubmitProvider);
      if (state is AsyncData) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('review_submitted_success') ?? 'Review submitted successfully')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final submitState = ref.watch(reviewSubmitProvider);
    final isLoading = submitState is AsyncLoading;

    return AlertDialog(
      title: Text(context.translate('add_review') ?? 'Add Review'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: isLoading ? null : () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 32,
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              enabled: !isLoading,
              maxLines: 3,
              textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
              decoration: InputDecoration(
                hintText: context.translate('write_comment') ?? 'Write your comment...',
                border: const OutlineInputBorder(),
              ),
            ),
            if (submitState is AsyncError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _getErrorMessage(submitState.error),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(context.translate('cancel') ?? 'Cancel'),
        ),
        ElevatedButton(
          onPressed: isLoading || _rating == 0 ? null : _submit,
          child: isLoading
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.translate('submit') ?? 'Submit'),
        ),
      ],
    );
  }
}
