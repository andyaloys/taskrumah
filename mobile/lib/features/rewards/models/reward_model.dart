class RewardModel {
  final String id;
  final String title;
  final String? description;
  final int pointsRequired;
  final String? iconEmoji;
  final bool isActive;

  RewardModel({
    required this.id,
    required this.title,
    this.description,
    required this.pointsRequired,
    this.iconEmoji,
    required this.isActive,
  });

  factory RewardModel.fromJson(Map<String, dynamic> json) {
    return RewardModel(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Hadiah',
      description: json['description'] as String?,
      pointsRequired: json['pointsRequired'] as int? ?? 0,
      iconEmoji: json['iconEmoji'] as String? ?? '🎁',
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
