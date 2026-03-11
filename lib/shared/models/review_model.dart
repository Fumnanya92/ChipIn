import 'package:equatable/equatable.dart';

class ReviewModel extends Equatable {
  final String id;
  final String reviewerId;
  final String revieweeId;
  final String matchId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  // Joined
  final String? reviewerName;
  final String? reviewerAvatarUrl;

  const ReviewModel({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.matchId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.reviewerName,
    this.reviewerAvatarUrl,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> json) {
    return ReviewModel(
      id: json['id'] as String,
      reviewerId: json['reviewer_id'] as String,
      revieweeId: json['reviewee_id'] as String,
      matchId: json['match_id'] as String,
      rating: json['rating'] as int,
      comment: json['comment'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      reviewerName: json['reviewer']?['full_name'] as String?,
      reviewerAvatarUrl: json['reviewer']?['avatar_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'match_id': matchId,
      'rating': rating,
      'comment': comment,
    };
  }

  @override
  List<Object?> get props => [id, reviewerId, revieweeId, matchId, rating];
}
