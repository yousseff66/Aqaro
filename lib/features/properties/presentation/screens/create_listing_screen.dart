import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
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
    final List<XFile> pickedFiles = await _picker.pickMultiImage();
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
        title: _isEditing ? (context.translate('edit_listing') ?? 'Edit Listing') : context.translate('add_listing'),
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
            type: StepperType.vertical, // حل مشكلة الـ Overflow
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
              title: Text(context.translate('basic_info')),
              isActive: _currentStep >= 0,
              content: Column(
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(labelText: context.translate('title')),
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? context.translate('required') : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(labelText: context.translate('description')),
                    maxLines: 3,
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? context.translate('required') : null,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          decoration: InputDecoration(labelText: context.translate('price')),
                          keyboardType: TextInputType.number,
                          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                          validator: (v) => v!.isEmpty ? context.translate('required') : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          controller: _areaController,
                          decoration: InputDecoration(labelText: context.translate('area')),
                          keyboardType: TextInputType.number,
                          textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                          validator: (v) => v!.isEmpty ? context.translate('required') : null,
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
                  DropdownButtonFormField<String>(
                    value: _listingType,
                    decoration: InputDecoration(
                      labelText: context.translate('listing_type'),
                      helperText: _isEditing
                          ? (context.translate('listing_type_locked_hint') ??
                          'Listing type cannot be changed after creation')
                          : null,
                    ),
                    items: ['Normal', 'Featured']
                        .map((e) => DropdownMenuItem(value: e, child: Text(context.translate(e.toLowerCase()))))
                        .toList(),
                    // ممنوع تغيير نوع الإعلان وقت التعديل، عشان منحصلش على
                    // عقار Featured من غير أي مسار دفع فعلي
                    onChanged: _isEditing ? null : (v) => setState(() => _listingType = v!),
                  ),
                  if (_listingType == 'Featured') ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.translate('featured_headline') ?? '🌟 خلي إعلانك يوصل لأكبر عدد ناس',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).primaryColor),
                          ),
                          const SizedBox(height: 12),
                          // Benefits section
                          Text(
                            context.translate('featured_benefits_title') ?? 'ليه تختار الإعلان المميز؟',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          _buildBenefitItem(Icons.trending_up, context.translate('featured_benefit_1')),
                          _buildBenefitItem(Icons.star_outline, context.translate('featured_benefit_2')),
                          _buildBenefitItem(Icons.bolt, context.translate('featured_benefit_3')),
                          const Divider(height: 24),
                          Text(
                            context.translate('select_duration') ?? 'اختر مدة التميز:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          const SizedBox(height: 8),
                          _buildDurationOption('week', context.translate('duration_week') ?? 'أسبوع', context.translate('duration_week_hint') ?? 'مثالي لو مستعجل تأجر بسرعة'),
                          const SizedBox(height: 8),
                          _buildDurationOption('twoWeeks', context.translate('duration_two_weeks') ?? 'أسبوعين', context.translate('duration_two_weeks_hint') ?? 'الأكثر طلبًا', isPopular: true),
                          const SizedBox(height: 8),
                          _buildDurationOption('month', context.translate('duration_month') ?? 'شهر كامل', context.translate('duration_month_hint') ?? 'أوفر قيمة، وفر أكتر'),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Step(
              title: Text(context.translate('details')),
              isActive: _currentStep >= 1,
              content: Column(
                children: [
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    decoration: InputDecoration(labelText: context.translate('property_type')),
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
                          decoration: InputDecoration(labelText: context.translate('bedrooms')),
                          items: List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                          onChanged: (v) => setState(() => _bedrooms = v!),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _bathrooms,
                          decoration: InputDecoration(labelText: context.translate('bathrooms')),
                          items: List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))).toList(),
                          onChanged: (v) => setState(() => _bathrooms = v!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(context.translate('furnished')),
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
                    label: Text(context.translate('add_images')),
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
              title: Text(context.translate('location')),
              isActive: _currentStep >= 2,
              content: Column(
                children: [
                  TextFormField(
                    controller: _addressController,
                    decoration: InputDecoration(labelText: context.translate('address')),
                    textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.right : TextAlign.left,
                    validator: (v) => v!.isEmpty ? context.translate('required') : null,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(context.translate('show_exact_location') ?? 'Show Exact Location'),
                    value: _showExactLocation,
                    onChanged: (v) => setState(() => _showExactLocation = v),
                  ),
                  const SizedBox(height: 16),
                  Text(context.translate('select_on_map')),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 300,
                    child: Stack(
                      children: [
                        GoogleMap(
                          initialCameraPosition: CameraPosition(target: _selectedLocation, zoom: 12),
                          onTap: _updateLocation,
                          onMapCreated: (controller) => _mapController = controller,
                          markers: {
                            Marker(markerId: const MarkerId('selected'), position: _selectedLocation),
                          },
                        ),
                        Positioned(
                          top: 16,
                          right: 16,
                          child: FloatingActionButton.small(
                            onPressed: _getCurrentLocation,
                            child: const Icon(Icons.my_location),
                          ),
                        ),
                      ],
                    ),
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
