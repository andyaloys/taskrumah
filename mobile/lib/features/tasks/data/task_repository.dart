import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/task_assignment_model.dart';

class TaskRepository {
  final ApiClient _client;

  TaskRepository(this._client);

  Future<List<TaskAssignmentModel>> getSchedule(String dateYmd) async {
    try {
      final response = await _client.dio.get(
        ApiConstants.taskSchedule,
        queryParameters: {'date': dateYmd},
      );
      final list = response.data as List<dynamic>;
      return list.map((e) => TaskAssignmentModel.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal memuat jadwal tugas.');
    }
  }

  Future<TaskAssignmentModel> submitTask(String id, {String? note, File? photo}) async {
    try {
      final formData = FormData();
      if (note != null && note.isNotEmpty) {
        formData.fields.add(MapEntry('submissionNote', note));
      }
      if (photo != null) {
        final filename = photo.path.split('/').last.split('\\').last;
        formData.files.add(
          MapEntry(
            'photo',
            await MultipartFile.fromFile(photo.path, filename: filename),
          ),
        );
      }

      final response = await _client.dio.post(
        ApiConstants.submitTask(id),
        data: formData,
      );

      return TaskAssignmentModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Gagal mengirim bukti tugas.');
    }
  }
}
