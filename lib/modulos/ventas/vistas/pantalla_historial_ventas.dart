import 'package:flutter/material.dart';
import '../datos/modelo_venta.dart';
import '../datos/repositorio_ventas.dart';

class PantallaHistorialVentas extends StatefulWidget {
  const PantallaHistorialVentas({super.key});

  @override
  State<PantallaHistorialVentas> createState() =>
      _PantallaHistorialVentasState();
}

class _PantallaHistorialVentasState extends State<PantallaHistorialVentas> {
  final _repo = RepositorioVentas();

  List<ModeloVenta> _ventas = [];
  bool _cargando = true;
  String? _error;

  String? _metodoPago;        // null = todos
  String? _estado;            // null = todos
  DateTimeRange? _rango;

  static const _metodos = {
    'efectivo': 'Efectivo',
    'nequi': 'Nequi',
    'daviplata': 'Daviplata',
    'transferencia': 'Transferencia',
    'otro': 'Otro',
  };

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  String _fecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _fmt(String iso) {
    final d = DateTime.parse(iso).toLocal();
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '${d.day}/${d.month}/${d.year}  $h:$m';
  }

  Future<void> _cargar() async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    try {
      final lista = await _repo.obtenerVentas(
        estado: _estado,
        metodoPago: _metodoPago,
        fechaDesde: _rango != null ? _fecha(_rango!.start) : null,
        fechaHasta: _rango != null ? _fecha(_rango!.end) : null,
      );
      if (!mounted) return;
      setState(() {
        _ventas = lista;
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _cargando = false;
      });
    }
  }

  Future<void> _elegirRango() async {
    final hoy = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(hoy.year - 2),
      lastDate: hoy,
      initialDateRange: _rango,
    );
    if (r != null) {
      setState(() => _rango = r);
      _cargar();
    }
  }

  double get _totalVendido => _ventas
      .where((v) => !v.estaAnulada)
      .fold(0, (s, v) => s + v.total);

  Future<void> _anular(ModeloVenta v) async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('¿Anular venta #${v.idVenta}?'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo de la anulación',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    if (ctrl.text.trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Debes escribir un motivo'),
        backgroundColor: Colors.orange,
      ));
      return;
    }

    try {
      await _repo.anularVenta(v.idVenta, ctrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Venta anulada, el stock fue devuelto'),
        backgroundColor: Colors.green,
      ));
      _cargar();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error al anular: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  void _verDetalle(ModeloVenta v) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Venta #${v.idVenta}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${_fmt(v.fechaHora)}  ·  ${_metodos[v.metodoPago] ?? v.metodoPago}',
                style: const TextStyle(color: Colors.grey)),
            if (v.estaAnulada) ...[
              const SizedBox(height: 8),
              Text('ANULADA: ${v.motivoAnulacion ?? ''}',
                  style: const TextStyle(color: Colors.red)),
            ],
            const Divider(height: 24),
            ...v.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              '${i.cantidad} × ${i.productoNombre ?? 'Producto'}')),
                      Text('\$${(i.subtotal ?? 0).toStringAsFixed(0)}'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${v.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            if (!v.estaAnulada) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                  label: const Text('Anular venta',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.pop(context);
                    _anular(v);
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hayFiltros = _metodoPago != null || _estado != null || _rango != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de ventas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ActionChip(
                  avatar: const Icon(Icons.date_range, size: 18),
                  label: Text(_rango == null
                      ? 'Fechas'
                      : '${_fecha(_rango!.start)} → ${_fecha(_rango!.end)}'),
                  onPressed: _elegirRango,
                ),
                PopupMenuButton<String?>(
                  onSelected: (v) {
                    setState(() => _metodoPago = v);
                    _cargar();
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: null, child: Text('Todos')),
                    ..._metodos.entries.map((e) =>
                        PopupMenuItem(value: e.key, child: Text(e.value))),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.payments_outlined, size: 18),
                    label: Text(_metodoPago == null
                        ? 'Método de pago'
                        : _metodos[_metodoPago]!),
                  ),
                ),
                PopupMenuButton<String?>(
                  onSelected: (v) {
                    setState(() => _estado = v);
                    _cargar();
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: null, child: Text('Todas')),
                    PopupMenuItem(value: 'activa', child: Text('Activas')),
                    PopupMenuItem(value: 'anulada', child: Text('Anuladas')),
                  ],
                  child: Chip(
                    avatar: const Icon(Icons.filter_list, size: 18),
                    label: Text(_estado == null
                        ? 'Estado'
                        : _estado == 'activa'
                            ? 'Activas'
                            : 'Anuladas'),
                  ),
                ),
                if (hayFiltros)
                  ActionChip(
                    avatar: const Icon(Icons.clear, size: 18),
                    label: const Text('Limpiar'),
                    onPressed: () {
                      setState(() {
                        _metodoPago = null;
                        _estado = null;
                        _rango = null;
                      });
                      _cargar();
                    },
                  ),
              ],
            ),
          ),

          // Resumen
          if (!_cargando && _error == null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${_ventas.length} ventas',
                      style: const TextStyle(color: Colors.grey)),
                  Text('Vendido: \$${_totalVendido.toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
            ),

          // Lista
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Error: $_error'))
                    : _ventas.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.receipt_long_outlined,
                                    size: 64, color: Colors.grey),
                                SizedBox(height: 12),
                                Text('No hay ventas',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(12),
                            itemCount: _ventas.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (_, i) {
                              final v = _ventas[i];
                              return Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                      color: Colors.grey.withOpacity(0.25)),
                                ),
                                child: ListTile(
                                  onTap: () => _verDetalle(v),
                                  title: Text(
                                    '\$${v.total.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      decoration: v.estaAnulada
                                          ? TextDecoration.lineThrough
                                          : null,
                                      color:
                                          v.estaAnulada ? Colors.grey : null,
                                    ),
                                  ),
                                  subtitle: Text(
                                      '${_fmt(v.fechaHora)}  ·  ${_metodos[v.metodoPago] ?? v.metodoPago}'),
                                  trailing: v.estaAnulada
                                      ? const Chip(
                                          label: Text('Anulada',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.red)))
                                      : Text('${v.items.length} ítems',
                                          style: const TextStyle(
                                              color: Colors.grey)),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}