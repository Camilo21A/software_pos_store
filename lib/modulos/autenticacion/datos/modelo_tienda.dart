// lib/modulos/autenticacion/datos/modelo_tienda.dart
class ModeloTienda {
  final int id;
  final String nombre;
  final String? direccion;
  final String? telefono;
  final bool activa;

  ModeloTienda({
    required this.id,
    required this.nombre,
    this.direccion,
    this.telefono,
    required this.activa,
  });

  factory ModeloTienda.fromJson(Map<String, dynamic> json) {
    return ModeloTienda(
      id:        json['id'],
      nombre:    json['nombre'],
      direccion: json['direccion'],
      telefono:  json['telefono'],
      activa:    json['activa'],
    );
  }
}