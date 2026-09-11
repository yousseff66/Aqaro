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

                // --- الخطوة 1: اختر طريقة الدفع ---
                _buildStepHeader('1', context.translate('select_payment_method') ?? 'اختر طريقة الدفع'),
                const SizedBox(height: 12),
                ...enabledMethods.map((method) => _buildMethodTile(method.key, method.value)),

                // --- الخطوة 2: حوّل المبلغ ---
                if (_selectedMethod != null) ...[
                  const SizedBox(height: 24),
                  _buildStepHeader('2', context.translate('transfer_amount') ?? 'حوّل المبلغ'),
                  const SizedBox(height: 12),
                  _buildTransferInstructions(amount, settings, context),
                ],

                // --- الخطوة 3: ارفع صورة الإيصال ---
                const SizedBox(height: 24),
                _buildStepHeader('3', context.translate('attach_receipt') ?? 'ارفع صورة الإيصال'),
                const SizedBox(height: 8),
                Text(
                  context.translate('attach_receipt_hint') ?? 'بعد ما تحول، صوّر الإيصال وارفعه هنا للتحقق من الدفع',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 12),
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

  Widget _buildStepHeader(String number, String title) {
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: Theme.of(context).primaryColor,
          child: Text(number, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
        ),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildTransferInstructions(double amount, dynamic settings, BuildContext context) {
    // احضر رقم الحساب حسب طريقة الدفع
    String? accountNumber;
    String? accountName;
    if (_selectedMethod != null) {
      final methodKey = _selectedMethod!.toLowerCase();
      if (methodKey == 'vodafonecash' || methodKey == 'vodafone') {
        accountNumber = settings?.paymentMethods['vodafoneCash']?.number ?? settings?.paymentMethods.entries
            .firstWhere((e) => e.key.toLowerCase().contains('vodafone'), orElse: () => MapEntry('', null))
            .value
            ?.number;
      } else if (methodKey == 'instapay') {
        accountNumber = settings?.paymentMethods['instaPay']?.number;
        accountName = settings?.paymentMethods['instaPay']?.name;
      } else if (methodKey == 'visa') {
        accountNumber = settings?.paymentMethods['visa']?.cardNumber;
        accountName = settings?.paymentMethods['visa']?.holder;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // رقم الحساب
          if (accountNumber != null && accountNumber.isNotEmpty) ...[
            Text(
              context.translate('transfer_to') ?? 'حوّل على:',
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800),
            ),
            const SizedBox(height: 8),
            if (accountName != null && accountName.isNotEmpty)
              Text(accountName, style: TextStyle(fontSize: 13, color: Colors.blue.shade700)),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade300),
                    ),
                    child: Text(
                      accountNumber,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy),
                  tooltip: context.translate('copy') ?? 'نسخ',
                  onPressed: () {
                    // نسخ الرقم للكليبورد
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(context.translate('copied') ?? 'تم النسخ ✓'), duration: const Duration(seconds: 2)),
                    );
                  },
                ),
              ],
            ),
            const Divider(height: 20),
          ],
          // المبلغ
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.translate('amount_to_transfer') ?? 'المبلغ المطلوب تحويله:',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '${AppFormatters.formatCurrency(amount)} ${context.translate('egp') ?? 'ج.م'}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
              ),
            ],
          ),
          const Divider(height: 20),
          // خطوات
          Text(
            context.translate('transfer_steps') ?? 'خطوات التحويل:',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildStep('1️⃣', context.translate('step_open_app') ?? 'افتح تطبيق البنك أو المحفظة'),
          _buildStep('2️⃣', context.translate('step_transfer') ?? 'حوّل المبلغ على الرقم المذكور'),
          _buildStep('3️⃣', context.translate('step_screenshot') ?? 'صوّر شاشة نجاح التحويل'),
          _buildStep('4️⃣', context.translate('step_upload') ?? 'ارفع صورة الإيصال في الخانة أسفل'),
        ],
      ),
    );
  }

  Widget _buildStep(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
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
          GestureDetector(
            onTap: _pickReceiptImage,
            child: Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor, style: BorderStyle.solid, width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo_outlined, size: 48, color: Theme.of(context).primaryColor),
                  const SizedBox(height: 12),
                  Text(
                    context.translate('add_receipt_image') ?? 'اضغط لإضافة صورة الإيصال',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.translate('add_receipt_hint') ?? 'صورة من الجاليري أو الكاميرا',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
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
