class UserModel {
  final String id;
  final String phone;
  final String name;
  final String email;
  final String role;
  final String language;
  final String? profilePhoto;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? farmer;
  final Map<String, dynamic>? supplier;
  final Map<String, dynamic>? dealer;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    this.email = '',
    required this.role,
    required this.language,
    this.profilePhoto,
    required this.isVerified,
    required this.isActive,
    this.farmer,
    this.supplier,
    this.dealer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id:           json['id']           ?? '',
    phone:        json['phone']?.toString() ?? '',
    name:         json['name']         ?? 'AgriMart User',
    email:        json['email']        ?? '',
    role:         json['role']         ?? 'FARMER',
    language:     json['language']     ?? 'en',
    profilePhoto: json['profilePhoto'],
    isVerified:   json['isVerified']   ?? false,
    isActive:     json['isActive']     ?? true,
    farmer:       json['farmer']   as Map<String, dynamic>?,
    supplier:     json['supplier'] as Map<String, dynamic>?,
    dealer:       json['dealer']   as Map<String, dynamic>?,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'name': name, 'email': email, 'role': role,
    'language': language, 'profilePhoto': profilePhoto,
    'isVerified': isVerified, 'isActive': isActive,
    'farmer': farmer, 'supplier': supplier, 'dealer': dealer,
  };

  UserModel copyWith({
    String? id, String? phone, String? name, String? email, String? role,
    String? language, String? profilePhoto, bool? isVerified, bool? isActive,
    Map<String, dynamic>? farmer, Map<String, dynamic>? supplier, Map<String, dynamic>? dealer,
  }) => UserModel(
    id:           id           ?? this.id,
    phone:        phone        ?? this.phone,
    name:         name         ?? this.name,
    email:        email        ?? this.email,
    role:         role         ?? this.role,
    language:     language     ?? this.language,
    profilePhoto: profilePhoto ?? this.profilePhoto,
    isVerified:   isVerified   ?? this.isVerified,
    isActive:     isActive     ?? this.isActive,
    farmer:       farmer       ?? this.farmer,
    supplier:     supplier     ?? this.supplier,
    dealer:       dealer       ?? this.dealer,
  );

  bool get isFarmer   => role == 'FARMER';
  bool get isSupplier => role == 'SUPPLIER';
  bool get isDealer   => role == 'DEALER';
  bool get isAdmin    => role == 'ADMIN';

  /// Convenience district getter — works for all roles
  String? get district =>
      farmer?['district'] as String? ??
      supplier?['district'] as String? ??
      dealer?['district'] as String?;

  /// District for mandi/news — ignores mistaken state names stored as district
  String get effectiveDistrict {
    final d = district?.trim();
    final s = state?.trim();
    if (d != null && d.isNotEmpty && (s == null || d.toLowerCase() != s.toLowerCase())) {
      return d;
    }
    return 'Nashik';
  }

  String? get state =>
      farmer?['state'] as String? ??
      supplier?['state'] as String? ??
      dealer?['state'] as String?;

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    return name.isNotEmpty ? name[0].toUpperCase() : 'U';
  }

  String? get farmerId    => farmer?['id']    as String?;
  String? get supplierId  => supplier?['id']  as String?;
  String? get dealerId    => dealer?['id']    as String?;
}

