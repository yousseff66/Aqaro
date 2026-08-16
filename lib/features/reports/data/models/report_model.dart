import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/shared/models/user_model.dart';

class PropertyReport {
  final String? id;
  final Property? property;
  final User? reporter;
  final String reason;
  final String description;
  final String status; // 'Pending', 'Reviewed', 'Rejected'
  final DateTime? createdAt;

  PropertyReport({
    this.id,
    this.property,
    this.reporter,
    required this.reason,
    required this.description,
    required this.status,
    this.createdAt,
  });

  factory PropertyReport.fromJson(Map<String, dynamic> json) {
    return PropertyReport(
      id: json['_id'],
      property: json['property'] != null && json['property'] is Map<String, dynamic> 
          ? Property.fromJson(json['property']) 
          : null,
      reporter: json['reporter'] != null && json['reporter'] is Map<String, dynamic> 
          ? User.fromJson(json['reporter']) 
          : null,
      reason: json['reason'],
      description: json['description'] ?? '',
      status: json['status'] ?? 'Pending',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
