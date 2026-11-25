class ModeloEntradaItem {
  final int idProducto;
  final String? productoNombre;
  final int cantidad;
  final double? costoUnit;

  ModeloEntradaItem({
    required this.idProducto,
    this.productoNombre,
    required this.cantidad,
    this.costoUnit,
  });

  factory ModeloEntradaItem.fromJson(Map<String, dynamic> json) {
    return ModeloEntradaItem(
      idProducto:     json['id_producto'],
      productoNombre: json['producto_nombre'],
      cantidad:       json['cantidad'],
      costoUnit: json['costo_unit'] != null
          ? double.parse(json['costo_unit'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id_producto': idProducto,
        'cantidad':    cantidad,
        if (costoUnit != null) 'costo_unit': costoUnit,
      };
}

class ModeloEntrada {
  final int idEntrada;
  final String fechaHora;
  final double total;
  final String? notas;
  final List<ModeloEntradaItem> items;

  ModeloEntrada({
    required this.idEntrada,
    required this.fechaHora,
    required this.total,
    this.notas,
    required this.items,
  });

  factory ModeloEntrada.fromJson(Map<String, dynamic> json) {
    return ModeloEntrada(
      idEntrada: json['id_entrada'],
      fechaHora: json['fecha_hora'],
      total: double.parse((json['total'] ?? '0').toString()),
      notas: json['notas'],
      items: (json['items'] as List)
          .map((i) => ModeloEntradaItem.fromJson(i))
          .toList(),
    );
  }
}