import '../../../core/constants/api_constants.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String role; // 'Admin' or 'Child'
  final String? avatarUrl;
  final int totalPoints;
  final int currentStreak;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    required this.totalPoints,
    required this.currentStreak,
  });

  bool get isAdmin => role == 'Admin' || role == '0';
  bool get isChild => role == 'Child' || role == '1';

  String? get fullAvatarUrl {
    if (avatarUrl == null || avatarUrl!.isEmpty) return null;
    if (avatarUrl!.startsWith('http://') || avatarUrl!.startsWith('https://')) {
      return avatarUrl;
    }
    final cleanPath = avatarUrl!.replaceAll('\\', '/');
    return '${ApiConstants.baseHost}${cleanPath.startsWith('/') ? '' : '/'}$cleanPath';
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? json['id'] ?? '';
    return UserModel(
      id: rawId.toString(),
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role']?.toString() ?? 'Child',
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: (json['totalPoints'] as num?)?.toInt() ?? 0,
      currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'avatarUrl': avatarUrl,
      'totalPoints': totalPoints,
      'currentStreak': currentStreak,
    };
  }

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? avatarUrl,
    int? totalPoints,
    int? currentStreak,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      totalPoints: totalPoints ?? this.totalPoints,
      currentStreak: currentStreak ?? this.currentStreak,
    );
  }
}
