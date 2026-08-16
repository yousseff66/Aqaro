import 'package:sakan_app/shared/models/user_model.dart';

class Property {
  final String? id;
  final String title;
  final String description;
  final double price;
  final String governorate;
  final String city;
  final String address;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final int? floor;
  final String propertyType;
  final bool furnished;
  final List<String> images;
  final List<String> imagePublicIds;
  final String status;
  final int views;
  final int favoritesCount;
  final String listingType;
  final String listingPurpose; // 'Sale' | 'Rent'
  final String? featuredDuration; // 'week' | 'twoWeeks' | 'month'
  final DateTime? featuredExpiresAt;
  bool get isFeatured => listingType == 'Featured';
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool showExactLocation;
  final LocationData location;
  final User? owner;

  Property({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.governorate,
    required this.city,
    required this.address,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    this.floor,
    required this.propertyType,
    required this.furnished,
    this.images = const [],
    this.imagePublicIds = const [],
    required this.status,
    this.views = 0,
    this.favoritesCount = 0,
    required this.listingType,
    required this.listingPurpose,
    this.featuredDuration,
    this.featuredExpiresAt,
    this.publishedAt,
    this.expiresAt,
    this.showExactLocation = true,
    required this.location,
    this.owner,
  });

  factory Property.fromJson(Map<String, dynamic> json) {
    return Property(
      id: json['_id'] as String?,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      governorate: json['governorate'] as String? ?? '',
      city: json['city'] as String? ?? '',
      address: json['address'] as String? ?? '',
      bedrooms: json['bedrooms'] as int? ?? 0,
      bathrooms: json['bathrooms'] as int? ?? 0,
      area: (json['area'] as num?)?.toDouble() ?? 0.0,
      floor: json['floor'] as int?,
      propertyType: json['propertyType'] as String? ?? 'Unknown',
      furnished: json['furnished'] is bool 
          ? json['furnished'] as bool 
          : json['furnished'] == 'true',
      images: json['images'] is List ? List<String>.from(json['images']) : const [],
      imagePublicIds: json['imagePublicIds'] is List ? List<String>.from(json['imagePublicIds']) : const [],
      status: json['status'] as String? ?? 'Pending',
      views: json['views'] as int? ?? 0,
      favoritesCount: json['favoritesCount'] as int? ?? 0,
      listingType: json['listingType'] as String? ?? 'Normal',
      listingPurpose: json['listingPurpose'] as String? ?? 'Rent',
      featuredDuration: json['featuredDuration'] as String?,
      featuredExpiresAt: json['featuredExpiresAt'] != null ? DateTime.tryParse(json['featuredExpiresAt']) : null,
      publishedAt: json['publishedAt'] != null ? DateTime.tryParse(json['publishedAt']) : null,
      expiresAt: json['expiresAt'] != null ? DateTime.tryParse(json['expiresAt']) : null,
      showExactLocation: json['showExactLocation'] as bool? ?? true,
      location: LocationData.fromJson(json['location']),
      owner: json['owner'] != null && json['owner'] is Map<String, dynamic>
          ? User.fromJson(json['owner'])
          : null,
    );
  }
}

class LocationData {
  final String type;
  final List<double> coordinates;

  LocationData({this.type = 'Point', required this.coordinates});

  factory LocationData.fromJson(Map<String, dynamic>? json) {
    if (json == null || json['coordinates'] == null) {
      return LocationData(coordinates: const [0.0, 0.0]);
    }
    final rawCoords = json['coordinates'];
    if (rawCoords is! List || rawCoords.length != 2) {
      return LocationData(coordinates: const [0.0, 0.0]);
    }
    try {
      return LocationData(
        type: json['type'] ?? 'Point',
        coordinates: List<double>.from(
          rawCoords.map((x) => (x as num).toDouble()),
        ),
      );
    } catch (_) {
      return LocationData(coordinates: const [0.0, 0.0]);
    }
  }

  Map<String, dynamic> toJson() => {
    'type': type,
    'coordinates': coordinates,
  };

  bool get isValid => coordinates.length == 2 && (coordinates[0] != 0.0 || coordinates[1] != 0.0);
}
