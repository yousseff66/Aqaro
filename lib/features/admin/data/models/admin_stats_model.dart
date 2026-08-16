class AdminStats {
  final int totalUsers;
  final int totalAdmins;
  final List<LatestUser> latestUsers;
  final int totalProperties;
  final int pendingProperties;
  final int publishedProperties;
  final int rejectedProperties;
  final int rentedProperties;
  final int expiredProperties;
  final int featuredProperties;
  final int totalViews;
  final int totalFavorites;
  final int pendingPayments;
  final double totalRevenue;
  final int activeReports;
  final List<CityStat> topCities;

  AdminStats({
    required this.totalUsers,
    required this.totalAdmins,
    required this.latestUsers,
    required this.totalProperties,
    required this.pendingProperties,
    required this.publishedProperties,
    required this.rejectedProperties,
    required this.rentedProperties,
    required this.expiredProperties,
    required this.featuredProperties,
    required this.totalViews,
    required this.totalFavorites,
    required this.pendingPayments,
    required this.totalRevenue,
    required this.activeReports,
    required this.topCities,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    final users = json['users'] as Map<String, dynamic>? ?? {};
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    final payments = json['payments'] as Map<String, dynamic>? ?? {};

    return AdminStats(
      totalUsers: users['total'] ?? 0,
      totalAdmins: users['admins'] ?? 0,
      latestUsers: (users['latest'] as List?)?.map((e) => LatestUser.fromJson(e)).toList() ?? [],
      totalProperties: properties['total'] ?? 0,
      pendingProperties: properties['pending'] ?? 0,
      publishedProperties: properties['published'] ?? 0,
      rejectedProperties: properties['rejected'] ?? 0,
      rentedProperties: properties['rented'] ?? 0,
      expiredProperties: properties['expired'] ?? 0,
      featuredProperties: properties['featured'] ?? 0,
      totalViews: properties['views'] ?? 0,
      totalFavorites: properties['favorites'] ?? 0,
      pendingPayments: payments['pending'] ?? 0,
      totalRevenue: (payments['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      activeReports: json['activeReports'] ?? 0,
      topCities: (json['topCities'] as List?)?.map((e) => CityStat.fromJson(e)).toList() ?? [],
    );
  }
}

class LatestUser {
  final String id;
  final String name;
  final String email;
  final DateTime? createdAt;

  LatestUser({required this.id, required this.name, required this.email, this.createdAt});

  factory LatestUser.fromJson(Map<String, dynamic> json) {
    return LatestUser(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt']) : null,
    );
  }
}

class CityStat {
  final String city;
  final int count;

  CityStat({required this.city, required this.count});

  factory CityStat.fromJson(Map<String, dynamic> json) {
    return CityStat(city: json['city'] ?? '', count: json['count'] ?? 0);
  }
}
