import 'package:flutter/material.dart';
import '../datos/repositorio_auth.dart';
import '../datos/modelo_usuario.dart';
import 'pantalla_login.dart';
import 'pantalla_admin_tiendas.dart';
import '../../inventario/vistas/pantalla_inventario.dart';

class PantallaPrincipal extends StatefulWidget {
  const PantallaPrincipal({super.key});

  @override
  State<PantallaPrincipal> createState() => _PantallaPrincipalState();
}

class _PantallaPrincipalState extends State<PantallaPrincipal> {
  final _repositorio = RepositorioAuth();
  bool _cerrandoSesion = false;
  SesionUsuario? _sesion; // ← viene del backend, no hardcodeado

  @override
  void initState() {
    super.initState();
    _cargarSesion();
  }

  Future<void> _cargarSesion() async {
    final sesion = await _repositorio.obtenerSesionActual();
    if (mounted) {
      setState(() => _sesion = sesion);
    }
  }

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
    // Mientras carga la sesión muestra un loader
    if (_sesion == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Solo aparece si es admin real
            if (_sesion!.esAdmin) ...[
              ElevatedButton.icon(
                icon: const Icon(Icons.store),
                label: const Text('Administrar tiendas'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PantallaAdminTiendas(),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            ElevatedButton.icon(
              icon: const Icon(Icons.inventory_2),
              label: const Text('Inventario'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PantallaInventario()),
              ),
            ),
            const SizedBox(height: 12),
            
            const Text(
              'Bienvenido. Aquí irá el dashboard (RF-09).',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}