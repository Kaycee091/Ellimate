enum UpdateCategory {
  general,
  maintenance,
  cleaning,
  water,
  electricity,
  parcel,
  security,
  other;

  static UpdateCategory fromString(String value) {
    switch (value) {
      case 'maintenance':
        return UpdateCategory.maintenance;
      case 'cleaning':
        return UpdateCategory.cleaning;
      case 'water':
        return UpdateCategory.water;
      case 'electricity':
        return UpdateCategory.electricity;
      case 'parcel':
        return UpdateCategory.parcel;
      case 'security':
        return UpdateCategory.security;
      case 'other':
        return UpdateCategory.other;
      default:
        return UpdateCategory.general;
    }
  }

  String get displayName {
    switch (this) {
      case UpdateCategory.general:
        return 'General';
      case UpdateCategory.maintenance:
        return 'Maintenance';
      case UpdateCategory.cleaning:
        return 'Cleaning';
      case UpdateCategory.water:
        return 'Water';
      case UpdateCategory.electricity:
        return 'Electricity';
      case UpdateCategory.parcel:
        return 'Parcel';
      case UpdateCategory.security:
        return 'Security';
      case UpdateCategory.other:
        return 'Other';
    }
  }

  String get icon {
    switch (this) {
      case UpdateCategory.general:
        return '📢';
      case UpdateCategory.maintenance:
        return '🔧';
      case UpdateCategory.cleaning:
        return '🧹';
      case UpdateCategory.water:
        return '💧';
      case UpdateCategory.electricity:
        return '⚡';
      case UpdateCategory.parcel:
        return '📦';
      case UpdateCategory.security:
        return '🔒';
      case UpdateCategory.other:
        return '📌';
    }
  }

  String get name {
    switch (this) {
      case UpdateCategory.general:
        return 'general';
      case UpdateCategory.maintenance:
        return 'maintenance';
      case UpdateCategory.cleaning:
        return 'cleaning';
      case UpdateCategory.water:
        return 'water';
      case UpdateCategory.electricity:
        return 'electricity';
      case UpdateCategory.parcel:
        return 'parcel';
      case UpdateCategory.security:
        return 'security';
      case UpdateCategory.other:
        return 'other';
    }
  }
}

class ApartmentUpdate {
  const ApartmentUpdate({
    required this.id,
    required this.apartmentId,
    required this.createdBy,
    required this.title,
    required this.description,
    required this.category,
    this.scheduledAt,
    required this.createdAt,
    this.updatedAt,
    this.creatorName,
    this.creatorAvatarUrl,
  });

  final String id;
  final String apartmentId;
  final String createdBy;
  final String title;
  final String description;
  final UpdateCategory category;
  final DateTime? scheduledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? creatorName;
  final String? creatorAvatarUrl;

  factory ApartmentUpdate.fromJson(Map<String, dynamic> json) {
    return ApartmentUpdate(
      id: json['id'] as String,
      apartmentId: json['apartment_id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      category: UpdateCategory.fromString(
          (json['category'] as String?) ?? 'general'),
      scheduledAt: json['scheduled_at'] != null
          ? DateTime.parse(json['scheduled_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  ApartmentUpdate copyWith({
    String? id,
    String? apartmentId,
    String? createdBy,
    String? title,
    String? description,
    UpdateCategory? category,
    DateTime? scheduledAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? creatorName,
    String? creatorAvatarUrl,
  }) {
    return ApartmentUpdate(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      creatorName: creatorName ?? this.creatorName,
      creatorAvatarUrl: creatorAvatarUrl ?? this.creatorAvatarUrl,
    );
  }
}
