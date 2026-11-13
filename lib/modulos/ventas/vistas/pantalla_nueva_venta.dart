import 'package:flutter/material.dart';
import '../../inventario/datos/modelo_producto.dart';
import '../../inventario/datos/repositorio_inventario.dart';
import '../datos/modelo_venta.dart';
import '../datos/repositorio_ventas.dart';

class PantallaNuevaVenta extends StatefulWidget {
  const PantallaNuevaVenta({super.key});

  @override
  State<PantallaNuevaVenta> createState() => _PantallaNuevaVentaState();
}

class _PantallaNuevaVentaState extends State<PantallaNuevaVenta> {
  final _repoInventario = RepositorioInventario();
  final _repoVentas     = RepositorioVentas();
  final _busqueda       = TextEditingController();

  List<ModeloProducto> _productos  = [];
  List<ModeloProducto> _filtrados  = [];
  final List<_ItemCarrito> _carrito = [];
  String _metodoPago = 'efectivo';
  bool _cargando     = true;
  bool _cobrando     = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  Future<void> _cargarProductos() async {
    try {
      final lista = await _repoInventario.obtenerProductos();
      lista.sort((a, b) =>
          a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
      if (!mounted) return;
      setState(() {
        _productos = lista;
        _filtrados = lista;
        _cargando  = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al cargar productos: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _filtrarProductos(String texto) {
    final t = texto.toLowerCase();
    setState(() {
      _filtrados = t.isEmpty
          ? _productos
          : _productos
              .where((p) =>
                  p.nombre.toLowerCase().contains(t) ||
                  p.sinonimos.any((s) => s.toLowerCase().contains(t)))
              .toList();
    });
  }

  int _cantidadEnCarrito(int idProducto) {
    final i = _carrito.indexWhere((c) => c.producto.idProducto == idProducto);
    return i >= 0 ? _carrito[i].cantidad : 0;
  }

  void _agregarAlCarrito(ModeloProducto producto) {
    final enCarrito = _cantidadEnCarrito(producto.idProducto);
    if (enCarrito >= producto.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Solo hay ${producto.stockActual} de "${producto.nombre}"'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() {
      final index = _carrito
          .indexWhere((i) => i.producto.idProducto == producto.idProducto);
      if (index >= 0) {
        _carrito[index].cantidad++;
      } else {
        _carrito.add(_ItemCarrito(producto: producto, cantidad: 1));
      }
    });
  }

  void _cambiarCantidad(int index, int delta) {
    final item = _carrito[index];
    if (delta > 0 && item.cantidad >= item.producto.stockActual) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Solo hay ${item.producto.stockActual} en stock'),
        backgroundColor: Colors.orange,
      ));
      return;
    }
    setState(() {
      item.cantidad += delta;
      if (item.cantidad <= 0) _carrito.removeAt(index);
    });
  }

  double get _total => _carrito.fold(
      0, (sum, i) => sum + (i.producto.precioVenta * i.cantidad));

  int get _unidades => _carrito.fold(0, (sum, i) => sum + i.cantidad);

  Future<void> _cobrar() async {
    if (_carrito.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Agrega productos al carrito primero'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    // Se guardan antes de cobrar, porque el carrito cambia después
    final totalCobrado = _total;
    final unidades     = _unidades;
    final metodo       = _metodoPago[0].toUpperCase() + _metodoPago.substring(1);

    setState(() => _cobrando = true);

    try {
      await _repoVentas.crearVenta(
        metodoPago: _metodoPago,
        items: _carrito
            .map((i) => ModeloVentaItem(
                  idProducto: i.producto.idProducto,
                  cantidad:   i.cantidad,
                ))
            .toList(),
      );

      if (!mounted) return;

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text('Venta registrada'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\$${totalCobrado.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('$unidades unidades · $metodo',
                  style: const TextStyle(color: Colors.grey)),
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Listo'),
            ),
          ],
        ),
      );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _cobrando = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al registrar venta: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva venta'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: DropdownButton<String>(
              value: _metodoPago,
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: 'efectivo',      child: Text('Efectivo')),
                DropdownMenuItem(value: 'nequi',         child: Text('Nequi')),
                DropdownMenuItem(value: 'daviplata',     child: Text('Daviplata')),
                DropdownMenuItem(value: 'transferencia', child: Text('Transferencia')),
                DropdownMenuItem(value: 'otro',          child: Text('Otro')),
              ],
              onChanged: (v) => setState(() => _metodoPago = v!),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Búsqueda
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _busqueda,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                suffixIcon: _busqueda.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _busqueda.clear();
                          _filtrarProductos('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filtrarProductos,
            ),
          ),

          // Productos (siempre visibles)
          Expanded(
            flex: 3,
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _filtrados.isEmpty
                    ? const Center(child: Text('No se encontraron productos'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _filtrados.length,
                        itemBuilder: (_, i) {
                          final p = _filtrados[i];
                          final sinStock = p.stockActual <= 0;
                          final enCarrito = _cantidadEnCarrito(p.idProducto);
                          return ListTile(
                            enabled: !sinStock,
                            contentPadding: EdgeInsets.zero,
                            dense: true,
                            title: Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text(
                              sinStock
                                  ? 'Sin stock'
                                  : '\$${p.precioVenta.toStringAsFixed(0)}  ·  Stock: ${p.stockActual}',
                              style: TextStyle(
                                  color: sinStock ? Colors.red : null),
                            ),
                            trailing: enCarrito > 0
                                ? CircleAvatar(
                                    radius: 12,
                                    child: Text('$enCarrito',
                                        style: const TextStyle(fontSize: 12)),
                                  )
                                : Icon(Icons.add_circle,
                                    color: sinStock ? Colors.grey : Colors.blue),
                            onTap: sinStock ? null : () => _agregarAlCarrito(p),
                          );
                        },
                      ),
          ),

          // Carrito
          Container(
            width: double.infinity,
            color: Colors.grey.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('Carrito ($_unidades)',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 2,
            child: _carrito.isEmpty
                ? const Center(
                    child: Text('Toca un producto para agregarlo',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _carrito.length,
                    itemBuilder: (_, i) {
                      final item = _carrito[i];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        title: Text(item.producto.nombre),
                        subtitle: Text(
                            '\$${(item.producto.precioVenta * item.cantidad).toStringAsFixed(0)}'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed: () => _cambiarCantidad(i, -1),
                            ),
                            Text('${item.cantidad}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed: () => _cambiarCantidad(i, 1),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Total y cobrar
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.3))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _metodoPago[0].toUpperCase() +
                              _metodoPago.substring(1),
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                        Text('\$${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    icon: _cobrando
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.check),
                    label: const Text('Cobrar'),
                    onPressed: _cobrando ? null : _cobrar,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemCarrito {
  final ModeloProducto producto;
  int cantidad;
  _ItemCarrito({required this.producto, required this.cantidad});
}