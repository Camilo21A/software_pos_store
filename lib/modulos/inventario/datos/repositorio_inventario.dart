import 'package:dio/dio.dart';
import '../../../nucleo/red/cliente_http.dart';
import '../../autenticacion/datos/repositorio_auth.dart';
import 'modelo_producto.dart';

class RepositorioInventario {
  final Dio _dio = ClienteHttp.dio;

  Future<Options> _opciones() async {
    final token = await RepositorioAuth().obtenerToken();
    return Options(headers: {'Authorization': 'Token $token'});
  }

  // ── Categorías ──────────────────────────────────────
  Future<List<ModeloCategoria>> obtenerCategorias() async {
    final r = await _dio.get('/inventario/categorias/', options: await _opciones());
    return (r.data as List).map((j) => ModeloCategoria.fromJson(j)).toList();
  }

  Future<ModeloCategoria> crearCategoria(String nombre) async {
    final r = await _dio.post(
      '/inventario/categorias/',
      data: {'nombre': nombre},
      options: await _opciones(),
    );
    return ModeloCategoria.fromJson(r.data);
  }

  // ── Productos ───────────────────────────────────────
  Future<List<ModeloProducto>> obtenerProductos({
    String? nombre,
    int? categoria,
    bool soloArchivados = false,
  }) async {
    final params = <String, dynamic>{};
    if (nombre != null)    params['nombre']    = nombre;
    if (categoria != null) params['categoria'] = categoria;
    params['activo'] = soloArchivados ? 'false' : 'true';

    final r = await _dio.get(
      '/inventario/productos/',
      queryParameters: params,
      options: await _opciones(),
    );
    return (r.data as List).map((j) => ModeloProducto.fromJson(j)).toList();
  }

  Future<ModeloProducto> crearProducto(Map<String, dynamic> datos) async {
    final r = await _dio.post(
      '/inventario/productos/',
      data: datos,
      options: await _opciones(),
    );
    return ModeloProducto.fromJson(r.data);
  }

  Future<ModeloProducto> actualizarProducto(int id, Map<String, dynamic> datos) async {
    final r = await _dio.patch(
      '/inventario/productos/$id/',
      data: datos,
      options: await _opciones(),
    );
    return ModeloProducto.fromJson(r.data);
  }

  Future<void> archivarProducto(int id) async {
    await _dio.delete(
      '/inventario/productos/$id/',
      options: await _opciones(),
    );
  }
}