class ApiConstants {
  static const String baseUrl = 'https://api.aqaroeg.com/api';
  
  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String me = '/auth/me';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String updatePhone = '/users/me/phone';
  static const String deleteAccount = '/users/me';

  // Properties
  static const String properties = '/properties';
  static const String myProperties = '/properties/my';
  static const String propertyStats = '/properties/my/stats';
  static const String nearbyProperties = '/properties/nearby';

  // Favorites
  static const String favorites = '/favorites';
  static String isFavorite(String id) => '/favorites/is-favorite/$id';
  static const String favoritesCount = '/favorites/count';

  // Reviews
  static const String reviews = '/reviews';
  static String userReviews(String userId) => '/reviews/user/$userId';
  static String userRating(String userId) => '/reviews/user/$userId/rating';

  // Reports
  static const String reports = '/reports';
  static const String myReports = '/reports/my';

  // Payments
  static const String payments = '/payments';
  static const String myPayments = '/payments/my';
  static const String paymentMethods = '/payments/methods';

  // Settings
  static const String settings = '/settings';

  // Notifications
  static const String notifications = '/notifications';
  static const String unreadNotificationsCount = '/notifications/unread-count';

  // Admin
  static const String adminDashboard = '/admin/dashboard';
  static const String adminPendingProperties = '/admin/properties/pending';
  static const String adminUsers = '/admin/users';
  static const String adminSettings = '/admin/settings';
  static const String adminDashboardExport = '/admin/dashboard/export';
}
