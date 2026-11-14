import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_client.dart';
import '../models/admin_dashboard_model.dart';
import '../../../worship/models/worship_model.dart';

class AdminChildWorshipModel {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final int subuh;
  final int dzuhur;
  final int ashar;
  final int maghrib;
  final int isya;
  final bool quranDone;
  final int totalPointsEarned;

  AdminChildWorshipModel({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.subuh,
    required this.dzuhur,
    required this.ashar,
    required this.maghrib,
    required this.isya,
    required this.quranDone,
    required this.totalPointsEarned,
  });

  factory AdminChildWorshipModel.fromJson(Map<String, dynamic> json) {
    return AdminChildWorshipModel(
      userId: json['userId']?.toString() ?? '',
      userName: json['userName'] as String? ?? '',
      avatarUrl: json['avatarUrl'] as String?,
      subuh: DailyWorshipModel.parsePrayerStatus(json['subuh']),
      dzuhur: DailyWorshipModel.parsePrayerStatus(json['dzuhur']),
      ashar: DailyWorshipModel.parsePrayerStatus(json['ashar']),
      maghrib: DailyWorshipModel.parsePrayerStatus(json['maghrib']),
      isya: DailyWorshipModel.parsePrayerStatus(json['isya']),
      quranDone: json['quranDone'] == true || json['quranDone'] == 'true',
      totalPointsEarned: (json['totalPointsEarned'] as num?)?.toInt() ?? 0,
    );
  }
}

class AdminRepository {
  final ApiClient _client;

  AdminRepository(this._client);

  Future<AdminDashboardModel> getDashboard() async {
    try {
      final response = await _client.dio.get(ApiConstants.adminDashboard);
      return AdminDashboardModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat dashboard admin.');
    }
  }

  Future<void> approveTask(String assignmentId) async {
    try {
      await _client.dio.post(ApiConstants.approveTask(assignmentId));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menyetujui tugas.');
    }
  }

  Future<void> rejectTask(String assignmentId, String reason) async {
    try {
      await _client.dio.post(
        ApiConstants.rejectTask(assignmentId),
        data: {'rejectionReason': reason},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menolak tugas.');
    }
  }

  Future<List<AdminChildWorshipModel>> getWorshipSummary(String dateYmd) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.worshipAdminSummary,
        queryParameters: {'date': dateYmd},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => AdminChildWorshipModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat monitoring ibadah.');
    }
  }
}
