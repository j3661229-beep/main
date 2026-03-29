class UserModel {
  final String id;
  final String phone;
  final String name;
  final String role;
  final String language;
  final String? profilePhoto;
  final bool isVerified;
  final bool isActive;
  final Map<String, dynamic>? farmer;
  final Map<String, dynamic>? supplier;

  const UserModel({
    required this.id,
    required this.phone,
    required this.name,
    required this.role,
    required this.language,
    this.profilePhoto,
    required this.isVerified,
    required this.isActive,
    this.farmer,
    this.supplier,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'] ?? '',
    phone: json['phone'] ?? '',
    name: json['name'] ?? 'AgriMart User',
    role: json['role'] ?? 'FARMER',
    language: json['language'] ?? 'marathi',
    profilePhoto: json['profilePhoto'],
    isVerified: json['isVerified'] ?? false,
    isActive: json['isActive'] ?? true,
    farmer: json['farmer'],
    supplier: json['supplier'],
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'phone': phone, 'name': name, 'role': role,
    'language': language, 'profilePhoto': profilePhoto,
    'isVerified': isVerified, 'isActive': isActive,
    'farmer': farmer, 'supplier': supplier,
  };

  bool get isFarmer => role == 'FARMER';
  bool get isSupplier => role == 'SUPPLIER';
  bool get isAdmin => role == 'ADMIN';
  String get initials => name.isNotEmpty ? name[0].toUpperCase() : 'U';
  String? get farmerId => farmer?['id'];
  String? get supplierId => supplier?['id'];
}
