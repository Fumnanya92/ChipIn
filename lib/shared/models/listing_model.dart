import 'package:equatable/equatable.dart';

enum ListingCategory {
  apartment,
  subscription,
  carpool,
  bills,
  office,
  groceries,
  other;

  String get label {
    switch (this) {
      case ListingCategory.apartment:
        return 'Apartment';
      case ListingCategory.subscription:
        return 'Subscription';
      case ListingCategory.carpool:
        return 'Carpool';
      case ListingCategory.bills:
        return 'Bills';
      case ListingCategory.office:
        return 'Office';
      case ListingCategory.groceries:
        return 'Groceries';
      case ListingCategory.other:
        return 'Other';
    }
  }

  String get subtitle {
    switch (this) {
      case ListingCategory.apartment:
        return 'Rent & Utilities';
      case ListingCategory.subscription:
        return 'Streaming & Apps';
      case ListingCategory.carpool:
        return 'Shared Rides';
      case ListingCategory.bills:
        return 'Household Bills';
      case ListingCategory.office:
        return 'Shared Supplies';
      case ListingCategory.groceries:
        return 'Food & Supplies';
      case ListingCategory.other:
        return 'Everything else';
    }
  }
}

enum ListingDuration { oneTime, monthly, custom }

enum ListingStatus { active, filled, paused, expired }

class ListingModel extends Equatable {
  final String id;
  final String userId;
  final String title;
  final ListingCategory category;
  final double totalCost;
  final double splitAmount;
  final int slotsTotal;
  final int slotsFilled;
  final ListingDuration duration;
  final String location;
  final bool isRemote;
  final String? description;
  final List<String> tags;
  final ListingStatus status;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Poster info (joined from users table)
  final String? posterName;
  final String? posterAvatarUrl;
  final double? posterTrustScore;

  const ListingModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.category,
    required this.totalCost,
    required this.splitAmount,
    required this.slotsTotal,
    required this.slotsFilled,
    required this.duration,
    required this.location,
    required this.isRemote,
    this.description,
    required this.tags,
    required this.status,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.posterName,
    this.posterAvatarUrl,
    this.posterTrustScore,
  });

  int get slotsLeft => slotsTotal - slotsFilled;

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      category: ListingCategory.values.firstWhere(
        (e) => e.name == json['category'],
        orElse: () => ListingCategory.other,
      ),
      totalCost: ((json['total_cost'] ?? json['amount']) as num).toDouble(),
      splitAmount: ((json['split_amount'] ?? json['amount']) as num).toDouble(),
      slotsTotal: (json['slots_total'] ?? json['split_ways'] ?? 2) as int,
      slotsFilled: json['slots_filled'] as int,
      duration: ListingDuration.values.firstWhere(
        (e) => e.name == json['duration'],
        orElse: () => ListingDuration.monthly,
      ),
      location: json['location'] as String,
      isRemote: json['is_remote'] as bool,
      description: json['description'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      status: ListingStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ListingStatus.active,
      ),
      imageUrl: json['image_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      posterName: json['users']?['full_name'] as String?,
      posterAvatarUrl: json['users']?['avatar_url'] as String?,
      posterTrustScore: (json['users']?['trust_score'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'category': category.name,
      'total_cost': totalCost,
      'split_amount': splitAmount,
      'slots_total': slotsTotal,
      'slots_filled': slotsFilled,
      'duration': duration.name,
      'location': location,
      'is_remote': isRemote,
      'description': description,
      'tags': tags,
      'status': status.name,
      'image_url': imageUrl,
    };
  }

  ListingModel copyWith({
    String? id,
    String? userId,
    String? title,
    ListingCategory? category,
    double? totalCost,
    double? splitAmount,
    int? slotsTotal,
    int? slotsFilled,
    ListingDuration? duration,
    String? location,
    bool? isRemote,
    String? description,
    List<String>? tags,
    ListingStatus? status,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? posterName,
    String? posterAvatarUrl,
    double? posterTrustScore,
  }) {
    return ListingModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      category: category ?? this.category,
      totalCost: totalCost ?? this.totalCost,
      splitAmount: splitAmount ?? this.splitAmount,
      slotsTotal: slotsTotal ?? this.slotsTotal,
      slotsFilled: slotsFilled ?? this.slotsFilled,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      isRemote: isRemote ?? this.isRemote,
      description: description ?? this.description,
      tags: tags ?? this.tags,
      status: status ?? this.status,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      posterName: posterName ?? this.posterName,
      posterAvatarUrl: posterAvatarUrl ?? this.posterAvatarUrl,
      posterTrustScore: posterTrustScore ?? this.posterTrustScore,
    );
  }

  @override
  List<Object?> get props => [id, userId, title, category, totalCost, splitAmount, slotsTotal, slotsFilled, status];
}
