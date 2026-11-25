import 'package:dio/dio.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/datos/repositorio_auth.dart';
import 'modelo_entrada.dart';

class RepositorioEntradas {
  final Dio _dio = ClienteHttp.dio;

  Future<Options> _opciones() async {
    final token = await RepositorioAuth().obtenerToken();
    return Options(headers: {'Authorization': 'Token $token'});
  }

  Future<List<ModeloEntrada>> obtenerEntradas() async {
    final r = await _dio.get('/inventario/entradas/',
        options: await _opciones());
    return (r.data as List).map((j) => ModeloEntrada.fromJson(j)).toList();
  }

  Future<ModeloEntrada> crearEntrada({
    String? notas,
    required List<ModeloEntradaItem> items,
  }) async {
    final r = await _dio.post(
      '/inventario/entradas/',
      data: {
        if (notas != null && notas.isNotEmpty) 'notas': notas,
        'items': items.map((i) => i.toJson()).toList(),
      },
      options: await _opciones(),
    );
    return ModeloEntrada.fromJson(r.data);
  }
}