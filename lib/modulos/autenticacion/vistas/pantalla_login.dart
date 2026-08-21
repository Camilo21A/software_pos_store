import 'package:flutter/material.dart';
import '../datos/repositorio_auth.dart';
import 'pantalla_principal.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final _repositorio = RepositorioAuth();
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _cargando = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    try {
      await _repositorio.login(_usernameCtrl.text, _passwordCtrl.text);

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PantallaPrincipal()),
              (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Usuario o contraseña incorrectos');
      }
    } finally {
      if (mounted) {
        setState(() => _cargando = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(controller: _usernameCtrl, decoration: const InputDecoration(labelText: 'Usuario')),
            TextField(controller: _passwordCtrl, obscureText: true, decoration: const InputDecoration(labelText: 'Contraseña')),
            if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            _cargando
                ? const CircularProgressIndicator()
                : ElevatedButton(onPressed: _iniciarSesion, child: const Text('Ingresar')),
          ],
        ),
      ),
    );
  }
}