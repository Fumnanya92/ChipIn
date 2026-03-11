import 'package:equatable/equatable.dart';

enum MatchStatus {
  pending,
  accepted,
  declined,
  active,
  completed,
  expired;

  String get label {
    switch (this) {
      case MatchStatus.pending:
        return 'Pending';
      case MatchStatus.accepted:
        return 'Accepted';
      case MatchStatus.declined:
        return 'Declined';
      case MatchStatus.active:
        return 'Active';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.expired:
        return 'Expired';
    }
  }
}

class MatchModel extends Equatable {
  final String id;
  final String listingId;
  final String requesterId;
  final String ownerId;
  final MatchStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Joined fields
  final String? listingTitle;
  final String? listingImageUrl;
  final double? listingAmount;
  final String? requesterName;
  final String? requesterAvatarUrl;
  final double? requesterTrustScore;
  final String? ownerName;
  final String? ownerAvatarUrl;

  const MatchModel({
    required this.id,
    required this.listingId,
    required this.requesterId,
    required this.ownerId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.listingTitle,
    this.listingImageUrl,
    this.listingAmount,
    this.requesterName,
    this.requesterAvatarUrl,
    this.requesterTrustScore,
    this.ownerName,
    this.ownerAvatarUrl,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String,
      listingId: json['listing_id'] as String,
      requesterId: json['requester_id'] as String,
      ownerId: json['owner_id'] as String,
      status: MatchStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => MatchStatus.pending,
      ),
      message: json['message'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      listingTitle: json['listings']?['title'] as String?,
      listingImageUrl: json['listings']?['image_url'] as String?,
      listingAmount: (json['listings']?['split_amount'] as num?)?.toDouble(),
      requesterName: json['requester']?['full_name'] as String?,
      requesterAvatarUrl: json['requester']?['avatar_url'] as String?,
      requesterTrustScore: (json['requester']?['trust_score'] as num?)?.toDouble(),
      ownerName: json['owner']?['full_name'] as String?,
      ownerAvatarUrl: json['owner']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'listing_id': listingId,
      'requester_id': requesterId,
      'owner_id': ownerId,
      'status': status.name,
      'message': message,
    };
  }

  MatchModel copyWith({
    String? id,
    String? listingId,
    String? requesterId,
    String? ownerId,
    MatchStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MatchModel(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      requesterId: requesterId ?? this.requesterId,
      ownerId: ownerId ?? this.ownerId,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      listingTitle: listingTitle,
      listingImageUrl: listingImageUrl,
      listingAmount: listingAmount,
      requesterName: requesterName,
      requesterAvatarUrl: requesterAvatarUrl,
      requesterTrustScore: requesterTrustScore,
      ownerName: ownerName,
      ownerAvatarUrl: ownerAvatarUrl,
    );
  }

  @override
  List<Object?> get props => [id, listingId, requesterId, ownerId, status];
}
