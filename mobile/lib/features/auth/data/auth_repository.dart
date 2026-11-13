import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _client;
  final StorageService _storage;

  AuthRepository(this._client, this._storage);

  Future<UserModel> login(String email, String password) async {
    try {
      final response = await _client.dio.post(
        ApiConstants.login,
        data: {'email': email, 'password': password},
      );

      final data = response.data as Map<String, dynamic>;
      final token = data['token'] as String;
      final user = UserModel.fromJson(data);

      await _storage.saveToken(token);
      await _storage.saveUser(user.toJson());

      return user;
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? 'Gagal masuk. Periksa kembali email dan password.';
      throw Exception(msg);
    }
  }

  Future<List<Map<String, dynamic>>> getQuickUsers() async {
    try {
      final response = await _client.dio.get('/auth/quick-users');
      final list = response.data as List<dynamic>;
      return list.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }

  Future<UserModel?> getCachedUser() async {
    final map = await _storage.getUser();
    if (map == null) return null;
    return UserModel.fromJson(map);
  }

  Future<void> logout() async {
    await _storage.clearAll();
  }
}
