import 'package:flutter/material.dart';
import '../core/app_theme.dart';

class ThemeViewModel extends ChangeNotifier {
  TemaColor _temaActual = TemaColor.azul;
  bool _altoContraste = false;

  TemaColor get temaActual => _temaActual;
  bool get altoContraste => _altoContraste;

  void cambiarTema(TemaColor nuevoTema) {
    if (_temaActual != nuevoTema) {
      _temaActual = nuevoTema;
      notifyListeners(); // Avisa a main.dart para que redibuje la app
    }
  }

  void toggleAltoContraste(bool valor) {
    if (_altoContraste != valor) {
      _altoContraste = valor;
      notifyListeners();
    }
  }
}