import 'package:flutter/material.dart';
import '../datos/modelo_entrada.dart';
import '../datos/modelo_producto.dart';
import '../datos/repositorio_entradas.dart';
import '../datos/repositorio_inventario.dart';
import 'pantalla_historial_entradas.dart';

class PantallaNuevaEntrada extends StatefulWidget {
  const PantallaNuevaEntrada({super.key});

  @override
  State<PantallaNuevaEntrada> createState() => _PantallaNuevaEntradaState();
}

class _PantallaNuevaEntradaState extends State<PantallaNuevaEntrada> {
  final _repoInventario = RepositorioInventario();
  final _repoEntradas   = RepositorioEntradas();
  final _busqueda       = TextEditingController();
  final _notas          = TextEditingController();

  List<ModeloProducto> _productos = [];
  List<ModeloProducto> _filtrados = [];
  final List<_ItemEntrada> _items = [];
  bool _cargando = true;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _cargarProductos();
  }

  @override
  void dispose() {
    _busqueda.dispose();
    _notas.dispose();
    for (final i in _items) {
      i.costo.dispose();
    }
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
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _cargando = false);
      _mensaje('Error al cargar productos: $e', Colors.red);
    }
  }

  void _mensaje(String texto, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), backgroundColor: color),
    );
  }

  void _filtrar(String texto) {
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

  void _agregar(ModeloProducto p) {
    final index = _items.indexWhere((i) => i.producto.idProducto == p.idProducto);
    setState(() {
      if (index >= 0) {
        _items[index].cantidad++;
      } else {
        _items.add(_ItemEntrada(
          producto: p,
          cantidad: 1,
          costo: TextEditingController(
            text: (p.precioCompra ?? 0).toStringAsFixed(0),
          ),
        ));
      }
    });
  }

  void _cambiarCantidad(int index, int delta) {
    setState(() {
      _items[index].cantidad += delta;
      if (_items[index].cantidad <= 0) {
        _items[index].costo.dispose();
        _items.removeAt(index);
      }
    });
  }

  double get _total =>
      _items.fold(0, (sum, i) => sum + (i.costoValor * i.cantidad));

  Future<void> _registrar() async {
    if (_items.isEmpty) {
      _mensaje('Agrega al menos un producto', Colors.orange);
      return;
    }

    setState(() => _guardando = true);
    try {
      await _repoEntradas.crearEntrada(
        notas: _notas.text.trim(),
        items: _items
            .map((i) => ModeloEntradaItem(
                  idProducto: i.producto.idProducto,
                  cantidad: i.cantidad,
                  costoUnit: i.costoValor,
                ))
            .toList(),
      );
      if (!mounted) return;
      _mensaje('Entrada registrada, el stock fue actualizado', Colors.green);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _guardando = false);
      _mensaje('Error al registrar la entrada: $e', Colors.red);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrada de mercancía'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historial de entradas',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const PantallaHistorialEntradas()),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _busqueda,
              decoration: InputDecoration(
                hintText: 'Buscar producto...',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: _filtrar,
            ),
          ),

          // Productos disponibles
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
                          return ListTile(
                            dense: true,
                            contentPadding: EdgeInsets.zero,
                            title: Text(p.nombre,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            subtitle: Text('Stock actual: ${p.stockActual}'),
                            trailing: const Icon(Icons.add_circle,
                                color: Colors.blue),
                            onTap: () => _agregar(p),
                          );
                        },
                      ),
          ),

          // Productos de la entrada
          Container(
            width: double.infinity,
            color: Colors.grey.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Text('Productos que llegaron (${_items.length})',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 3,
            child: _items.isEmpty
                ? const Center(
                    child: Text('Toca un producto para agregarlo',
                        style: TextStyle(color: Colors.grey)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _items.length,
                    itemBuilder: (_, i) {
                      final item = _items[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(item.producto.nombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: item.costo,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setState(() {}),
                                decoration: const InputDecoration(
                                  labelText: 'Costo',
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
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

          // Notas, total y botón
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                    top: BorderSide(color: Colors.grey.withOpacity(0.3))),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _notas,
                    decoration: InputDecoration(
                      hintText: 'Notas (opcional)',
                      isDense: true,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Costo total',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey)),
                            Text('\$${_total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: const Text('Registrar entrada'),
                        onPressed: _guardando ? null : _registrar,
                      ),
                    ],
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

class _ItemEntrada {
  final ModeloProducto producto;
  int cantidad;
  final TextEditingController costo;

  _ItemEntrada({
    required this.producto,
    required this.cantidad,
    required this.costo,
  });

  double get costoValor => double.tryParse(costo.text) ?? 0;
}