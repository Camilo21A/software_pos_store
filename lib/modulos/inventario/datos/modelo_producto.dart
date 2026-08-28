class ModeloCategoria {
  final int idCategoria;
  final String nombre;
  final bool activo;

  ModeloCategoria({
    required this.idCategoria,
    required this.nombre,
    required this.activo,
  });

  factory ModeloCategoria.fromJson(Map<String, dynamic> json) {
    return ModeloCategoria(
      idCategoria: json['id_categoria'],
      nombre:      json['nombre'],
      activo:      json['activo'],
    );
  }

  Map<String, dynamic> toJson() => {'nombre': nombre};
}

class ModeloProducto {
  final int idProducto;
  final String nombre;
  final List<String> sinonimos;
  final String? codigoBarras;
  final double precioVenta;
  final double? precioCompra;
  final int stockActual;
  final int stockMinimo;
  final String? fotoUrl;
  final bool activo;
  final int? idCategoria;
  final String? categoriaNombre;

  ModeloProducto({
    required this.idProducto,
    required this.nombre,
    required this.sinonimos,
    this.codigoBarras,
    required this.precioVenta,
    this.precioCompra,
    required this.stockActual,
    required this.stockMinimo,
    this.fotoUrl,
    required this.activo,
    this.idCategoria,
    this.categoriaNombre,
  });

  factory ModeloProducto.fromJson(Map<String, dynamic> json) {
    return ModeloProducto(
      idProducto:      json['id_producto'],
      nombre:          json['nombre'],
      sinonimos:       List<String>.from(json['sinonimos'] ?? []),
      codigoBarras:    json['codigo_barras'],
      precioVenta:     double.parse(json['precio_venta'].toString()),
      precioCompra:    json['precio_compra'] != null
          ? double.parse(json['precio_compra'].toString())
          : null,
      stockActual:     json['stock_actual'],
      stockMinimo:     json['stock_minimo'],
      fotoUrl:         json['foto_url'],
      activo:          json['activo'],
      idCategoria:     json['id_categoria'],
      categoriaNombre: json['categoria_nombre'],
    );
  }

  bool get stockBajo => stockActual <= stockMinimo;
}