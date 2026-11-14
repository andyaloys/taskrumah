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

  static int parsePrayerStatus(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) {
      final s = value.toLowerCase().trim();
      if (s == 'solo' || s == '1') return 1;
      if (s == 'mosque' || s == '2') return 2;
      return 0; // 'none', '0', etc.
    }
    return 0;
  }

  static String statusToString(int status) {
    switch (status) {
      case 1:
        return 'Solo';
      case 2:
        return 'Mosque';
      default:
        return 'None';
    }
  }

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
      subuh: parsePrayerStatus(json['subuh']),
      dzuhur: parsePrayerStatus(json['dzuhur']),
      ashar: parsePrayerStatus(json['ashar']),
      maghrib: parsePrayerStatus(json['maghrib']),
      isya: parsePrayerStatus(json['isya']),
      quranDone: json['quranDone'] == true || json['quranDone'] == 'true',
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'subuh': statusToString(subuh),
      'dzuhur': statusToString(dzuhur),
      'ashar': statusToString(ashar),
      'maghrib': statusToString(maghrib),
      'isya': statusToString(isya),
      'quranDone': quranDone,
    };
  }
}
