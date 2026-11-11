import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/app_colors.dart';
import '../viewmodels/auth_view_model.dart';
import 'widgets/pictograma_imagen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usuarioCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _ocultar = true;

  @override
  void dispose() {
    _usuarioCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _entrar() async {
    final usuario = _usuarioCtrl.text.trim();
    final pass = _passCtrl.text;
    if (usuario.isEmpty || pass.isEmpty) return;
    // Si el login va bien, AuthGate cambia de pantalla solo.
    await context.read<AuthViewModel>().iniciarSesion(usuario, pass);
  }

  InputDecoration _decoracion(
    String etiqueta,
    IconData icono, {
    Widget? sufijo,
  }) {
    return InputDecoration(
      labelText: etiqueta,
      labelStyle: const TextStyle(fontSize: 22),
      prefixIcon: Icon(icono, size: 32),
      suffixIcon: sufijo,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthViewModel>();

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Card(
              color: AppColors.surface,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Center(
                      child: PictogramaImagen(
                        consulta: 'agenda',
                        size: 120,
                        iconoReserva: Icons.menu_book_outlined,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Mi Agenda',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Escribe tu nombre de usuario y tu contraseña',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, color: AppColors.textSoft),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: _usuarioCtrl,
                      textInputAction: TextInputAction.next,
                      autocorrect: false,
                      style: const TextStyle(fontSize: 26),
                      decoration: _decoracion(
                        'Nombre de usuario',
                        Icons.person_outline,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _passCtrl,
                      obscureText: _ocultar,
                      onSubmitted: (_) => _entrar(),
                      style: const TextStyle(fontSize: 26),
                      decoration: _decoracion(
                        'Contraseña',
                        Icons.lock_outline,
                        sufijo: IconButton(
                          iconSize: 32,
                          tooltip: _ocultar
                              ? 'Mostrar contraseña'
                              : 'Ocultar contraseña',
                          icon: Icon(
                            _ocultar ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () => setState(() => _ocultar = !_ocultar),
                        ),
                      ),
                    ),
                    if (auth.error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        auth.error!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    const SizedBox(height: 28),
                    FilledButton(
                      onPressed: auth.cargando ? null : _entrar,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size.fromHeight(76),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: auth.cargando
                          ? const SizedBox(
                              height: 30,
                              width: 30,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ENTRAR',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
