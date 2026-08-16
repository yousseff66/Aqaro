import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sakan_app/core/localization/app_localizations.dart';
import 'package:sakan_app/features/properties/presentation/providers/property_provider.dart';
import 'package:sakan_app/shared/widgets/property_card.dart';
import 'package:sakan_app/features/properties/presentation/screens/property_detail_screen.dart';
import 'package:sakan_app/core/theme/app_colors.dart';

import 'package:sakan_app/shared/widgets/mode_toggle_appbar.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearched = true; // Set to true since we'll search on init
  double? _minPrice;
  double? _maxPrice;
  int? _bedrooms;
  String? _propertyType;
  String? _listingPurpose;
  String? _sort;

  @override
  void initState() {
    super.initState();
    // Trigger initial search to show all properties automatically
    Future.microtask(() => _triggerSearch());
  }

  void _triggerSearch() {
    if (!mounted) return;
    setState(() => _hasSearched = true);
    ref.read(searchResultsProvider.notifier).fetchProperties(
      search: _searchController.text.isNotEmpty ? _searchController.text : null,
      city: null,
      governorate: null,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      bedrooms: _bedrooms,
      propertyType: _propertyType,
      listingPurpose: _listingPurpose,
      sort: _sort,
      refresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final propertiesAsync = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: ModeToggleAppBar(
        titleWidget: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.search, color: AppColors.lime700, size: 22),
              ),
              Expanded(
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(
                    color: AppColors.carbon900,
                    fontSize: 16,
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  decoration: InputDecoration(
                    hintText: context.translate('search_properties'),
                    hintStyle: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  onSubmitted: (value) => _triggerSearch(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: VerticalDivider(
                  color: Colors.grey[300],
                  width: 1,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.tune, color: AppColors.carbon900, size: 20),
                onPressed: () => _showFilterSheet(context),
              ),
              const SizedBox(width: 4),
            ],
          ),
        ),
        actions: const [], // The filter is now inside the search bar
      ),
      body: propertiesAsync.when(
        data: (properties) {
          if (properties.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_outlined, size: 80, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    context.translate('no_results_found') ?? 'No properties found matching your criteria',
                    style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: properties.length,
            itemBuilder: (context, index) {
              final property = properties[index];
              return PropertyCard(
                property: property,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PropertyDetailScreen(propertyId: property.id!),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsetsDirectional.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                start: 20,
                end: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.translate('filters'),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: _propertyType,
                    hint: Text(context.translate('property_type')),
                    items: ['Apartment', 'Villa', 'Studio', 'Office'].map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(context.translate('type_${e.toLowerCase()}') ?? e),
                    )).toList(),
                    onChanged: (v) => setModalState(() => _propertyType = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _listingPurpose,
                    decoration: InputDecoration(labelText: context.translate('listing_purpose')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.translate('any') ?? 'Any')),
                      DropdownMenuItem(value: 'Sale', child: Text(context.translate('sale'))),
                      DropdownMenuItem(value: 'Rent', child: Text(context.translate('rent'))),
                    ],
                    onChanged: (v) => setModalState(() => _listingPurpose = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int?>(
                    value: _bedrooms,
                    decoration: InputDecoration(labelText: context.translate('bedrooms')),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.translate('any') ?? 'Any')),
                      ...List.generate(10, (i) => i + 1).map((e) => DropdownMenuItem(value: e, child: Text(e.toString()))),
                    ],
                    onChanged: (v) => setModalState(() => _bedrooms = v),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _sort,
                    decoration: InputDecoration(labelText: context.translate('sort_by') ?? 'Sort By'),
                    items: [
                      DropdownMenuItem(value: null, child: Text(context.translate('sort_latest') ?? 'Latest')),
                      DropdownMenuItem(value: 'priceAsc', child: Text(context.translate('sort_price_asc') ?? 'Price: Low to High')),
                      DropdownMenuItem(value: 'priceDesc', child: Text(context.translate('sort_price_desc') ?? 'Price: High to Low')),
                    ],
                    onChanged: (v) => setModalState(() => _sort = v),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _minPrice?.toString(),
                          decoration: InputDecoration(labelText: context.translate('min_price')),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _minPrice = double.tryParse(v),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _maxPrice?.toString(),
                          decoration: InputDecoration(labelText: context.translate('max_price')),
                          keyboardType: TextInputType.number,
                          onChanged: (v) => _maxPrice = double.tryParse(v),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      _triggerSearch();
                      Navigator.pop(context);
                    },
                    child: Text(context.translate('apply_filters')),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
