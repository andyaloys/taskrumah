import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/worship_model.dart';

class WorshipRepository {
  final ApiClient _client;

  WorshipRepository(this._client);

  Future<DailyWorshipModel> getMyWorship(String dateYmd) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.worshipMy,
        queryParameters: {'date': dateYmd},
      );
      return DailyWorshipModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat catatan ibadah.');
    }
  }

  Future<void> saveWorship(DailyWorshipModel model) async {
    try {
      await _client.dio.post(
        ApiConstants.worshipSave,
        data: model.toJson(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menyimpan catatan ibadah.');
    }
  }
}
