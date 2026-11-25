import 'package:flutter/material.dart';
import '../datos/modelo_entrada.dart';
import '../datos/repositorio_entradas.dart';

class PantallaHistorialEntradas extends StatefulWidget {
  const PantallaHistorialEntradas({super.key});

  @override
  State<PantallaHistorialEntradas> createState() =>
      _PantallaHistorialEntradasState();
}

class _PantallaHistorialEntradasState extends State<PantallaHistorialEntradas> {
  final _repo = RepositorioEntradas();
  List<ModeloEntrada> _entradas = [];
  bool _cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

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
      final lista = await _repo.obtenerEntradas();
      if (!mounted) return;
      setState(() {
        _entradas = lista;
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

  void _verDetalle(ModeloEntrada e) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entrada #${e.idEntrada}',
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Text(_fmt(e.fechaHora),
                style: const TextStyle(color: Colors.grey)),
            if (e.notas != null && e.notas!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Notas: ${e.notas}'),
            ],
            const Divider(height: 24),
            ...e.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Expanded(
                          child: Text(
                              '${i.cantidad} × ${i.productoNombre ?? 'Producto'}')),
                      Text(
                          '\$${((i.costoUnit ?? 0) * i.cantidad).toStringAsFixed(0)}'),
                    ],
                  ),
                )),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Costo total',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('\$${e.total.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de entradas'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _cargar),
        ],
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : _entradas.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping_outlined,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 12),
                          Text('No hay entradas',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: _entradas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final e = _entradas[i];
                        return Card(
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                                color: Colors.grey.withOpacity(0.25)),
                          ),
                          child: ListTile(
                            onTap: () => _verDetalle(e),
                            title: Text('\$${e.total.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            subtitle: Text(_fmt(e.fechaHora)),
                            trailing: Text('${e.items.length} productos',
                                style: const TextStyle(color: Colors.grey)),
                          ),
                        );
                      },
                    ),
    );
  }
}