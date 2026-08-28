import 'package:flutter/material.dart';
import '../datos/modelo_producto.dart';
import '../datos/repositorio_inventario.dart';

class PantallaFormularioProducto extends StatefulWidget {
  final ModeloProducto? producto;
  const PantallaFormularioProducto({super.key, this.producto});

  @override
  State<PantallaFormularioProducto> createState() =>
      _PantallaFormularioProductoState();
}

class _PantallaFormularioProductoState
    extends State<PantallaFormularioProducto> {
  final _formKey     = GlobalKey<FormState>();
  final _repo        = RepositorioInventario();
  bool _guardando    = false;
  bool _cargandoCategorias = true;

  final _nombre       = TextEditingController();
  final _precioVenta  = TextEditingController();
  final _precioCompra = TextEditingController();
  final _stockActual  = TextEditingController();
  final _stockMinimo  = TextEditingController();
  final _codigoBarras = TextEditingController();
  final _sinonimos    = TextEditingController();

  List<ModeloCategoria> _categorias = [];
  int? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarCategorias().then((_) {
      final p = widget.producto;
      if (p != null && mounted) {
        setState(() {
          _nombre.text       = p.nombre;
          _precioVenta.text  = p.precioVenta.toStringAsFixed(0);
          _precioCompra.text = p.precioCompra?.toStringAsFixed(0) ?? '';
          _stockActual.text  = p.stockActual.toString();
          _stockMinimo.text  = p.stockMinimo.toString();
          _codigoBarras.text = p.codigoBarras ?? '';
          _sinonimos.text    = p.sinonimos.join(', ');
          final existe = _categorias.any((c) => c.idCategoria == p.idCategoria);
          _categoriaSeleccionada = existe ? p.idCategoria : null;
        });
      }
    });
  }

  Future<void> _cargarCategorias() async {
    try {
      final lista = await _repo.obtenerCategorias();
      if (mounted) {
        setState(() {
          _categorias = lista;
          _cargandoCategorias = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _cargandoCategorias = false);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final sinonimos = _sinonimos.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final datos = {
      'nombre':        _nombre.text.trim(),
      'precio_venta':  double.tryParse(_precioVenta.text) ?? 0,
      'precio_compra': _precioCompra.text.isNotEmpty
          ? double.tryParse(_precioCompra.text)
          : null,
      'stock_actual':  int.tryParse(_stockActual.text) ?? 0,
      'stock_minimo':  int.tryParse(_stockMinimo.text) ?? 5,
      'codigo_barras': _codigoBarras.text.isNotEmpty ? _codigoBarras.text : null,
      'sinonimos':     sinonimos,
      if (_categoriaSeleccionada != null) 'id_categoria': _categoriaSeleccionada,
    };

    try {
      if (widget.producto == null) {
        await _repo.crearProducto(datos);
      } else {
        await _repo.actualizarProducto(widget.producto!.idProducto, datos);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(widget.producto == null
              ? 'Producto creado exitosamente'
              : 'Producto actualizado'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _guardando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error al guardar: $e'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  @override
  void dispose() {
    _nombre.dispose();
    _precioVenta.dispose();
    _precioCompra.dispose();
    _stockActual.dispose();
    _stockMinimo.dispose();
    _codigoBarras.dispose();
    _sinonimos.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.producto != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(esEdicion ? 'Editar producto' : 'Nuevo producto'),
        actions: [
          _guardando
              ? const Padding(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: 20, height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : TextButton(
            onPressed: _guardar,
            child: const Text('Guardar'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            _Campo(
              label: 'Nombre del producto *',
              controller: _nombre,
              validator: (v) => v!.isEmpty ? 'El nombre es obligatorio' : null,
            ),
            const SizedBox(height: 12),

            // Categoría con loader
            _cargandoCategorias
                ? const TextField(
              decoration: InputDecoration(
                labelText: 'Categoría',
                hintText: 'Cargando...',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              ),
              enabled: false,
            )
                : DropdownButtonFormField<int>(
              value: _categoriaSeleccionada,
              decoration: _decoracion('Categoría'),
              items: [
                const DropdownMenuItem(
                    value: null, child: Text('Sin categoría')),
                ..._categorias.map((c) => DropdownMenuItem(
                  value: c.idCategoria,
                  child: Text(c.nombre),
                )),
              ],
              onChanged: (v) =>
                  setState(() => _categoriaSeleccionada = v),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _Campo(
                    label: 'Precio venta *',
                    controller: _precioVenta,
                    teclado: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      if (double.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    label: 'Precio compra',
                    controller: _precioCompra,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _Campo(
                    label: 'Stock actual *',
                    controller: _stockActual,
                    teclado: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Obligatorio';
                      if (int.tryParse(v) == null) return 'Número inválido';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _Campo(
                    label: 'Stock mínimo',
                    controller: _stockMinimo,
                    teclado: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _Campo(
              label: 'Código de barras',
              controller: _codigoBarras,
              teclado: TextInputType.number,
            ),
            const SizedBox(height: 12),

            _Campo(
              label: 'Sinónimos para voz (separados por coma)',
              controller: _sinonimos,
              hint: 'ej: coca, koka, cocacola',
            ),
            const SizedBox(height: 8),
            const Text(
              'Los sinónimos permiten encontrar el producto al vender por voz',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 32),

            FilledButton(
              onPressed: _guardando ? null : _guardar,
              child: Text(esEdicion ? 'Actualizar producto' : 'Crear producto'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final TextInputType teclado;
  final String? Function(String?)? validator;

  const _Campo({
    required this.label,
    required this.controller,
    this.hint,
    this.teclado = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller:   controller,
      keyboardType: teclado,
      validator:    validator,
      decoration:   _decoracion(label).copyWith(hintText: hint),
    );
  }
}

InputDecoration _decoracion(String label) {
  return InputDecoration(
    labelText:      label,
    border:         OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
    isDense:        true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
  );
}