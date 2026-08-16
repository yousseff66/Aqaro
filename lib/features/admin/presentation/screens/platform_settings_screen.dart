import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/admin/data/models/settings_model.dart';
import 'package:sakan_app/features/admin/data/repositories/settings_repository.dart';

final settingsFutureProvider = FutureProvider.autoDispose<PlatformSettings>((ref) async {
  return ref.read(settingsRepositoryProvider).getSettings();
});

class PlatformSettingsScreen extends ConsumerStatefulWidget {
  const PlatformSettingsScreen({super.key});

  @override
  ConsumerState<PlatformSettingsScreen> createState() => _PlatformSettingsScreenState();
}

class _PlatformSettingsScreenState extends ConsumerState<PlatformSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _normalPriceController;
  late TextEditingController _featuredPriceWeekController;
  late TextEditingController _featuredPriceTwoWeeksController;
  late TextEditingController _featuredPriceMonthController;
  late TextEditingController _durationController;
  late TextEditingController _supportPhoneController;
  late TextEditingController _supportEmailController;

  // InstaPay
  late TextEditingController _instaPayNameController;
  late TextEditingController _instaPayNumberController;
  bool _instaPayEnabled = true;

  // Vodafone Cash
  late TextEditingController _vodafoneNumberController;
  bool _vodafoneEnabled = true;

  // Visa
  late TextEditingController _visaHolderController;
  late TextEditingController _visaBankController;
  late TextEditingController _visaCardNumberController;
  bool _visaEnabled = true;

  // Max images
  late TextEditingController _maxImagesController;

  @override
  void initState() {
    super.initState();
    _normalPriceController = TextEditingController();
    _featuredPriceWeekController = TextEditingController();
    _featuredPriceTwoWeeksController = TextEditingController();
    _featuredPriceMonthController = TextEditingController();
    _durationController = TextEditingController();
    _supportPhoneController = TextEditingController();
    _supportEmailController = TextEditingController();

    _instaPayNameController = TextEditingController();
    _instaPayNumberController = TextEditingController();
    _vodafoneNumberController = TextEditingController();
    _visaHolderController = TextEditingController();
    _visaBankController = TextEditingController();
    _visaCardNumberController = TextEditingController();
    _maxImagesController = TextEditingController();
  }

  @override
  void dispose() {
    _normalPriceController.dispose();
    _featuredPriceWeekController.dispose();
    _featuredPriceTwoWeeksController.dispose();
    _featuredPriceMonthController.dispose();
    _durationController.dispose();
    _supportPhoneController.dispose();
    _supportEmailController.dispose();

    _instaPayNameController.dispose();
    _instaPayNumberController.dispose();
    _vodafoneNumberController.dispose();
    _visaHolderController.dispose();
    _visaBankController.dispose();
    _visaCardNumberController.dispose();
    _maxImagesController.dispose();
    super.dispose();
  }

  void _initFields(PlatformSettings settings) {
    _normalPriceController.text = settings.normalListingPrice.toString();
    _featuredPriceWeekController.text = settings.featuredPriceWeek.toString();
    _featuredPriceTwoWeeksController.text = settings.featuredPriceTwoWeeks.toString();
    _featuredPriceMonthController.text = settings.featuredPriceMonth.toString();
    _durationController.text = settings.listingDurationDays.toString();
    _supportPhoneController.text = settings.supportPhone;
    _supportEmailController.text = settings.supportEmail;
    _maxImagesController.text = settings.maxImagesPerProperty.toString();

    final instaPay = settings.paymentMethods['instaPay'];
    _instaPayEnabled = instaPay?.enabled ?? true;
    _instaPayNameController.text = instaPay?.name ?? '';
    _instaPayNumberController.text = instaPay?.number ?? '';

    final vodafone = settings.paymentMethods['vodafoneCash'];
    _vodafoneEnabled = vodafone?.enabled ?? true;
    _vodafoneNumberController.text = vodafone?.number ?? '';

    final visa = settings.paymentMethods['visa'];
    _visaEnabled = visa?.enabled ?? false;
    _visaHolderController.text = visa?.holder ?? '';
    _visaBankController.text = visa?.bank ?? '';
    _visaCardNumberController.text = visa?.cardNumber ?? '';
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final data = {
        'normalListingPrice': double.parse(_normalPriceController.text),
        'featuredPriceWeek': double.parse(_featuredPriceWeekController.text),
        'featuredPriceTwoWeeks': double.parse(_featuredPriceTwoWeeksController.text),
        'featuredPriceMonth': double.parse(_featuredPriceMonthController.text),
        'listingDurationDays': int.parse(_durationController.text),
        'supportPhone': _supportPhoneController.text,
        'supportEmail': _supportEmailController.text,
        'maxImagesPerProperty': int.parse(_maxImagesController.text),
        'paymentMethods': {
          'instaPay': {
            'enabled': _instaPayEnabled,
            'name': _instaPayNameController.text,
            'number': _instaPayNumberController.text,
          },
          'vodafoneCash': {
            'enabled': _vodafoneEnabled,
            'number': _vodafoneNumberController.text,
          },
          'visa': {
            'enabled': _visaEnabled,
            'holder': _visaHolderController.text,
            'bank': _visaBankController.text,
            'cardNumber': _visaCardNumberController.text,
          },
        },
      };

      await ref.read(settingsRepositoryProvider).updateSettings(data);
      ref.invalidate(settingsFutureProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('settings_updated') ?? 'Settings updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsFutureProvider);

    return settingsAsync.when(
      data: (settings) {
          if (_normalPriceController.text.isEmpty && !_isLoading) {
            _initFields(settings);
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(context.translate('pricing') ?? 'Pricing'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _normalPriceController,
                  label: context.translate('normal_listing_price') ?? 'Normal Listing Price (EGP)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _featuredPriceWeekController,
                  label: '${context.translate('featured_listing_price')} (${context.translate('duration_week')})',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _featuredPriceTwoWeeksController,
                  label: '${context.translate('featured_listing_price')} (${context.translate('duration_two_weeks')})',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _featuredPriceMonthController,
                  label: '${context.translate('featured_listing_price')} (${context.translate('duration_month')})',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context.translate('listing_policy') ?? 'Listing Policy'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _durationController,
                  label: context.translate('listing_duration_days') ?? 'Duration (Days)',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _maxImagesController,
                  label: context.translate('max_images') ?? 'Max Images Per Property',
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context.translate('support_info') ?? 'Support Info'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _supportPhoneController,
                  label: context.translate('support_phone') ?? 'Support Phone',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _supportEmailController,
                  label: context.translate('support_email') ?? 'Support Email',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 24),
                _buildSectionTitle(context.translate('payment_methods') ?? 'Payment Methods'),
                const SizedBox(height: 16),
                
                // InstaPay Card
                _buildPaymentMethodCard(
                  title: context.translate('instapay') ?? 'InstaPay',
                  enabled: _instaPayEnabled,
                  onChanged: (v) => setState(() => _instaPayEnabled = v),
                  children: [
                    _buildTextField(
                      controller: _instaPayNameController,
                      label: context.translate('account_name') ?? 'Account Name',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _instaPayNumberController,
                      label: context.translate('instapay_number') ?? 'InstaPay Number/Handle',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Vodafone Cash Card
                _buildPaymentMethodCard(
                  title: context.translate('vodafone_cash') ?? 'Vodafone Cash',
                  enabled: _vodafoneEnabled,
                  onChanged: (v) => setState(() => _vodafoneEnabled = v),
                  children: [
                    _buildTextField(
                      controller: _vodafoneNumberController,
                      label: context.translate('vodafone_number') ?? 'Vodafone Number',
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Visa Card
                _buildPaymentMethodCard(
                  title: context.translate('visa') ?? 'Visa / Bank Transfer',
                  enabled: _visaEnabled,
                  onChanged: (v) => setState(() => _visaEnabled = v),
                  children: [
                    _buildTextField(
                      controller: _visaHolderController,
                      label: context.translate('account_holder') ?? 'Account Holder',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _visaBankController,
                      label: context.translate('bank_name') ?? 'Bank Name',
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _visaCardNumberController,
                      label: context.translate('card_number') ?? 'Card/Account Number',
                    ),
                  ],
                ),

                ElevatedButton(
                  onPressed: _isLoading ? null : _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          context.translate('save') ?? 'Save Settings',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary, 
                            fontSize: 16, 
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18, 
        fontWeight: FontWeight.bold, 
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      keyboardType: keyboardType,
      validator: (v) {
        if (v == null || v.isEmpty) {
          return context.translate('required') ?? 'Required';
        }
        return null;
      },
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required List<Widget> children,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Switch(
                  value: enabled,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            if (enabled) ...[
              const Divider(),
              const SizedBox(height: 8),
              ...children,
            ],
          ],
        ),
      ),
    );
  }
}
