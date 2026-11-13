class ModeloVentaItem {
  final int? idItem;
  final int idProducto;
  final String? productoNombre;
  final int cantidad;
  final double? precioUnitario;
  final double? subtotal;

  ModeloVentaItem({
    this.idItem,
    required this.idProducto,
    this.productoNombre,
    required this.cantidad,
    this.precioUnitario,
    this.subtotal,
  });

  factory ModeloVentaItem.fromJson(Map<String, dynamic> json) {
    return ModeloVentaItem(
      idItem:          json['id_item'],
      idProducto:      json['id_producto'],
      productoNombre:  json['producto_nombre'],
      cantidad:        json['cantidad'],
      precioUnitario:  json['precio_unitario'] != null
          ? double.parse(json['precio_unitario'].toString())
          : null,
      subtotal:        json['subtotal'] != null
          ? double.parse(json['subtotal'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'id_producto': idProducto,
    'cantidad':    cantidad,
  };
}

class ModeloVenta {
  final int idVenta;
  final String fechaHora;
  final double total;
  final String metodoPago;
  final bool fuePorVoz;
  final String estado;
  final String? motivoAnulacion;
  final List<ModeloVentaItem> items;

  ModeloVenta({
    required this.idVenta,
    required this.fechaHora,
    required this.total,
    required this.metodoPago,
    required this.fuePorVoz,
    required this.estado,
    this.motivoAnulacion,
    required this.items,
  });

  factory ModeloVenta.fromJson(Map<String, dynamic> json) {
    return ModeloVenta(
      idVenta:         json['id_venta'],
      fechaHora:       json['fecha_hora'],
      total:           double.parse(json['total'].toString()),
      metodoPago:      json['metodo_pago'],
      fuePorVoz:       json['fue_por_voz'],
      estado:          json['estado'],
      motivoAnulacion: json['motivo_anulacion'],
      items:           (json['items'] as List)
          .map((i) => ModeloVentaItem.fromJson(i))
          .toList(),
    );
  }

  bool get estaAnulada => estado == 'anulada';
}