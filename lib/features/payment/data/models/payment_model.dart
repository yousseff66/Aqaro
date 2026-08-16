import 'package:sakan_app/features/properties/data/models/property_model.dart';
import 'package:sakan_app/shared/models/user_model.dart';

class Payment {
  final String? id;
  final User? user;
  final Property? property;
  final double amount;
  final String paymentMethod;
  final String status;
  final bool isRenewal;
  final String? receiptImage;
  final DateTime? createdAt;

  Payment({
    this.id,
    this.user,
    this.property,
    required this.amount,
    required this.paymentMethod,
    required this.status,
    this.isRenewal = false,
    this.receiptImage,
    this.createdAt,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['_id'],
      user: json['user'] != null && json['user'] is Map<String, dynamic> ? User.fromJson(json['user']) : null,
      property: json['property'] != null && json['property'] is Map<String, dynamic> ? Property.fromJson(json['property']) : null,
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] ?? '',
      status: json['status'] ?? 'Pending',
      isRenewal: json['isRenewal'] as bool? ?? false,
      receiptImage: json['receiptImage'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
}
