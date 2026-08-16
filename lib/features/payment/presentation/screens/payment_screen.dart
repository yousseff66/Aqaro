import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/payment/presentation/providers/payment_provider.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/admin/data/models/settings_model.dart';

import 'package:sakan_app/core/utils/formatters.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final Property property;
  final bool isFeatured;

  const PaymentScreen({
    super.key,
    required this.property,
    required this.isFeatured,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  String? _selectedMethod;
  File? _receiptImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickReceiptImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(paymentMethodsProvider);
    final paymentState = ref.watch(paymentProcessProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.translate('complete_payment') ?? 'Complete Payment')),
      body: settingsAsync.when(
        data: (settings) {
          double amount = settings.normalListingPrice;
          if (widget.isFeatured) {
            switch (widget.property.featuredDuration) {
              case 'week':
                amount = settings.featuredPriceWeek;
                break;
              case 'twoWeeks':
                amount = settings.featuredPriceTwoWeeks;
                break;
              case 'month':
                amount = settings.featuredPriceMonth;
                break;
              default:
                amount = settings.featuredPriceWeek; // Fallback
            }
          }

          final enabledMethods = settings.paymentMethods.entries
              .where((e) => e.value.enabled)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSummary(amount, context),
                const SizedBox(height: 24),
                Text(context.translate('select_payment_method') ?? 'Select Payment Method', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...enabledMethods.map((method) => _buildMethodTile(method.key, method.value)),
                const SizedBox(height: 24),
                Text(context.translate('attach_receipt') ?? 'Attach Payment Receipt', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildImagePicker(),
                const SizedBox(height: 32),
                if (paymentState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _selectedMethod == null ? null : () => _handlePayment(amount),
                      child: Text('${context.translate('pay')} ${AppFormatters.formatCurrency(amount)} ${context.translate('egp')}'),
                    ),
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading payment methods: $e')),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Column(
      children: [
        if (_receiptImage != null)
          Stack(
            children: [
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.file(_receiptImage!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: CircleAvatar(
                  backgroundColor: Colors.red,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.white),
                    onPressed: () => setState(() => _receiptImage = null),
                  ),
                ),
              ),
            ],
          )
        else
          InkWell(
            onTap: _pickReceiptImage,
            child: Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, style: BorderStyle.solid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
                  const SizedBox(height: 8),
                  Text(context.translate('add_receipt_image') ?? 'Add Receipt Image'),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSummary(double amount, BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('property')),
                Text(widget.property.title, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('listing_type')),
                Text(widget.isFeatured ? context.translate('featured_listing') : context.translate('standard_listing')),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.translate('total_amount'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('${AppFormatters.formatCurrency(amount)} ${context.translate('egp')}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(String key, PaymentMethodConfig config) {
    IconData icon;
    String displayName;
    String submissionKey;

    switch (key.toLowerCase()) {
      case 'vodafonecash':
      case 'vodafone':
        icon = Icons.phone_android;
        displayName = context.translate('vodafone_cash') ?? 'Vodafone Cash';
        submissionKey = 'VodafoneCash';
        break;
      case 'instapay':
      case 'bank':
        icon = Icons.account_balance;
        displayName = context.translate('instapay') ?? 'InstaPay';
        submissionKey = 'InstaPay';
        break;
      case 'visa':
      case 'card':
        icon = Icons.credit_card;
        displayName = context.translate('visa') ?? 'Visa / Bank Transfer';
        submissionKey = 'Visa';
        break;
      default:
        icon = Icons.payments;
        displayName = config.name ?? key.toUpperCase();
        submissionKey = key;
    }

    return RadioListTile<String>(
      value: submissionKey,
      groupValue: _selectedMethod,
      onChanged: (val) => setState(() => _selectedMethod = val),
      title: Text(displayName),
      secondary: Icon(icon),
      subtitle: config.number != null ? Text(config.number!) : null,
    );
  }

  void _handlePayment(double amount) async {
    if (_receiptImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('please_add_receipt') ?? 'Please attach payment proof image')),
      );
      return;
    }

    final formData = FormData.fromMap({
      'propertyId': widget.property.id,
      'paymentMethod': _selectedMethod,
      'receipt': await MultipartFile.fromFile(
        _receiptImage!.path,
        filename: _receiptImage!.path.split('/').last,
      ),
    });

    await ref.read(paymentProcessProvider.notifier).processPayment(formData);
    
    final state = ref.read(paymentProcessProvider);
    if (state.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${context.translate('payment_failed')}: ${state.error}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.translate('payment_submitted'))));
      Navigator.pop(context);
    }
  }
}
