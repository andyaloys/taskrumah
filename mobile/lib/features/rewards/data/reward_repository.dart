import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/reward_model.dart';

class RewardRepository {
  final ApiClient _client;

  RewardRepository(this._client);

  Future<List<RewardModel>> getRewards() async {
    try {
      final response = await _client.dio.get(ApiConstants.rewards);
      final list = response.data as List<dynamic>;
      return list.map((e) => RewardModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat katalog hadiah.');
    }
  }

  Future<void> claimReward(String rewardId) async {
    try {
      await _client.dio.post(ApiConstants.claimReward(rewardId));
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal menukarkan hadiah.');
    }
  }
}
