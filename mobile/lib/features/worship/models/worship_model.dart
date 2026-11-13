class DailyWorshipModel {
  final String id;
  final String userId;
  final String date;
  final int subuh; // 0 = None, 1 = Solo, 2 = Mosque
  final int dzuhur;
  final int ashar;
  final int maghrib;
  final int isya;
  final bool quranDone;
  final int totalPointsEarned;

  DailyWorshipModel({
    required this.id,
    required this.userId,
    required this.date,
    required this.subuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
    required this.quranDone,
    required this.totalPointsEarned,
  });

  DailyWorshipModel copyWith({
    int? subuh,
    int? dzuhur,
    int? ashar,
    int? maghrib,
    int? isya,
    bool? quranDone,
  }) {
    return DailyWorshipModel(
      id: id,
      userId: userId,
      date: date,
      subuh: subuh ?? this.subuh,
      dzuhur: dzuhur ?? this.dzuhur,
      ashar: ashar ?? this.ashar,
      maghrib: maghrib ?? this.maghrib,
      isya: isya ?? this.isya,
      quranDone: quranDone ?? this.quranDone,
      totalPointsEarned: totalPointsEarned,
    );
  }

  factory DailyWorshipModel.fromJson(Map<String, dynamic> json) {
    return DailyWorshipModel(
      id: json['id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      date: json['date'] as String? ?? '',
      subuh: json['subuh'] as int? ?? 0,
      dzuhur: json['dzuhur'] as int? ?? 0,
      ashar: json['ashar'] as int? ?? 0,
      maghrib: json['maghrib'] as int? ?? 0,
      isya: json['isya'] as int? ?? 0,
      quranDone: json['quranDone'] as bool? ?? false,
      totalPointsEarned: json['totalPointsEarned'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'subuh': subuh,
      'dzuhur': dzuhur,
      'ashar': ashar,
      'maghrib': maghrib,
      'isya': isya,
      'quranDone': quranDone,
    };
  }
}
