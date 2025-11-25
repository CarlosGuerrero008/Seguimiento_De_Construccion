import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/image_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'section_details_screen.dart';
import '../widgets/profile_option.dart';
import '../widgets/detail_item.dart';
import '../widgets/invitation_list_panel.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../widgets/project_card.dart';
import '../widgets/section_card.dart';
import '../widgets/progress_section.dart';
import '../widgets/delete_project_dialog.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImageService _imageService = ImageService();
  String? selectedProject;
  bool showProjectDetails = false;
  bool isDarkMode = false;
  OverlayEntry? _profileOverlayEntry;
  Uint8List? _profileImageBytes;

  Widget _buildProjectDetailsView(String projectId) {
    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance
              .collection('projects')
              .doc(projectId)
              .get(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text('Error al cargar los detalles: ${snapshot.error}'),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text('Detalles del proyecto no encontrados.'));
        }

        Map<String, dynamic> data =
            snapshot.data!.data() as Map<String, dynamic>;
        return _buildProjectDetails(
          data,
        ); // Llamamos a la función que construye la UI con los datos
      },
    );
  }

  final _emailController = TextEditingController();
  String? _selectedRole;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
    _loadProfileImage();
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  Future<void> _deleteProject(Map<String, dynamic> projectData) async {
    if (selectedProject == null || user == null) return;

    try {
      // Mostrar indicador de carga
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator()),
      );

      // 1. Eliminar todas las invitaciones relacionadas con este proyecto
      final invitations =
          await FirebaseFirestore.instance
              .collection('invitations')
              .where('projectId', isEqualTo: selectedProject)
              .get();

      for (var doc in invitations.docs) {
        await doc.reference.delete();
      }

      // 2. Eliminar todas las relaciones de usuarios con este proyecto
      final projectUsers =
          await FirebaseFirestore.instance
              .collection('projectUsers')
              .where('projectId', isEqualTo: selectedProject)
              .get();

      for (var doc in projectUsers.docs) {
        await doc.reference.delete();
      }

      // 3. Eliminar el proyecto en sí
      await FirebaseFirestore.instance
          .collection('projects')
          .doc(selectedProject)
          .delete();

      // Cerrar el diálogo de carga
      Navigator.of(context).pop();

      // Mostrar mensaje de éxito y volver a la lista
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Proyecto eliminado con éxito')));

      setState(() {
        showProjectDetails = false;
        selectedProject = null;
      });
    } catch (e) {
      // Cerrar el diálogo de carga si hay error
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar el proyecto: $e')),
      );
    }
  }

  // Future<bool> _isUserAdmin(String projectId) async {
  //   if (user == null) return false;

  //   final userProject = await FirebaseFirestore.instance
  //       .collection('projectUsers')
  //       .where('projectId', isEqualTo: projectId)
  //       .where('userId', isEqualTo: user!.uid)
  //       .where('role', isEqualTo: 'admin')
  //       .get();

  //   return userProject.docs.isNotEmpty;
  // }

  Future<void> _loadProfileImage() async {
    if (user == null) return;

    try {
      // Recargar el usuario actual para obtener los últimos datos
      await user?.reload();

      // Cargar imagen
      final imageBytes = await _imageService.getImage(user!.uid);

      setState(() {
        _profileImageBytes = imageBytes;
      });
    } catch (e) {
      debugPrint('Error cargando imagen y datos de usuario: $e');
    }
  }

  Future<void> _saveThemePreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', value);
  }

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
  }

  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    _saveThemePreference(isDarkMode);
  }

  String getUserName() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.displayName != null &&
        currentUser!.displayName!.isNotEmpty) {
      return currentUser.displayName!;
    } else if (currentUser?.email != null) {
      return currentUser!.email!.split('@')[0];
    }
    return 'Usuario';
  }

  void _showProfilePanel(BuildContext context) {
    _removeOverlay();
    _profileOverlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.black.withOpacity(0.3)),
            ),
            Positioned(
              right: 16,
              top: kToolbarHeight + MediaQuery.of(context).padding.top,
              child: Material(
                elevation: 8,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 350,
                  decoration: BoxDecoration(
                    color: isDarkMode ? Colors.grey[900] : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage:
                                  _profileImageBytes != null
                                      ? MemoryImage(_profileImageBytes!)
                                      : null,
                              child:
                                  _profileImageBytes == null
                                      ? Icon(Icons.person, size: 30)
                                      : null,
                              backgroundColor:
                                  isDarkMode
                                      ? Colors.blueGrey[700]
                                      : Colors.blue.shade100,
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  getUserName(),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        isDarkMode
                                            ? Colors.white
                                            : Colors.black,
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  user?.email ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDarkMode
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      ProfileOption(
                        icon: Icons.settings,
                        text: "Administrar tu cuenta",
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _removeOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfileScreen(),
                            ),
                          ).then((updated) {
                            if (updated == true) {
                              _loadProfileImage(); // Recargar imagen
                              setState(
                                () {},
                              ); // Forzar reconstrucción del widget
                            }
                          });
                        },
                      ),
                      Divider(height: 1),
                      ProfileOption(
                        icon: Icons.exit_to_app,
                        text: "Cerrar sesión",
                        color: Colors.red,
                        isDarkMode: isDarkMode,
                        onTap: () {
                          _removeOverlay();
                          logout(context);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );

    Overlay.of(context).insert(_profileOverlayEntry!);
  }

  void _showProjectDetailsDialog(Map<String, dynamic> projectData) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Encabezado
                Container(
                  padding: EdgeInsets.all(16),
                  color: isDarkMode ? Colors.blueGrey[800] : Colors.blue,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Detalles del Proyecto',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                // Contenido
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Información básica
                        Text(
                          projectData['name'] ?? 'Sin nombre',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        
                        // Ubicación GPS
                        if (projectData['latitude'] != null && projectData['longitude'] != null) ...[
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.location_on, color: Colors.red),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ubicación de la Obra',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: 8),
                                Text('Latitud: ${projectData['latitude']}'),
                                Text('Longitud: ${projectData['longitude']}'),
                                if (projectData['locationAddress'] != null)
                                  Padding(
                                    padding: EdgeInsets.only(top: 4),
                                    child: Text(
                                      'Dirección: ${projectData['locationAddress']}',
                                      style: TextStyle(fontStyle: FontStyle.italic),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                        ],
                        
                        // Historial de Actualizaciones
                        Text(
                          'Historial de Actualizaciones',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 12),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('projects')
                              .doc(selectedProject)
                              .snapshots(),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return Center(child: CircularProgressIndicator());
                            }
                            
                            var data = snapshot.data!.data() as Map<String, dynamic>?;
                            List<dynamic> updateHistory = data?['updateHistory'] ?? [];
                            
                            if (updateHistory.isEmpty) {
                              return Container(
                                padding: EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline, color: Colors.grey),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'No hay actualizaciones registradas',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            
                            return Column(
                              children: updateHistory.reversed.take(10).map((update) {
                                DateTime timestamp = (update['timestamp'] as Timestamp).toDate();
                                String formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(timestamp);
                                
                                return Container(
                                  margin: EdgeInsets.only(bottom: 8),
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? Colors.grey[800] : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: Colors.blue,
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              formattedDate,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 12,
                                              ),
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              update['description'] ?? 'Actualización',
                                              style: TextStyle(fontSize: 14),
                                            ),
                                            if (update['userName'] != null)
                                              Padding(
                                                padding: EdgeInsets.only(top: 4),
                                                child: Text(
                                                  'Por: ${update['userName']}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: Colors.grey[600],
                                                    fontStyle: FontStyle.italic,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _removeOverlay() {
    if (_profileOverlayEntry != null) {
      _profileOverlayEntry?.remove();
      _profileOverlayEntry = null;
    }
  }

  void _showNotificationPanel() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return InvitationListPanel(
          user: user,
        ); // Widget para mostrar la lista de invitaciones
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
      child: Scaffold(
        appBar: AppBar(
          title: Text("OSCUTO"),
          actions: [
            IconButton(icon: Icon(Icons.brightness_6), onPressed: toggleTheme),
            Stack(
              children: [
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed:
                      _showNotificationPanel, // Nueva función para mostrar el panel
                ),
                StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection('invitations')
                          .where('userId', isEqualTo: user!.uid)
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          constraints: BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            '${snapshot.data!.docs.length}',
                            style: TextStyle(color: Colors.white, fontSize: 10),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }
                    return SizedBox.shrink();
                  },
                ),
              ],
            ),
            GestureDetector(
              onTap: () => _showProfilePanel(context),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage:
                      _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : null,
                  child:
                      _profileImageBytes == null
                          ? Icon(Icons.person, size: 18)
                          : null,
                  backgroundColor:
                      isDarkMode ? Colors.blueGrey[700] : Colors.blue.shade100,
                ),
              ),
            ),
          ],
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              if (showProjectDetails)
                _buildProjectDetailsView(selectedProject!)
              else
                _buildProjectList(),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    super.dispose();
  }

  ThemeData _buildLightTheme() {
    return ThemeData(
      brightness: Brightness.light,
      primaryColor: Colors.blue,
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: Colors.blueGrey[800],
      scaffoldBackgroundColor: Colors.grey[900],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.blueGrey[800],
        foregroundColor: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: Colors.grey[800],
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _buildProjectList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton(
              onPressed: _showCreateProjectDialog,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor:
                    isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("CREAR PROYECTO"),
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection('projectUsers')
                    .where('userId', isEqualTo: user!.uid)
                    .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (snapshot.data == null || snapshot.data!.docs.isEmpty) {
                return Center(child: Text('No hay proyectos disponibles.'));
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final projectUser = snapshot.data!.docs[index];
                  final projectUserData =
                      projectUser.data(); // Obtener los datos

                  if (projectUserData != null &&
                      projectUserData is Map<String, dynamic>) {
                    // Verificar que no sea nulo y sea un mapa
                    final projectId = projectUserData['projectId'];
                    return FutureBuilder<DocumentSnapshot>(
                      future:
                          FirebaseFirestore.instance
                              .collection('projects')
                              .doc(projectId)
                              .get(),
                      builder: (context, projectSnapshot) {
                        if (projectSnapshot.hasError) {
                          return Center(
                            child: Text('Error: ${projectSnapshot.error}'),
                          );
                        }

                        if (projectSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return Center(child: CircularProgressIndicator());
                        }

                        if (!projectSnapshot.hasData ||
                            !projectSnapshot.data!.exists) {
                          return SizedBox.shrink();
                        }

                        final projectData =
                            projectSnapshot.data!.data()
                                as Map<String, dynamic>;
                        return ProjectCard(
                          projectName: projectData['name'],
                          projectId: projectId,
                          onTap: () {
                            setState(() {
                              selectedProject = projectId;
                              showProjectDetails = true;
                            });
                          },
                        );
                      },
                    );
                  } else {
                    return SizedBox.shrink(); // O un widget de error, dependiendo de tu lógica
                  }
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showCreateProjectDialog() {
    final _projectNameController = TextEditingController();
    final _projectDescriptionController = TextEditingController();
    final _projectTypeController = TextEditingController();
    final _workersController = TextEditingController();
    final _latitudeController = TextEditingController();
    final _longitudeController = TextEditingController();
    String _locationAddress = '';
    DateTime _startDate = DateTime.now();
    DateTime _endDate = DateTime.now().add(
      Duration(days: 30),
    ); //  Fecha prevista por defecto

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Crear Nuevo Proyecto'),
          content: SingleChildScrollView(
            child: StatefulBuilder(
              //  Usamos StatefulBuilder para manejar el estado dentro del diálogo
              builder: (BuildContext context, StateSetter setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _projectNameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre del Proyecto',
                      ),
                    ),
                    TextField(
                      controller: _projectDescriptionController,
                      decoration: InputDecoration(
                        labelText: 'Descripción del Proyecto',
                      ),
                    ),
                    DropdownButtonFormField<String>(
                      value:
                          _projectTypeController.text.isNotEmpty
                              ? _projectTypeController.text
                              : null,
                      items:
                          <String>['Privada', 'Pública', 'Mixta'].map((
                            String value,
                          ) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _projectTypeController.text = newValue!;
                        });
                      },
                      decoration: InputDecoration(labelText: 'Tipo de Obra'),
                    ),
                    TextField(
                      controller: _workersController,
                      decoration: InputDecoration(
                        labelText: 'Número de Trabajadores',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    ListTile(
                      title: Text('Fecha Inicio'),
                      subtitle: Text(
                        _startDate.toLocal().toString().split(' ')[0],
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _startDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && pickedDate != _startDate) {
                          setState(() {
                            _startDate = pickedDate;
                          });
                        }
                      },
                    ),
                    ListTile(
                      title: Text('Fecha Fin Previsto'),
                      subtitle: Text(
                        _endDate.toLocal().toString().split(' ')[0],
                      ),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        final DateTime? pickedDate = await showDatePicker(
                          context: context,
                          initialDate: _endDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (pickedDate != null && pickedDate != _endDate) {
                          setState(() {
                            _endDate = pickedDate;
                          });
                        }
                      },
                    ),
                    SizedBox(height: 16),
                    Divider(),
                    Text(
                      'Ubicación de la Obra',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _latitudeController,
                            decoration: InputDecoration(
                              labelText: 'Latitud',
                              hintText: 'Ej: -12.0464',
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _longitudeController,
                            decoration: InputDecoration(
                              labelText: 'Longitud',
                              hintText: 'Ej: -77.0428',
                            ),
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () async {
                        try {
                          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                          if (!serviceEnabled) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Los servicios de ubicación están deshabilitados')),
                            );
                            return;
                          }

                          LocationPermission permission = await Geolocator.checkPermission();
                          if (permission == LocationPermission.denied) {
                            permission = await Geolocator.requestPermission();
                            if (permission == LocationPermission.denied) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Permiso de ubicación denegado')),
                              );
                              return;
                            }
                          }

                          if (permission == LocationPermission.deniedForever) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Los permisos de ubicación están permanentemente denegados')),
                            );
                            return;
                          }

                          Position position = await Geolocator.getCurrentPosition(
                            desiredAccuracy: LocationAccuracy.high,
                          );

                          setState(() {
                            _latitudeController.text = position.latitude.toStringAsFixed(6);
                            _longitudeController.text = position.longitude.toStringAsFixed(6);
                          });

                          // Obtener dirección
                          try {
                            List<Placemark> placemarks = await placemarkFromCoordinates(
                              position.latitude,
                              position.longitude,
                            );
                            if (placemarks.isNotEmpty) {
                              Placemark place = placemarks[0];
                              setState(() {
                                _locationAddress = '${place.street}, ${place.locality}, ${place.country}';
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Ubicación obtenida: $_locationAddress')),
                              );
                            }
                          } catch (e) {
                            print('Error al obtener dirección: $e');
                          }
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error al obtener ubicación: $e')),
                          );
                        }
                      },
                      icon: Icon(Icons.my_location),
                      label: Text('Obtener Ubicación Actual'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 40),
                      ),
                    ),
                    if (_locationAddress.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Text(
                          'Dirección: $_locationAddress',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                String projectName = _projectNameController.text.trim();
                String projectDescription =
                    _projectDescriptionController.text.trim();
                String projectType = _projectTypeController.text.trim();
                String workers = _workersController.text.trim();

                if (projectName.isNotEmpty &&
                    projectDescription.isNotEmpty &&
                    projectType.isNotEmpty &&
                    workers.isNotEmpty) {
                  try {
                    // Validar y preparar coordenadas GPS
                    double? latitude;
                    double? longitude;
                    if (_latitudeController.text.isNotEmpty && _longitudeController.text.isNotEmpty) {
                      try {
                        latitude = double.parse(_latitudeController.text);
                        longitude = double.parse(_longitudeController.text);
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Coordenadas GPS inválidas')),
                        );
                        return;
                      }
                    }

                    //  1. Crear el proyecto en Firestore
                    final newProjectRef = await FirebaseFirestore.instance
                        .collection('projects')
                        .add({
                          'name': projectName,
                          'description': projectDescription,
                          'type': projectType,
                          'workers': workers,
                          'startDate': _startDate,
                          'endDate': _endDate,
                          'adminId': user!.uid,
                          'createdAt': FieldValue.serverTimestamp(),
                          'latitude': latitude,
                          'longitude': longitude,
                          'locationAddress': _locationAddress.isNotEmpty ? _locationAddress : null,
                          'updateHistory': [],
                        });

                    final newProjectId = newProjectRef.id;

                    //  Opcional:  Agregar al administrador al proyecto con el rol "admin"
                    await FirebaseFirestore.instance
                        .collection('projectUsers')
                        .add({
                          'projectId': newProjectId,
                          'userId': user!.uid,
                          'role': 'admin',
                        });

                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Proyecto creado con éxito.')),
                    );
                    setState(() {});
                  } catch (e) {
                    print('Error al crear el proyecto: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error al crear el proyecto.')),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Por favor, completa todos los campos.'),
                    ),
                  );
                }
              },
              child: Text('Crear'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProjectDetails(Map<String, dynamic> projectData) {
    return Column(
      // Cambiamos ListView por Column
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    showProjectDetails = false;
                    selectedProject = null;
                  });
                },
              ),
              Expanded(
                child: Text(
                  projectData['name'] ?? "Nombre del Proyecto",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              if (projectData['adminId'] ==
                  user?.uid) // Solo muestra si es el administrador
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => DeleteProjectDialog(
                        projectData: projectData,
                        onDelete: _deleteProject,
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
        Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DetailItem(
                label: "Tipo de Obra:",
                value: projectData['type'] ?? "No especificado",
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 16),
              DetailItem(
                label: "Descripción:",
                value: projectData['description'] ?? "Sin descripción",
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 16),
              DetailItem(
                label: "Trabajadores:",
                value: projectData['workers'] ?? "No especificado",
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 16),
              DetailItem(
                label: "Fecha Inicio:",
                value:
                    projectData['startDate'] != null
                        ? (projectData['startDate'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0]
                        : "No especificada",
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 16),
              DetailItem(
                label: "Fecha Fin Prevista:",
                value:
                    projectData['endDate'] != null
                        ? (projectData['endDate'] as Timestamp)
                            .toDate()
                            .toLocal()
                            .toString()
                            .split(' ')[0]
                        : "No especificada",
                isDarkMode: isDarkMode,
              ),
              SizedBox(height: 32),
              // NUEVA SECCIÓN: Progreso General del Proyecto
              ProgressSection(projectId: selectedProject!),
              SizedBox(height: 24),
              // NUEVA SECCIÓN: Secciones de la Obra
              _buildProjectSections(),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: () => _showProjectDetailsDialog(projectData),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(200, 50),
                    backgroundColor:
                        isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("MÁS DETALLES"),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: Text(
                    "HACER REPORTE CON LA ACTUALIZAR",
                    style: TextStyle(
                      fontSize: 16,
                      color: isDarkMode ? Colors.blue[200] : Colors.blue,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              // Sección para Invitar Usuarios
              Container(
                padding: EdgeInsets.all(16.0),
                margin: EdgeInsets.only(top: 24.0),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Invitar Usuario al Proyecto',
                      style: TextStyle(
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16.0),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: 'Correo Electrónico del Usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      value: _selectedRole,
                      items:
                          ['contratista', 'supervisor'].map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role),
                            );
                          }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedRole = value;
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Rol del Usuario',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    ElevatedButton(
                      onPressed: _inviteUser,
                      child: Text('Invitar'),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 50), // Agregar espacio extra al final
            ],
          ),
        ),
      ],
    );
  }

  void _inviteUser() async {
    String email = _emailController.text.trim();
    String? role = _selectedRole;

    if (email.isNotEmpty && role != null && selectedProject != null) {
      try {
        // 1. Buscar al usuario por correo electrónico
        final userSnapshot =
            await FirebaseFirestore.instance
                .collection(
                  'users',
                ) //  Asegúrate de que tu colección de usuarios se llama 'users'
                .where('email', isEqualTo: email)
                .get();

        if (userSnapshot.docs.isEmpty) {
          // 2. Manejar el caso de usuario no encontrado
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Usuario no encontrado.')));
          return; //  Detener la ejecución si el usuario no existe
        }

        //  Si llegamos aquí, el usuario existe.  Obtenemos su ID.
        final invitedUserId = userSnapshot.docs.first.id;

        //  3. Crear la invitación en la colección 'invitations'
        await FirebaseFirestore.instance.collection('invitations').add({
          'projectId': selectedProject, //  Ahora contiene el ID del proyecto
          'userId': invitedUserId,
          'role': role,
          'status': 'pending', //  Estado inicial de la invitación
          'invitedBy':
              user!.uid, // Opcional: ID del usuario que envió la invitación
          'invitedAt':
              FieldValue.serverTimestamp(), // Opcional: Fecha y hora de la invitación
        });

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Invitación enviada.')));

        //  4. Limpiar los campos después de enviar la invitación
        _emailController.clear();
        setState(() {
          _selectedRole = null;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al enviar la invitación: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Por favor, ingresa el correo electrónico, selecciona el rol y asegúrate de haber seleccionado un proyecto.',
          ),
        ),
      );
    }
  }

  // M\u00e9todos para gesti\u00f3n de secciones del proyecto
  Widget _buildProgressSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: selectedProject)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();
        
        double totalProgress = 0;
        int sectionCount = snapshot.data!.docs.length;
        
        if (sectionCount > 0) {
          for (var doc in snapshot.data!.docs) {
            totalProgress += (doc.data() as Map<String, dynamic>)['progressPercentage'] ?? 0;
          }
          totalProgress = totalProgress / sectionCount;
        }
        
        return Card(
          elevation: 4,
          margin: EdgeInsets.symmetric(horizontal: 16),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso General',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                LinearPercentIndicator(
                  lineHeight: 20.0,
                  percent: totalProgress / 100,
                  center: Text(
                    '${totalProgress.toStringAsFixed(1)}%',
                    style: TextStyle(fontSize: 12, color: Colors.white),
                  ),
                  backgroundColor: Colors.grey[300],
                  progressColor: totalProgress < 30 ? Colors.red :
                               totalProgress < 70 ? Colors.orange : Colors.green,
                  barRadius: Radius.circular(10),
                ),
                SizedBox(height: 8),
                Text(
                  sectionCount > 0 
                    ? '$sectionCount ${sectionCount == 1 ? "secci\u00f3n" : "secciones"}'
                    : 'Sin secciones a\u00fan',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProjectSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Secciones de la Obra',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: Icon(Icons.add_circle, color: Colors.blue, size: 32),
                onPressed: _showCreateSectionDialog,
                tooltip: 'Agregar secci\u00f3n',
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('projectSections')
              .where('projectId', isEqualTo: selectedProject)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Text('Error: ${snapshot.error}'),
              );
            }
            
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.construction, size: 48, color: Colors.grey),
                      SizedBox(height: 8),
                      Text(
                        'No hay secciones creadas a\u00fan.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Presiona + para agregar una',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            }
            
            // Ordenar las secciones manualmente por createdAt
            final sections = snapshot.data!.docs;
            sections.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aTime = (aData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              final bTime = (bData['createdAt'] as Timestamp?)?.millisecondsSinceEpoch ?? 0;
              return aTime.compareTo(bTime);
            });
            
            return ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: sections.length,
              itemBuilder: (context, index) {
                final doc = sections[index];
                final data = doc.data() as Map<String, dynamic>;
                
                return SectionCard(
                  sectionId: doc.id,
                  data: data,
                  onTap: () => _navigateToSectionDetails(doc.id, data),
                );
              },
            );
          },
        ),
      ],
    );
  }

  void _showCreateSectionDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Crear Nueva Secci\u00f3n'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre de la secci\u00f3n',
                  hintText: 'Ej: Cimentaci\u00f3n, Estructura, Acabados',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Descripci\u00f3n (opcional)',
                  hintText: 'Detalles sobre esta secci\u00f3n',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Por favor ingresa un nombre')),
                );
                return;
              }
              
              try {
                await FirebaseFirestore.instance.collection('projectSections').add({
                  'projectId': selectedProject,
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'progressPercentage': 0.0,
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastUpdated': null,
                });
                
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Secci\u00f3n creada exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error al crear secci\u00f3n: $e')),
                );
              }
            },
            child: Text('Crear'),
          ),
        ],
      ),
    );
  }

  void _navigateToSectionDetails(String sectionId, Map<String, dynamic> data) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SectionDetailsScreen(
          sectionId: sectionId,
          sectionData: data,
          projectId: selectedProject!,
        ),
      ),
    );
    
    // Si se actualizó algo, recargar la vista
    if (result == true) {
      setState(() {});
    }
  }
}
