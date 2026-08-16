class Review {
  final String? id;
  final String propertyId;
  final ReviewerInfo? reviewer;
  final int rating;
  final String comment;
  final DateTime? createdAt;

  Review({
    this.id,
    required this.propertyId,
    this.reviewer,
    required this.rating,
    required this.comment,
    this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    String pId = '';
    if (json['property'] is String) {
      pId = json['property'] as String;
    } else if (json['property'] != null && json['property'] is Map<String, dynamic>) {
      pId = (json['property'] as Map<String, dynamic>)['_id'] as String? ?? '';
    }

    return Review(
      id: json['_id'] as String?,
      propertyId: pId,
      reviewer: json['reviewer'] != null && json['reviewer'] is Map<String, dynamic>
          ? ReviewerInfo.fromJson(json['reviewer'] as Map<String, dynamic>)
          : null,
      rating: json['rating'] as int? ?? 0,
      comment: json['comment'] as String? ?? '',
      createdAt: json['createdAt'] != null ? DateTime.tryParse(json['createdAt'] as String) : null,
    );
  }
}

class ReviewerInfo {
  final String? name;
  final String? image;

  ReviewerInfo({this.name, this.image});

  factory ReviewerInfo.fromJson(Map<String, dynamic> json) {
    return ReviewerInfo(
      name: json['name'] as String?,
      image: json['image'] as String?,
    );
  }
}
