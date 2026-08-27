import 'package:flutter/material.dart';
import '../datos/modelo_producto.dart';
import '../datos/repositorio_inventario.dart';
import 'pantalla_formulario_producto.dart';

class PantallaInventario extends StatefulWidget {
  final bool soloArchivados; // ← parámetro nuevo
  const PantallaInventario({super.key, this.soloArchivados = false});

  @override
  State<PantallaInventario> createState() => _PantallaInventarioState();
}

class _PantallaInventarioState extends State<PantallaInventario> {
  final _repo     = RepositorioInventario();
  final _busqueda = TextEditingController();
  List<ModeloProducto> _productos = [];
  bool _cargando  = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  Future<void> _cargarProductos({String? nombre}) async {
    setState(() { _cargando = true; _error = null; });
    try {
      final lista = await _repo.obtenerProductos(
        nombre: nombre,
        soloArchivados: widget.soloArchivados, // ← usa el parámetro
      );
      setState(() { _productos = lista; _cargando = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _cargando = false; });
    }
  }

  Future<void> _archivarProducto(ModeloProducto p) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Archivar producto?'),
        content: Text('Se archivará "${p.nombre}". No aparecerá en ventas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Archivar'),
          ),
        ],
      ),
    );
    if (confirmar != true) return;
    await _repo.archivarProducto(p.idProducto);
    _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.soloArchivados ? 'Productos archivados' : 'Inventario'),
        actions: [
          // Solo muestra el botón de archivados cuando estamos en la vista normal
          if (!widget.soloArchivados)
            IconButton(
              icon: const Icon(Icons.archive_outlined),
              tooltip: 'Ver archivados',
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PantallaInventario(soloArchivados: true),
                  ),
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _cargarProductos(),
          ),
        ],
      ),
      floatingActionButton: widget.soloArchivados
          ? null // sin botón en vista archivados
          : FloatingActionButton.extended(
        icon: const Icon(Icons.add),
        label: const Text('Nuevo producto'),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PantallaFormularioProducto(),
            ),
          );
          _cargarProductos();
        },
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _busqueda,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _busqueda.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _busqueda.clear();
                    _cargarProductos();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (v) => _cargarProductos(nombre: v.isEmpty ? null : v),
            ),
          ),
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text('Error: $_error'))
                : _productos.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.soloArchivados
                        ? Icons.archive_outlined
                        : Icons.inventory_2_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.soloArchivados
                        ? 'No hay productos archivados'
                        : 'No hay productos',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
                : ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
              itemCount: _productos.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _TarjetaProducto(
                producto: _productos[i],
                soloArchivados: widget.soloArchivados,
                onEditar: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PantallaFormularioProducto(
                        producto: _productos[i],
                      ),
                    ),
                  );
                  _cargarProductos();
                },
                onArchivar: () => _archivarProducto(_productos[i]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaProducto extends StatelessWidget {
  final ModeloProducto producto;
  final bool soloArchivados;
  final VoidCallback onEditar;
  final VoidCallback onArchivar;

  const _TarjetaProducto({
    required this.producto,
    required this.soloArchivados,
    required this.onEditar,
    required this.onArchivar,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: soloArchivados
              ? Colors.grey.withOpacity(0.3)
              : producto.stockBajo
              ? Colors.orange.withOpacity(0.6)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: soloArchivados
              ? Colors.grey.withOpacity(0.1)
              : producto.stockBajo
              ? Colors.orange.withOpacity(0.15)
              : Colors.blue.withOpacity(0.1),
          child: Icon(
            soloArchivados ? Icons.archive : Icons.inventory_2,
            color: soloArchivados
                ? Colors.grey
                : producto.stockBajo
                ? Colors.orange
                : Colors.blue,
          ),
        ),
        title: Text(
          producto.nombre,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: soloArchivados ? Colors.grey : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (producto.categoriaNombre != null)
              Text(producto.categoriaNombre!,
                  style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Row(
              children: [
                _Chip(
                  'Venta: \$${producto.precioVenta.toStringAsFixed(0)}',
                  soloArchivados ? Colors.grey : Colors.green,
                ),
                const SizedBox(width: 6),
                _Chip(
                  'Stock: ${producto.stockActual}',
                  soloArchivados
                      ? Colors.grey
                      : producto.stockBajo
                      ? Colors.orange
                      : Colors.blue,
                ),
              ],
            ),
            if (producto.stockBajo && !soloArchivados)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('⚠ Stock bajo',
                    style: TextStyle(fontSize: 11, color: Colors.orange)),
              ),
          ],
        ),
        // En archivados no se muestra menú de opciones
        trailing: soloArchivados
            ? null
            : PopupMenuButton(
          itemBuilder: (_) => [
            const PopupMenuItem(value: 'editar', child: Text('Editar')),
            const PopupMenuItem(value: 'archivar', child: Text('Archivar')),
          ],
          onSelected: (v) {
            if (v == 'editar') onEditar();
            if (v == 'archivar') onArchivar();
          },
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  const _Chip(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}