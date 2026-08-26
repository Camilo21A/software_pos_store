import 'package:flutter/material.dart';
import 'modulos/autenticacion/datos/repositorio_auth.dart';
import 'modulos/autenticacion/vistas/pantalla_login.dart';
import 'modulos/autenticacion/vistas/pantalla_principal.dart';

void main() {
  runApp(const MiPosApp());
}

class MiPosApp extends StatelessWidget {
  const MiPosApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Tienda',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const PantallaInicial(),
    );
  }
}

/// Decide, al abrir la app, si arranca en PantallaPrincipal (ya hay sesión)
/// o en PantallaLogin (no hay sesión activa).
class PantallaInicial extends StatefulWidget {
  const PantallaInicial({super.key});

  @override
  State<PantallaInicial> createState() => _PantallaInicialState();
}

class _PantallaInicialState extends State<PantallaInicial> {
  final _repositorio = RepositorioAuth();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _repositorio.haySesionActiva(),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final sesionActiva = snapshot.data ?? false;
        return sesionActiva ? const PantallaPrincipal() : const PantallaLogin();
      },
    );
  }
}