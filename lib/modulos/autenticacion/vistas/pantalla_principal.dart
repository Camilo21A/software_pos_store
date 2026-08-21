import 'package:flutter/material.dart';
import '../datos/repositorio_auth.dart';
import 'pantalla_login.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final _repositorio = RepositorioAuth();
  bool _cerrandoSesion = false;

  Future<void> _cerrarSesion() async {
    setState(() => _cerrandoSesion = true);

    await _repositorio.logout();

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PantallaLogin()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel principal'),
        actions: [
          _cerrandoSesion
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: _cerrarSesion,
          ),
        ],
      ),
      // TODO (RF-09): reemplazar este cuerpo por el dashboard real
      // (ventas del día, transacciones, producto más vendido, alertas de stock).
      body: const Center(
        child: Text(
          'Bienvenido. Aquí irá el dashboard (RF-09).',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}