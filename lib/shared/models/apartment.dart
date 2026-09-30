class Apartment {
  const Apartment({
    required this.id,
    required this.name,
    this.description,
    required this.inviteCode,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String inviteCode;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Apartment.fromJson(Map<String, dynamic> json) {
    return Apartment(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      inviteCode: json['invite_code'] as String,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Apartment copyWith({
    String? id,
    String? name,
    String? description,
    String? inviteCode,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Apartment(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      inviteCode: inviteCode ?? this.inviteCode,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'invite_code': inviteCode,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}

class UserProfileSummary {
  const UserProfileSummary({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.email,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final String? email;

  factory UserProfileSummary.fromJson(Map<String, dynamic> json) {
    return UserProfileSummary(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      avatarUrl: json['avatar_url'] as String?,
      email: json['email'] as String?,
    );
  }

  UserProfileSummary copyWith({
    String? id,
    String? name,
    String? avatarUrl,
    String? email,
  }) {
    return UserProfileSummary(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      email: email ?? this.email,
    );
  }
}

class ApartmentMember {
  const ApartmentMember({
    required this.id,
    required this.apartmentId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.profile,
  });

  final String id;
  final String apartmentId;
  final String userId;
  final String role;
  final DateTime joinedAt;
  final UserProfileSummary? profile;

  factory ApartmentMember.fromJson(Map<String, dynamic> json) {
    UserProfileSummary? profile;
    final profileData = json['profiles'];
    if (profileData != null && profileData is Map<String, dynamic>) {
      profile = UserProfileSummary.fromJson(profileData);
    }
    return ApartmentMember(
      id: json['id'] as String,
      apartmentId: json['apartment_id'] as String,
      userId: json['user_id'] as String,
      role: (json['role'] as String?) ?? 'member',
      joinedAt: DateTime.parse(json['joined_at'] as String),
      profile: profile,
    );
  }

  ApartmentMember copyWith({
    String? id,
    String? apartmentId,
    String? userId,
    String? role,
    DateTime? joinedAt,
    UserProfileSummary? profile,
  }) {
    return ApartmentMember(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      userId: userId ?? this.userId,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      profile: profile ?? this.profile,
    );
  }
}
