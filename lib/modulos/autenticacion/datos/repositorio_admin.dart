// lib/modulos/autenticacion/datos/repositorio_admin.dart
import 'package:dio/dio.dart';

import '../../../nucleo/constantes/constantes_api.dart';
import '../../../nucleo/red/cliente_http.dart';
import 'modelo_tienda.dart';
import 'repositorio_auth.dart';

class RepositorioAdmin {
  final Dio _dio = ClienteHttp.dio;

  // Obtiene el token guardado y lo pone en el header
  Future<Options> _opcionesConToken() async {
    final token = await RepositorioAuth().obtenerToken();
    return Options(headers: {'Authorization': 'Token $token'});
  }

  // Trae la lista de todas las tiendas
  Future<List<ModeloTienda>> obtenerTiendas() async {
    final opciones = await _opcionesConToken();
    final respuesta = await _dio.get(
      ConstantesApi.tiendasUrl,
      options: opciones,
    );
    final List lista = respuesta.data;
    return lista.map((json) => ModeloTienda.fromJson(json)).toList();
  }

  // Activa o desactiva una tienda
  Future<bool> toggleTienda(int id) async {
    final opciones = await _opcionesConToken();
    final respuesta = await _dio.patch(
      ConstantesApi.toggleTiendaUrl(id),
      options: opciones,
    );
    return respuesta.data['activa'];
  }
}
