import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../models/auth/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient dioClient;
  final SharedPreferences prefs;

  AuthRepositoryImpl({required this.dioClient, required this.prefs});

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      final response = await dioClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 201) {
        final token = response.data['token'];
        final userData = response.data['user'];

        // Save Token
        await prefs.setString(AppConstants.tokenKey, token);
        
        // Save User Data
        await prefs.setString(AppConstants.userDataKey, json.encode(userData));

        return UserModel.fromJson(userData);
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Error de conexión');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post('/logout');
    } finally {
      await prefs.remove(AppConstants.tokenKey);
      await prefs.remove(AppConstants.userDataKey);
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    final userDataString = prefs.getString(AppConstants.userDataKey);
    if (userDataString != null) {
      return UserModel.fromJson(json.decode(userDataString));
    }
    return null;
  }
}
