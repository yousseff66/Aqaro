class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type;
  final String? propertyId;
  final String? propertyTitle;
  final String? propertyImage;
  final String? paymentId;
  final bool isRead;
  final DateTime? createdAt;
  final Map<String, dynamic> metadata;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    this.propertyId,
    this.propertyTitle,
    this.propertyImage,
    this.paymentId,
    required this.isRead,
    this.createdAt,
    this.metadata = const {},
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    String? propId;
    String? propTitle;
    String? propImage;

    final property = json['property'];
    if (property is Map<String, dynamic>) {
      propId = property['_id'] as String?;
      propTitle = property['title'] as String?;
      final images = property['images'];
      if (images is List && images.isNotEmpty) {
        propImage = images.first as String?;
      }
    } else if (property is String) {
      propId = property;
    }

    return AppNotification(
      id: json['_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      type: json['type'] as String? ?? '',
      propertyId: propId,
      propertyTitle: propTitle,
      propertyImage: propImage,
      paymentId: json['payment'] is String ? json['payment'] as String : null,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
      metadata: json['metadata'] is Map<String, dynamic> ? json['metadata'] as Map<String, dynamic> : {},
    );
  }
}