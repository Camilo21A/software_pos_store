// lib/modulos/autenticacion/vistas/pantalla_admin_tiendas.dart
import 'package:flutter/material.dart';
import '../datos/modelo_tienda.dart';
import '../datos/repositorio_admin.dart';

class PantallaAdminTiendas extends StatefulWidget {
  const PantallaAdminTiendas({super.key});

  @override
  State<PantallaAdminTiendas> createState() => _PantallaAdminTiendasState();
}

class _PantallaAdminTiendasState extends State<PantallaAdminTiendas> {
  final RepositorioAdmin _repo = RepositorioAdmin();
  late Future<List<ModeloTienda>> _futureTiendas;

  @override
  void initState() {
    super.initState();
    _cargarTiendas();
  }

  void _cargarTiendas() {
    setState(() {
      _futureTiendas = _repo.obtenerTiendas();
    });
  }

  Future<void> _toggleTienda(ModeloTienda tienda) async {
    final accion = tienda.activa ? 'desactivar' : 'activar';

    // Pide confirmación antes de cambiar el estado
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿${accion[0].toUpperCase()}${accion.substring(1)} tienda?'),
        content: Text(
          'Vas a $accion "${tienda.nombre}".\n'
              '${tienda.activa ? 'La tienda no podrá registrar nuevas ventas.' : 'La tienda podrá operar normalmente.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: tienda.activa
                ? FilledButton.styleFrom(backgroundColor: Colors.red)
                : null,
            child: Text(accion[0].toUpperCase() + accion.substring(1)),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _repo.toggleTienda(tienda.id);
      _cargarTiendas(); // recarga la lista completa
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Tienda "${tienda.nombre}" ${tienda.activa ? 'desactivada' : 'activada'}'),
            backgroundColor: tienda.activa ? Colors.orange : Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al $accion la tienda: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administración de tiendas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Recargar',
            onPressed: _cargarTiendas,
          ),
        ],
      ),
      body: FutureBuilder<List<ModeloTienda>>(
        future: _futureTiendas,
        builder: (context, snapshot) {

          // Cargando
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('Error al cargar tiendas:\n${snapshot.error}',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _cargarTiendas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          final tiendas = snapshot.data ?? [];

          // Sin tiendas
          if (tiendas.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.store_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No hay tiendas registradas',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          // Lista de tiendas
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: tiendas.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final tienda = tiendas[index];
              return _TarjetaTienda(
                tienda: tienda,
                onToggle: () => _toggleTienda(tienda),
              );
            },
          );
        },
      ),
    );
  }
}

// Widget separado para cada tarjeta de tienda
class _TarjetaTienda extends StatelessWidget {
  final ModeloTienda tienda;
  final VoidCallback onToggle;

  const _TarjetaTienda({required this.tienda, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: tienda.activa
              ? Colors.green.withOpacity(0.4)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: tienda.activa
              ? Colors.green.withOpacity(0.15)
              : Colors.red.withOpacity(0.1),
          child: Icon(
            Icons.store,
            color: tienda.activa ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          tienda.nombre,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tienda.direccion != null && tienda.direccion!.isNotEmpty)
              Text(tienda.direccion!,
                  style: const TextStyle(fontSize: 12)),
            if (tienda.telefono != null && tienda.telefono!.isNotEmpty)
              Text(tienda.telefono!,
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: tienda.activa
                    ? Colors.green.withOpacity(0.1)
                    : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                tienda.activa ? 'Activa' : 'Desactivada',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: tienda.activa ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        trailing: Switch(
          value: tienda.activa,
          activeColor: Colors.green,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}