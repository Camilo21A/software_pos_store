import 'package:dio/dio.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/datos/repositorio_auth.dart';
import 'modelo_venta.dart';

class RepositorioVentas {
  final Dio _dio = ClienteHttp.dio;

  Future<Options> _opciones() async {
    final token = await RepositorioAuth().obtenerToken();
    return Options(headers: {'Authorization': 'Token $token'});
  }

  Future<List<ModeloVenta>> obtenerVentas({
    String? estado,
    String? metodoPago,
    String? fechaDesde,
    String? fechaHasta,
  }) async {
    final params = <String, dynamic>{};
    if (estado != null)      params['estado']       = estado;
    if (metodoPago != null)  params['metodo_pago']  = metodoPago;
    if (fechaDesde != null)  params['fecha_desde']  = fechaDesde;
    if (fechaHasta != null)  params['fecha_hasta']  = fechaHasta;

    final r = await _dio.get(
      '/ventas/',
      queryParameters: params,
      options: await _opciones(),
    );
    return (r.data as List).map((j) => ModeloVenta.fromJson(j)).toList();
  }

  Future<ModeloVenta> crearVenta({
    required String metodoPago,
    required List<ModeloVentaItem> items,
    bool fuePorVoz = false,
  }) async {
    final r = await _dio.post(
      '/ventas/',
      data: {
        'metodo_pago': metodoPago,
        'total':       0,
        'fue_por_voz': fuePorVoz,
        'items':       items.map((i) => i.toJson()).toList(),
      },
      options: await _opciones(),
    );
    return ModeloVenta.fromJson(r.data);
  }

  Future<ModeloVenta> anularVenta(int id, String motivo) async {
    final r = await _dio.patch(
      '/ventas/$id/anular/',
      data: {'motivo': motivo},
      options: await _opciones(),
    );
    return ModeloVenta.fromJson(r.data);
  }
}