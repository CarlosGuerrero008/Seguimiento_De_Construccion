import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import '../screens/invitation_handler_screen.dart';

class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;
  String? _pendingToken;

  // Getter para el token pendiente
  String? get pendingToken => _pendingToken;

  // Limpiar token pendiente
  void clearPendingToken() {
    _pendingToken = null;
  }

  // Inicializar el servicio de deep linking
  Future<void> initialize(BuildContext context) async {
    _appLinks = AppLinks();

    // Manejar el link inicial cuando la app se abre desde un estado cerrado
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri, context);
      }
    } catch (e) {
      print('Error al obtener el link inicial: $e');
    }

    // Escuchar links cuando la app ya está abierta
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleDeepLink(uri, context);
      },
      onError: (err) {
        print('Error en el stream de links: $err');
      },
    );
  }

  // Procesar el deep link
  void _handleDeepLink(Uri uri, BuildContext context) {
    print('Deep link recibido: $uri');

    // Verificar si es un link de invitación (custom scheme o https)
    final isCustomInvite =
        uri.scheme == 'seguimiento-construccion' && uri.host == 'invite';
    final isHttpsInvite = uri.scheme == 'https' &&
        uri.host.contains('seguimiento-construccion') &&
        uri.pathSegments.contains('invite');

    if (isCustomInvite || isHttpsInvite) {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        // Guardar el token para procesarlo después del login si es necesario
        _pendingToken = token;

        // Navegar a la pantalla de validación de invitación
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => InvitationHandlerScreen(token: token),
            ),
          );
        }
      } else {
        print('Token de invitación no encontrado en el link');
      }
    } else {
      print('Esquema de deep link no reconocido: ${uri.scheme}://${uri.host}');
    }
  }

  // Limpiar recursos
  void dispose() {
    _linkSubscription?.cancel();
  }
}
