import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/properties/data/repositories/property_repository.dart';
import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/features/payment/presentation/screens/payment_screen.dart';
import 'package:sakan_app/features/payment/presentation/providers/payment_provider.dart';
import 'package:sakan_app/core/utils/formatters.dart' as app_formatters;

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

class CreateListingScreen extends ConsumerStatefulWidget {
  final Property? existingProperty;
  const CreateListingScreen({super.key, this.existingProperty});

  @override
  ConsumerState<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends ConsumerState<CreateListingScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  bool get _isEditing => widget.existingProperty != null;

  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _areaController = TextEditingController();
  final _addressController = TextEditingController();

  String _governorate = 'Cairo';
  String _city = 'Maadi';
  String _propertyType = 'Apartment';
  String _listingPurpose = 'Rent';
  String _listingType = 'Normal';
  String? _featuredDuration;
  bool _showExactLocation = true;
  int _bedrooms = 1;
  int _bathrooms = 1;
  int? _floor;
  bool _furnished = false;

  LatLng _selectedLocation = const LatLng(30.0444, 31.2357);
  GoogleMapController? _mapController;

  // صور جديدة هيختارها اليوزر
  List<File> _images = [];
  final ImagePicker _picker = ImagePicker();

  // الصور الموجودة مسبقًا (وقت التعديل بس) - urls + publicIds متطابقين بالـ index
  List<String> _existingImageUrls = [];
  List<String> _existingImagePublicIds = [];
  // الـ publicIds اللي المستخدم قرر يحذفها
  final List<String> _removedImagePublicIds = [];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final p = widget.existingProperty!;
      _titleController.text = p.title;
      _descriptionController.text = p.description;
      _priceController.text = p.price.toString();
      _areaController.text = p.area.toString();
      _addressController.text = p.address;
      _governorate = p.governorate;
      _city = p.city;
      _propertyType = p.propertyType;
      _listingPurpose = p.listingPurpose;
      _listingType = p.listingType;
      _featuredDuration = p.featuredDuration;
      _bedrooms = p.bedrooms;
      _bathrooms = p.bathrooms;
      _floor = p.floor;
      _furnished = p.furnished;
      _showExactLocation = p.showExactLocation;
      _existingImageUrls = List.from(p.images);
      _existingImagePublicIds = List.from(p.imagePublicIds);
      if (p.location.coordinates.length >= 2) {
        _selectedLocation = LatLng(p.location.coordinates[1], p.location.coordinates[0]);
      }
    }
  }

  Future<void> _pickImages() async {
    final List<XFile> pickedFiles = await _picker.pickMultiImage(
      imageQuality: 70, // ضغط الصورة لـ 70% من جودتها الأصلية
      maxWidth: 1440,   // أقصى عرض 1440 بكسل (كافي جداً للموبايل)
      maxHeight: 1440,  // أقصى ارتفاع 1440 بكسل
    );
    if (pickedFiles.isNotEmpty) {
      setState(() {
        _images.addAll(pickedFiles.map((file) => File(file.path)));
      });
    }
  }

  // حذف صورة موجودة (بتسجل الـ publicId بتاعها عشان تتحذف من السيرفر وقت الحفظ)
  void _removeExistingImage(int index) {
    setState(() {
      if (index < _existingImagePublicIds.length) {
        _removedImagePublicIds.add(_existingImagePublicIds[index]);
        _existingImagePublicIds.removeAt(index);
      }
      _existingImageUrls.removeAt(index);
    });
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('location_services_disabled') ?? 'Location services are disabled.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(context.translate('location_permission_denied') ?? 'Location permissions are denied')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('location_permission_permanently_denied') ?? 'Location permissions are permanently denied')),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final newLatLng = LatLng(position.latitude, position.longitude);
      _updateLocation(newLatLng);
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLatLng));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _updateLocation(LatLng pos) async {
    setState(() => _selectedLocation = pos);
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        // دالة للتأكد إن النص مش Plus Code (اللي بيبقى فيه علامة +)
        bool isValidText(String? s) {
          if (s == null || s.isEmpty) return false;
          return !s.contains('+') && !RegExp(r'^[A-Z0-9]{4,}\+').hasMatch(s);
        }

        List<String> addressParts = [];
        if (isValidText(place.street)) addressParts.add(place.street!);
        if (isValidText(place.subLocality)) addressParts.add(place.subLocality!);
        if (isValidText(place.locality)) addressParts.add(place.locality!);
        if (isValidText(place.subAdministrativeArea)) addressParts.add(place.subAdministrativeArea!);
        
        // لو ملقيناش أي اسم منطقة، بنحاول نستخدم اسم المكان كملجأ أخير لو مش كود
        if (addressParts.isEmpty && isValidText(place.name)) {
          addressParts.add(place.name!);
        }

        setState(() {
          // دالة تنظيف للفواصل الزائدة والمسافات
          _addressController.text = addressParts
              .where((s) => s.trim().isNotEmpty && s != ',')
              .join(', ')
              .replaceAll(RegExp(r',\s*,'), ',')
              .trim();

          // تحديث المحافظة والمدينة فقط لو القيم صالحة ومش أكواد
          if (isValidText(place.administrativeArea)) {
            _governorate = place.administrativeArea!;
          }
          if (isValidText(place.locality)) {
            _city = place.locality!;
          }
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // التأكد من وجود صورة واحدة على الأقل (سواء موجودة أو جديدة)
    final totalImagesCount = _existingImageUrls.length + _images.length;
    if (totalImagesCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('please_add_images'))),
      );
      return;
    }

    if (_listingType == 'Featured' && _featuredDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('please_select_duration') ?? 'Please select a featured duration')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        await _submitEdit();
      } else {
        await _submitCreate();
      }
    } catch (e) {
      String errorMessage = 'Error: $e';

      if (e is DioException) {
        debugPrint('=== DioException Details ===');
        debugPrint('Status Code: ${e.response?.statusCode}');
        debugPrint('Response Data: ${e.response?.data}');
        debugPrint('Request Data: ${e.requestOptions.data}');
        debugPrint('=============================');

        final responseData = e.response?.data;
        if (responseData is Map && responseData['message'] != null) {
          final message = responseData['message'];
          if (message is List) {
            errorMessage = message.join('\n');
          } else {
            errorMessage = message.toString();
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), duration: const Duration(seconds: 5)),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDurationOption(String value, String label, String hint, {bool isPopular = false}) {
    return Consumer(
      builder: (context, ref, _) {
        final settingsAsync = ref.watch(paymentMethodsProvider);
        return settingsAsync.when(
          data: (settings) {
            final price = {
              'week': settings.featuredPriceWeek,
              'twoWeeks': settings.featuredPriceTwoWeeks,
              'month': settings.featuredPriceMonth,
            }[value];
            return InkWell(
              onTap: () => setState(() => _featuredDuration = value),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _featuredDuration == value ? Theme.of(context).primaryColor.withOpacity(0.15) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _featuredDuration == value ? Theme.of(context).primaryColor : Colors.grey.shade300,
                    width: _featuredDuration == value ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<String>(
                      value: value,
                      groupValue: _featuredDuration,
                      onChanged: (v) => setState(() => _featuredDuration = v),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
                              if (isPopular) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)),
                                  child: const Text('★', style: TextStyle(color: Colors.white, fontSize: 10)),
                                ),
                              ],
                            ],
                          ),
                          Text(hint, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Text('${app_formatters.AppFormatters.formatCurrency(price ?? 0)} ${context.translate('egp')}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            );
          },
          loading: () => const SizedBox(height: 50, child: Center(child: CircularProgressIndicator())),
          error: (_, __) => const SizedBox.shrink(),
        );
      },
    );
  }

  Widget _buildPlanSelector(BuildContext context, dynamic settings) {
    final primaryColor = Theme.of(context).primaryColor;

    // تعريف الخطط
    final plans = [
      {
        'type': 'Normal',
        'duration': null,
        'icon': Icons.list_alt_outlined,
        'title': context.translate('normal') ?? 'عادي',
        'subtitle': context.translate('free_listing_desc') ?? 'مجاني - إعلان عادي في نتائج البحث',
        'price': null,
        'badge': null,
        'benefits': [
          context.translate('featured_benefit_normal_1') ?? '✓ ظهور في نتائج البحث',
          context.translate('featured_benefit_normal_2') ?? '✓ مجاني تماماً',
        ],
      },
      {
        'type': 'Featured',
        'duration': 'week',
        'icon': Icons.star_outline,
        'title': context.translate('duration_week') ?? 'مميز أسبوع',
        'subtitle': context.translate('duration_week_hint') ?? 'مثالي لو مستعجل تأجر بسرعة',
        'price': settings?.featuredPriceWeek,
        'badge': null,
        'benefits': [
          context.translate('featured_benefit_1') ?? '✓ أولوية في ظهور البحث',
          context.translate('featured_benefit_2') ?? '✓ شارة مميز على الإعلان',
          context.translate('featured_benefit_3') ?? '✓ وصول لعدد أكبر من العملاء',
        ],
      },
      {
        'type': 'Featured',
        'duration': 'twoWeeks',
        'icon': Icons.star,
        'title': context.translate('duration_two_weeks') ?? 'مميز أسبوعين',
        'subtitle': context.translate('duration_two_weeks_hint') ?? 'الأكثر طلبًا',
        'price': settings?.featuredPriceTwoWeeks,
        'badge': context.translate('most_popular') ?? 'الأكثر طلباً',
        'benefits': [
          context.translate('featured_benefit_1') ?? '✓ أولوية في ظهور البحث',
          context.translate('featured_benefit_2') ?? '✓ شارة مميز على الإعلان',
          context.translate('featured_benefit_3') ?? '✓ وصول لعدد أكبر من العملاء',
        ],
      },
      {
        'type': 'Featured',
        'duration': 'month',
        'icon': Icons.workspace_premium,
        'title': context.translate('duration_month') ?? 'مميز شهر',
        'subtitle': context.translate('duration_month_hint') ?? 'أوفر قيمة، وفر أكتر',
        'price': settings?.featuredPriceMonth,
        'badge': context.translate('best_value') ?? 'أفضل قيمة',
        'benefits': [
          context.translate('featured_benefit_1') ?? '✓ أولوية قصوى في ظهور البحث',
          context.translate('featured_benefit_2') ?? '✓ شارة مميز على الإعلان',
          context.translate('featured_benefit_3') ?? '✓ أكبر وصول ممكن للعملاء',
        ],
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.translate('select_listing_plan') ?? 'اختر خطة الإعلان',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        if (_isEditing)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              context.translate('listing_type_locked_hint') ?? 'لا يمكن تغيير نوع الإعلان بعد الإنشاء',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ),
        const SizedBox(height: 10),
        ...plans.map((plan) {
          final isSelected = _listingType == plan['type'] &&
              (plan['duration'] == null ? _featuredDuration == null : _featuredDuration == plan['duration']);
          final badge = plan['badge'] as String?;
          final price = plan['price'];
          final benefits = plan['benefits'] as List<String>;
          final isNormal = plan['type'] == 'Normal';

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              onTap: _isEditing
                  ? null
                  : () => setState(() {
                        _listingType = plan['type'] as String;
                        _featuredDuration = plan['duration'] as String?;
                      }),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? primaryColor : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  color: isSelected ? primaryColor.withOpacity(0.07) : Theme.of(context).cardColor,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // أيقونة الاختيار
                    Radio<bool>(
                      value: true,
                      groupValue: isSelected,
                      onChanged: _isEditing
                          ? null
                          : (_) => setState(() {
                                _listingType = plan['type'] as String;
                                _featuredDuration = plan['duration'] as String?;
                              }),
                      activeColor: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    // تفاصيل الخطة
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(plan['icon'] as IconData,
                                  size: 18,
                                  color: isNormal ? Colors.grey[600] : Colors.amber[700]),
                              const SizedBox(width: 6),
                              Text(
                                plan['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected ? primaryColor : null,
                                ),
                              ),
                              if (badge != null) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(badge,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                              ],
                              const Spacer(),
                              // السعر
                              Text(
                                isNormal
                                    ? (context.translate('free') ?? 'مجاني')
                                    : (price != null ? '${price.toInt()} ${context.translate('egp') ?? 'ج.م'}' : '...'),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isNormal ? Colors.green[700] : primaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            plan['subtitle'] as String,
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                          if (isSelected) ...[
                            const SizedBox(height: 8),
                            ...benefits.map((b) => Padding(
                                  padding: const EdgeInsets.only(bottom: 2),
                                  child: Text(b, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                )),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildBenefitItem(IconData icon, String? text) {
    if (text == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Theme.of(context).primaryColor),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitCreate() async {
    final formData = FormData.fromMap({
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'governorate': _governorate,
      'city': _city,
      'address': _addressController.text,
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'area': double.parse(_areaController.text),
      if (_floor != null) 'floor': _floor,
      'propertyType': _propertyType,
      'listingPurpose': _listingPurpose,
      'furnished': _furnished.toString(), // تحويل لـ string 'true'/'false' حسب طلب الباك
      'listingType': _listingType,
      if (_featuredDuration != null) 'featuredDuration': _featuredDuration!,
      'showExactLocation': _showExactLocation.toString(),
      // إرسال الـ location بصيغة Bracket Notation المتوافقة مع الـ multipart/form-data
      'location[type]': 'Point',
      'location[coordinates][0]': _selectedLocation.longitude,
      'location[coordinates][1]': _selectedLocation.latitude,
    });

    for (var image in _images) {
      formData.files.add(MapEntry(
        'images',
        await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
      ));
    }

    debugPrint('=== FormData Fields Being Sent ===');
    for (var field in formData.fields) {
      debugPrint('${field.key}: ${field.value}');
    }
    debugPrint('=== FormData Files ===');
    for (var file in formData.files) {
      debugPrint('${file.key}: ${file.value.filename}');
    }
    debugPrint('===================================');

    final createdProperty = await ref.read(propertyRepositoryProvider).createProperty(formData);

    if (mounted) {
      if (_listingType == 'Featured') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentScreen(property: createdProperty, isFeatured: true),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.translate('property_listed_success'))),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _submitEdit() async {
    final propertyId = widget.existingProperty!.id!;

    // 1) تحديث الحقول النصية (JSON عادي عن طريق PATCH /properties/:id)
    // ملاحظة: listingType متعمدين نستبعدها من التعديل، لأن تغييرها لـ Featured
    // محتاج مسار دفع كامل، ومش هنسمح بيه من شاشة التعديل دي حاليًا
    final updateData = {
      'title': _titleController.text,
      'description': _descriptionController.text,
      'price': double.parse(_priceController.text),
      'governorate': _governorate,
      'city': _city,
      'address': _addressController.text,
      'bedrooms': _bedrooms,
      'bathrooms': _bathrooms,
      'area': double.parse(_areaController.text),
      if (_floor != null) 'floor': _floor,
      'propertyType': _propertyType,
      'listingPurpose': _listingPurpose,
      'furnished': _furnished.toString(), // الباك برضه مستنيها string هنا
      'showExactLocation': _showExactLocation.toString(),
      'location': {
        'type': 'Point',
        'coordinates': [_selectedLocation.longitude, _selectedLocation.latitude],
      },
    };

    await ref.read(propertyRepositoryProvider).updateProperty(propertyId, updateData);

    // 2) تحديث الصور بشكل منفصل تمامًا (PATCH /properties/:id/images)
    // بس لو فيه تغيير فعلي (صور جديدة أو صور محذوفة)
    if (_images.isNotEmpty || _removedImagePublicIds.isNotEmpty) {
      final multipartFiles = <MultipartFile>[];
      for (var image in _images) {
        multipartFiles.add(
          await MultipartFile.fromFile(image.path, filename: image.path.split('/').last),
        );
      }
      await ref.read(propertyRepositoryProvider).updatePropertyImages(
        propertyId,
        newImages: multipartFiles,
        removedImagePublicIds: _removedImagePublicIds,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.translate('property_updated_success') ?? 'Property updated successfully')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModeToggleAppBar(
        title: _isEditing ? (context.translate('edit_listing') ?? 'Edit Listing') : (context.translate('add_listing') ?? 'Add Listing'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).primaryColor,
            ),
          ),
          child: Stepper(
            type: StepperType.vertical,
            currentStep: _currentStep,
            onStepContinue: () {
              if (_currentStep < 2) {
                setState(() => _currentStep++);
              } else {
                _submit();
              }
            },
            onStepCancel: () {
              if (_currentStep > 0) {
                setState(() => _currentStep--);
              }
            },
            steps: [
            Step(
              title: Text(context.translate('basic_info') ?? 'Basic Info'),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: context.translate('title') ?? 'Title'),
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? (context.translate('required') ?? 'Required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: context.translate('description') ?? 'Description'),
                    maxLines: 3,
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? (context.translate('required') ?? 'Required') : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: context.translate('price') ?? 'Price'),
                          keyboardType: TextInputType.number,
                          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                          validator: (v) => v!.isEmpty ? (context.translate('required') ?? 'Required') : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          decoration: InputDecoration(labelText: context.translate('area') ?? 'Area'),
                          keyboardType: TextInputType.number,
                          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                          validator: (v) => v!.isEmpty ? (context.translate('required') ?? 'Required') : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _listingPurpose,
                    decoration: InputDecoration(labelText: context.translate('listing_purpose') ?? 'Listing Purpose'),
                    items: ['Rent', 'Sale']
                        .map((e) => DropdownMenuItem(value: e, child: Text(context.translate(e == 'Rent' ? 'for_rent' : 'for_sale') ?? e)))
                        .toList(),
                    onChanged: (v) => setState(() => _listingPurpose = v!),
                  ),
                  const SizedBox(height: 16),
                  Consumer(
                    builder: (context, ref, _) {
                      final settingsAsync = ref.watch(paymentMethodsProvider);
                      return settingsAsync.when(
                        data: (settings) => _buildPlanSelector(context, settings),
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (_, __) => _buildPlanSelector(context, null),
                      );
                    },
                  ),
                ],
              ),
            ),
            Step(
              title: Text(context.translate('details') ?? 'Details'),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    decoration: InputDecoration(labelText: context.translate('property_type') ?? 'Property Type'),
                    items: ['Apartment', 'Villa', 'Studio', 'Office'].map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(context.translate('type_${e.toLowerCase()}') ?? e),
                    )).toList(),
                    onChanged: (v) => setState(() => _propertyType = v!),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bedrooms,
                          decoration: InputDecoration(labelText: context.translate('bedrooms') ?? 'Bedrooms'),
                          items: List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                          onChanged: (v) => setState(() => _bedrooms = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: InputDecoration(labelText: context.translate('bathrooms') ?? 'Bathrooms'),
                          items: List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                          onChanged: (v) => setState(() => _bathrooms = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(context.translate('furnished') ?? 'Furnished'),
                    value: _furnished,
                    onChanged: (v) => setState(() => _furnished = v),
                  ),
                  const SizedBox(height: 16),
                  if (_existingImageUrls.isNotEmpty) ...[
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        context.translate('current_images') ?? 'Current Images',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      children: List.generate(_existingImageUrls.length, (index) {
                        return Stack(
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.network(_existingImageUrls[index], width: 80, height: 80, fit: BoxFit.cover),
                            ),
                            PositionedDirectional(
                              end: 0,
                              child: GestureDetector(
                                onTap: () => _removeExistingImage(index),
                                child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        );
                      }),
                    ),
                    const SizedBox(height: 12),
                  ],
                  ElevatedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.add_a_photo),
                    label: Text(context.translate('add_images') ?? 'Add Images'),
                  ),
                  Wrap(
                    children: _images.map((img) => Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: Image.file(img, width: 80, height: 80, fit: BoxFit.cover),
                        ),
                        PositionedDirectional(
                          end: 0,
                          child: GestureDetector(
                            onTap: () => setState(() => _images.remove(img)),
                            child: const CircleAvatar(radius: 10, backgroundColor: Colors.red, child: Icon(Icons.close, size: 12, color: Colors.white)),
                          ),
                        ),
                      ],
                    )).toList(),
                  ),
                ],
              ),
            ),
            Step(
              title: Text(context.translate('location') ?? 'Location'),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: context.translate('address') ?? 'Address'),
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? (context.translate('required') ?? 'Required') : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(context.translate('show_exact_location') ?? 'Show Exact Location'),
                    value: _showExactLocation,
                    onChanged: (v) => setState(() => _showExactLocation = v),
                  ),
                  const SizedBox(height: 16),
                  Text(context.translate('select_on_map') ?? 'Select on map'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 350, // زودنا الارتفاع شوية للتحكم الأفضل
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GoogleMap(
                            initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 15),
                            onMapCreated: (controller) => _mapController = controller,
                            // السماح بحركات الخريطة حتى داخل الـ Stepper
                            gestureRecognizers: {
                              Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
                            },
                            onCameraMove: (position) {
                              _selectedLocation = position.target;
                            },
                            onCameraIdle: () {
                              _updateLocation(_selectedLocation);
                            },
                            zoomControlsEnabled: false, // هنخليها false ونعمل زراير مخصصة أشيك
                            zoomGesturesEnabled: true,
                            myLocationButtonEnabled: false,
                          ),
                        ),
                        // الدبوس الثابت في منتصف الخريطة
                        IgnorePointer(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 35), // لضبط سن الدبوس في المنتصف تماماً
                              child: Icon(
                                Icons.location_on,
                                size: 45,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ),
                        ),
                        // زراير التحكم (الزوم والموقع الحالي)
                        Positioned(
                          bottom: 16,
                          right: 16,
                          child: Column(
                            children: [
                              FloatingActionButton.small(
                                heroTag: 'zoom_in',
                                onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
                                backgroundColor: Colors.white,
                                child: Icon(Icons.add, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                heroTag: 'zoom_out',
                                onPressed: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
                                backgroundColor: Colors.white,
                                child: Icon(Icons.remove, color: Theme.of(context).primaryColor),
                              ),
                              const SizedBox(height: 8),
                              FloatingActionButton.small(
                                heroTag: 'current_loc',
                                onPressed: _getCurrentLocation,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.my_location, color: Theme.of(context).primaryColor),
                              ),
                            ],
                          ),
                        ),
                        // تنبيه للمستخدم
                        Positioned(
                          top: 10,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                context.translate('move_map_to_select') ?? 'Move map to select location',
                                style: const TextStyle(color: Colors.white, fontSize: 12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.translate('location_hint') ?? 'Drag map to place pin over your property',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
}
