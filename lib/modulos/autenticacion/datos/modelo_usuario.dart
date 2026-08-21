class ModeloTienda {
  final int id;
  final String nombre;
  final bool activa;

  ModeloTienda({required this.id, required this.nombre, required this.activa});

  factory ModeloTienda.fromJson(Map<String, dynamic> json) => ModeloTienda(
    id: json['id'],
    nombre: json['nombre'],
    activa: json['activa'],
  );
}

class SesionUsuario {
  final String token;
  final bool esAdmin;
  final ModeloTienda? tienda;

  SesionUsuario({required this.token, required this.esAdmin, this.tienda});
}