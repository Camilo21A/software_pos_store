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

    final token     = respuesta.data['token'] as String;
    final esAdmin   = respuesta.data['es_admin'] as bool;

    // Guarda token Y es_admin para recuperarlos sin llamar al backend
    await _storage.write(key: 'token',    value: token);
    await _storage.write(key: 'es_admin', value: esAdmin.toString());

    return SesionUsuario(
      token:   token,
      esAdmin: esAdmin,
      tienda:  respuesta.data['tienda'] != null
          ? ModeloTienda.fromJson(respuesta.data['tienda'])
          : null,
    );
  }

  Future<void> logout() async {
    final token = await _storage.read(key: 'token');
    await ClienteHttp.dio.post(
      '/auth/logout/',
      options: Options(headers: {'Authorization': 'Token $token'}),
    );
    // Borra todo lo guardado
    await _storage.delete(key: 'token');
    await _storage.delete(key: 'es_admin');
  }

  Future<bool> haySesionActiva() async {
    final token = await _storage.read(key: 'token');
    return token != null;
  }

  Future<String?> obtenerToken() async {
    return await _storage.read(key: 'token');
  }

  // ← método nuevo que necesita PantallaPrincipal
  Future<SesionUsuario?> obtenerSesionActual() async {
    final token   = await _storage.read(key: 'token');
    final esAdmin = await _storage.read(key: 'es_admin');

    if (token == null) return null;

    return SesionUsuario(
      token:   token,
      esAdmin: esAdmin == 'true',
      tienda:  null, // no es necesario para esta pantalla
    );
  }
}