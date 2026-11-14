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

  Future<AdminDashboardModel> getDashboard({int weekOffset = 0, String? date}) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.adminDashboard,
        queryParameters: {
          'weekOffset': weekOffset,
          if (date != null && date.isNotEmpty) 'date': date,
        },
      );
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

  // --- Kelola Master Tugas ---
  Future<List<Map<String, dynamic>>> getTasks({bool activeOnly = false}) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.tasks,
        queryParameters: {'activeOnly': activeOnly},
      );
      return (response.data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat master tugas.');
    }
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    try {
      await _client.dio.post(ApiConstants.tasks, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal membuat tugas baru.');
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('${ApiConstants.tasks}/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memperbarui tugas.');
    }
  }

  Future<void> deleteTask(String id) async {
    try {
      await _client.dio.delete('${ApiConstants.tasks}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menghapus tugas.');
    }
  }

  // --- Pengaturan Poin Ibadah ---
  Future<Map<String, dynamic>> getWorshipSetting() async {
    try {
      final response = await _client.dio.get(ApiConstants.worshipSetting);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat pengaturan ibadah.');
    }
  }

  Future<void> updateWorshipSetting(Map<String, dynamic> data) async {
    try {
      await _client.dio.put(ApiConstants.worshipSetting, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menyimpan pengaturan ibadah.');
    }
  }

  // --- Kelola Hadiah & Klaim ---
  Future<List<Map<String, dynamic>>> getRewards() async {
    try {
      final response = await _client.dio.get(ApiConstants.rewards);
      return (response.data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat katalog hadiah.');
    }
  }

  Future<void> createReward(Map<String, dynamic> data) async {
    try {
      await _client.dio.post(ApiConstants.rewards, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menambah hadiah.');
    }
  }

  Future<void> updateReward(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put('${ApiConstants.rewards}/$id', data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memperbarui hadiah.');
    }
  }

  Future<void> deleteReward(String id) async {
    try {
      await _client.dio.delete('${ApiConstants.rewards}/$id');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menghapus hadiah.');
    }
  }

  Future<void> processRedemption(String id, String status) async {
    try {
      await _client.dio.put(
        ApiConstants.processRedemption(id),
        data: {'status': status},
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memproses klaim.');
    }
  }

  // --- Kelola Pengguna (Anak & Orang Tua) ---
  Future<List<Map<String, dynamic>>> getUsers() async {
    try {
      final response = await _client.dio.get(ApiConstants.users);
      return (response.data as List<dynamic>).map((e) => e as Map<String, dynamic>).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat pengguna.');
    }
  }

  Future<void> createUser(Map<String, dynamic> data) async {
    try {
      await _client.dio.post(ApiConstants.users, data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menambahkan pengguna.');
    }
  }

  Future<void> updateUser(String id, Map<String, dynamic> data) async {
    try {
      await _client.dio.put(ApiConstants.userDetail(id), data: data);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memperbarui pengguna.');
    }
  }

  Future<void> uploadAvatar(String id, String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      await _client.dio.post('${ApiConstants.users}/$id/avatar', data: formData);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengupload avatar.');
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await _client.dio.delete(ApiConstants.userDetail(id));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menonaktifkan pengguna.');
    }
  }
}
