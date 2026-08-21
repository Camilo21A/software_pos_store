import 'package:flutter/material.dart';
import 'modulos/autenticacion/vistas/pantalla_login.dart';

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
      home: const PantallaLogin(),
    );
  }
}