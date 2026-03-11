import 'package:equatable/equatable.dart';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String? fullName;
  final String? phoneNumber;
  final String? avatarUrl;
  final String? bio;
  final String? location;
  final double trustScore;
  final bool phoneVerified;
  final bool idVerified;
  final bool paymentVerified;
  final double averageRating;
  final int totalSplits;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserModel({
    required this.id,
    required this.email,
    this.fullName,
    this.phoneNumber,
    this.avatarUrl,
    this.bio,
    this.location,
    this.trustScore = 0.0,
    this.phoneVerified = false,
    this.idVerified = false,
    this.paymentVerified = false,
    this.averageRating = 0.0,
    this.totalSplits = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  String get displayName => fullName ?? email.split('@').first;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String?,
      phoneNumber: json['phone_number'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      trustScore: (json['trust_score'] as num?)?.toDouble() ?? 0.0,
      phoneVerified: json['phone_verified'] as bool? ?? false,
      idVerified: json['id_verified'] as bool? ?? false,
      paymentVerified: json['payment_verified'] as bool? ?? false,
      averageRating: (json['average_rating'] as num?)?.toDouble() ?? 0.0,
      totalSplits: json['total_splits'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'phone_number': phoneNumber,
      'avatar_url': avatarUrl,
      'bio': bio,
      'location': location,
      'trust_score': trustScore,
      'phone_verified': phoneVerified,
      'id_verified': idVerified,
      'payment_verified': paymentVerified,
      'average_rating': averageRating,
      'total_splits': totalSplits,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? phoneNumber,
    String? avatarUrl,
    String? bio,
    String? location,
    double? trustScore,
    bool? phoneVerified,
    bool? idVerified,
    bool? paymentVerified,
    double? averageRating,
    int? totalSplits,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      trustScore: trustScore ?? this.trustScore,
      phoneVerified: phoneVerified ?? this.phoneVerified,
      idVerified: idVerified ?? this.idVerified,
      paymentVerified: paymentVerified ?? this.paymentVerified,
      averageRating: averageRating ?? this.averageRating,
      totalSplits: totalSplits ?? this.totalSplits,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [id, email, trustScore, phoneVerified, idVerified, paymentVerified];
}
