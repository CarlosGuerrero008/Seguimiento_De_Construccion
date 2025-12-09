import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import '../providers/theme_provider.dart';

class InvitationHandlerScreen extends StatefulWidget {
  final String token;

  const InvitationHandlerScreen({
    Key? key,
    required this.token,
  }) : super(key: key);

  @override
  _InvitationHandlerScreenState createState() => _InvitationHandlerScreenState();
}

class _InvitationHandlerScreenState extends State<InvitationHandlerScreen> {
  bool _isLoading = true;
  bool _isValid = false;
  String _errorMessage = '';
  Map<String, dynamic>? _invitationData;
  Map<String, dynamic>? _projectData;

  @override
  void initState() {
    super.initState();
    _validateInvitation();
  }

  Future<void> _validateInvitation() async {
    try {
      // Obtener datos del link de invitación
      final invitationDoc = await FirebaseFirestore.instance
          .collection('invitation_links')
          .doc(widget.token)
          .get();

      if (!invitationDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'El link de invitación no existe o es inválido.';
        });
        return;
      }

      final invitationData = invitationDoc.data()!;

      // Verificar si está activo
      if (invitationData['isActive'] != true) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Este link de invitación ha sido desactivado.';
        });
        return;
      }

      // Verificar expiración
      final expiresAt = (invitationData['expiresAt'] as Timestamp).toDate();
      if (DateTime.now().isAfter(expiresAt)) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Este link de invitación ha expirado.';
        });
        return;
      }

      // Verificar límite de usos
      final usedCount = invitationData['usedCount'] ?? 0;
      final maxUses = invitationData['maxUses'] ?? 10;
      if (usedCount >= maxUses) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Este link ha alcanzado su límite máximo de usos.';
        });
        return;
      }

      // Obtener datos del proyecto
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(invitationData['projectId'])
          .get();

      if (!projectDoc.exists) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'El proyecto asociado ya no existe.';
        });
        return;
      }

      setState(() {
        _isValid = true;
        _isLoading = false;
        _invitationData = invitationData;
        _projectData = projectDoc.data();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error al validar la invitación: $e';
      });
    }
  }

  Future<void> _acceptInvitation() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Usuario no autenticado, redirigir al login
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Debes iniciar sesión para aceptar la invitación'),
          backgroundColor: Colors.orange,
        ),
      );

      // Guardar el token para procesarlo después del login
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => LoginScreen(
            invitationToken: widget.token,
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final projectId = _invitationData!['projectId'];
      final role = _invitationData!['role'];

      // Verificar si el usuario ya es miembro del proyecto
      final projectDoc = await FirebaseFirestore.instance
          .collection('projects')
          .doc(projectId)
          .get();

      final projectMembers = List<String>.from(projectDoc.data()?['members'] ?? []);

      if (projectMembers.contains(user.uid)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ya eres miembro de este proyecto'),
            backgroundColor: AppColors.primary500,
          ),
        );

        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        return;
      }

      // Agregar usuario al proyecto
      await FirebaseFirestore.instance.collection('projects').doc(projectId).update({
        'members': FieldValue.arrayUnion([user.uid]),
        'roles.$user.uid': role,
      });

      // Incrementar contador de usos
      await FirebaseFirestore.instance
          .collection('invitation_links')
          .doc(widget.token)
          .update({
        'usedCount': FieldValue.increment(1),
      });

      // Crear notificación de aceptación
      await FirebaseFirestore.instance.collection('invitations').add({
        'projectId': projectId,
        'userId': user.uid,
        'role': role,
        'status': 'accepted',
        'invitedBy': _invitationData!['createdBy'],
        'invitedAt': FieldValue.serverTimestamp(),
        'acceptedAt': FieldValue.serverTimestamp(),
        'invitationType': 'link',
      });

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('¡Te has unido al proyecto exitosamente!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );

      // Redirigir al home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => HomeScreen()),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al unirse al proyecto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text(
                    'Validando invitación...',
                    style: TextStyle(fontSize: 16),
                  ),
                ],
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    Icon(
                      _isValid ? Icons.mail : Icons.error_outline,
                      size: 100,
                      color: _isValid
                          ? (isDark ? Colors.green[300] : Colors.green)
                          : (isDark ? Colors.red[300] : Colors.red),
                    ),
                    SizedBox(height: 30),
                    Text(
                      _isValid ? 'Invitación de Proyecto' : 'Invitación Inválida',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    if (_isValid && _projectData != null) ...[
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[850] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                            width: 2,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.business,
                                  color: AppColors.primary500,
                                  size: 32,
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Proyecto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      SizedBox(height: 4),
                                      Text(
                                        _projectData!['name'] ?? 'Sin nombre',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 16),
                            Divider(),
                            SizedBox(height: 16),
                            _buildInfoRow(
                              Icons.location_on,
                              'Ubicación',
                              _projectData!['location'] ?? 'No especificada',
                              isDark,
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.work_outline,
                              'Tu Rol',
                              _invitationData!['role'] ?? 'Sin rol',
                              isDark,
                            ),
                            SizedBox(height: 12),
                            _buildInfoRow(
                              Icons.access_time,
                              'Link expira',
                              _formatDate(
                                  (_invitationData!['expiresAt'] as Timestamp).toDate()),
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: _acceptInvitation,
                        icon: Icon(Icons.check_circle, size: 24),
                        label: Text(
                          'Unirse al Proyecto',
                          style: TextStyle(fontSize: 18),
                        ),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 60),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => HomeScreen()),
                          );
                        },
                        icon: Icon(Icons.home),
                        label: Text('Volver al Inicio'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red[900]!.withOpacity(0.2)
                              : Colors.red[50],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isDark ? Colors.red[700]! : Colors.red[300]!,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.error_outline,
                              color: isDark ? Colors.red[300] : Colors.red[700],
                              size: 32,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _errorMessage,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isDark ? Colors.red[200] : Colors.red[900],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => HomeScreen()),
                          );
                        },
                        icon: Icon(Icons.home),
                        label: Text('Volver al Inicio'),
                        style: ElevatedButton.styleFrom(
                          minimumSize: Size(double.infinity, 50),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now);

    if (difference.inDays > 0) {
      return 'En ${difference.inDays} días';
    } else if (difference.inHours > 0) {
      return 'En ${difference.inHours} horas';
    } else if (difference.inMinutes > 0) {
      return 'En ${difference.inMinutes} minutos';
    } else {
      return 'Expirado';
    }
  }
}
