import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sistema_control_agua/core/constants/app_constants.dart';
import 'package:sistema_control_agua/core/network/dio_client.dart';
import 'package:sistema_control_agua/domain/entities/user_entity.dart';
import 'package:sistema_control_agua/domain/repositories/auth_repository.dart';
import 'package:sistema_control_agua/data/models/auth/user_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DioClient dioClient;
  final SharedPreferences prefs;

  AuthRepositoryImpl({required this.dioClient, required this.prefs});

  @override
  Future<UserEntity?> login(String email, String password) async {
    try {
      print('AuthRepository: Intentando login en ${dioClient.dio.options.baseUrl}/login');
      final response = await dioClient.dio.post('/login', data: {
        'email': email,
        'password': password,
      });

      print('AuthRepository: Respuesta recibida [${response.statusCode}]');
      
      final dynamic data = response.data;
      if (data is String) {
        print('AuthRepository: ERROR - La respuesta es un String (no se parseó automáticamente). Contenido: $data');
        // Aquí podrías intentar json.decode(data) si realmente es un JSON en String
        return null;
      }
      
      if (data is! Map) {
        print('AuthRepository: ERROR - La respuesta no es un Map. Tipo: ${data.runtimeType}');
        return null;
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final token = data['token'];
        final userData = data['user'];

        print('AuthRepository: Persistiendo token y datos de usuario');
        await prefs.setString(AppConstants.tokenKey, token);
        await prefs.setString(AppConstants.userDataKey, json.encode(userData));

        return UserModel.fromJson(userData);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        throw Exception(e.response?.data['message'] ?? 'Error de conexión');
      }
      throw Exception('Error del servidor (${e.response?.statusCode ?? "Error de conexión"})');
    }
  }

  @override
  Future<void> logout() async {
    try {
      await dioClient.dio.post('/logout');
    } catch (_) {
      // Ignorar errores en logout (como 401 si ya se reseteó la DB)
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
