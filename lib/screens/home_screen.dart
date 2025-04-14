import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';

class HomeScreen extends StatelessWidget {
  final User? user = FirebaseAuth.instance.currentUser;

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenido"),
        actions: [
          IconButton(
            onPressed: () => logout(context), 
            icon: Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue.shade100,
              child: Icon(
                Icons.person,
                size: 50,
                color: Colors.blue,
              ),
            ),
            SizedBox(height: 20),
            Text(
              "¡Bienvenido, ${user?.displayName ?? 'Usuario'}!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Text(
              user?.email ?? 'No hay correo registrado',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
            ),
            SizedBox(height: 20),
            Chip(
              backgroundColor: user?.emailVerified ?? false 
                  ? Colors.green.shade100 
                  : Colors.orange.shade100,
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    user?.emailVerified ?? false 
                        ? Icons.verified 
                        : Icons.warning,
                    size: 18,
                    color: user?.emailVerified ?? false 
                        ? Colors.green 
                        : Colors.orange,
                  ),
                  SizedBox(width: 5),
                  Text(
                    user?.emailVerified ?? false 
                        ? 'Correo verificado' 
                        : 'Correo no verificado',
                    style: TextStyle(
                      color: user?.emailVerified ?? false 
                          ? Colors.green 
                          : Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            if (!(user?.emailVerified ?? true))
              ElevatedButton.icon(
                onPressed: () async {
                  await user?.sendEmailVerification();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Correo de verificación reenviado a ${user?.email}'),
                    ),
                  );
                },
                icon: Icon(Icons.email),
                label: Text('Reenviar verificación'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade50,
                  foregroundColor: Colors.orange.shade800,
                ),
              ),
          ],
        ),
      ),
    );
  }
}