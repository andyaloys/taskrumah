class UserModel {
  final int id;
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

  bool get isAdmin => role == 'Admin';
  bool get isChild => role == 'Child';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'Child',
      avatarUrl: json['avatarUrl'] as String?,
      totalPoints: json['totalPoints'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
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
}
