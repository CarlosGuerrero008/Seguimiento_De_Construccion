import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/deep_link_service.dart';

class AuthWrapper extends StatefulWidget {
  @override
  _AuthWrapperState createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    // Inicializar el servicio de deep linking después de que se construya el widget
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _deepLinkService.initialize(context);
      }
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Verificando si hay un usuario autenticado
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          if (user.emailVerified) {
            return HomeScreen();
          } else {
            // Si hay un token pendiente, pasarlo al LoginScreen
            return LoginScreen(
              invitationToken: _deepLinkService.pendingToken,
            );
          }
        }
        // Si hay un token pendiente, pasarlo al LoginScreen
        return LoginScreen(
          invitationToken: _deepLinkService.pendingToken,
        );
      },
    );
  }
}
