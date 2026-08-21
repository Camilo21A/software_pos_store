import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../nucleo/red/cliente_http.dart';
import 'modelo_usuario.dart';

class RepositorioAuth {
  final _storage = const FlutterSecureStorage();

  Future<SesionUsuario> login(String username, String password) async {
    final respuesta = await ClienteHttp.dio.post('/auth/login/', data: {
      'username': username,
      'password': password,
    });

    final token = respuesta.data['token'];
    await _storage.write(key: 'token', value: token);

    return SesionUsuario(
      token: token,
      esAdmin: respuesta.data['es_admin'],
      tienda: respuesta.data['tienda'] != null
          ? ModeloTienda.fromJson(respuesta.data['tienda'])
          : null,
    );
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'token');
    await ClienteHttp.dio.post('/auth/logout/',
        options: Options(headers: {'Authorization': 'Token $token'}));
    await _storage.delete(key: 'token');
  }

  Future<bool> haySesionActiva() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }
}