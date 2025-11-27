import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'login_screen.dart';
import 'profile_settings_screen.dart';
import 'project_dashboard_screen.dart';
import 'materials_management_screen.dart';
import 'create_project_screen.dart';
import '../widgets/image_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'section_details_screen.dart';
import '../widgets/profile_option.dart';
import '../widgets/detail_item.dart';
import '../widgets/invitation_list_panel.dart';
import 'project_report_screen.dart';
import 'project_chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImageService _imageService = ImageService();
  final TextEditingController _searchController = TextEditingController();
  String? selectedProject;
  bool showProjectDetails = false;
  bool isDarkMode = false;
  OverlayEntry? _profileOverlayEntry;
  Uint8List? _profileImageBytes;
  bool showInviteSection = false;
  bool showProjectDetailsExpanded = false;
  String _searchQuery = '';

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
        showInviteSection = false;
        showProjectDetailsExpanded = false;
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

  void logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginScreen()),
    );
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
                              builder: (context) => ProfileSettingsScreen(),
                            ),
                          ).then((updated) {
                            // Recargar tema y perfil cuando regrese de configuraciones
                            _loadThemePreference();
                            _loadProfileImage();
                            setState(() {});
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

  void _showDeleteConfirmationDialog(Map<String, dynamic> projectData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirmar eliminación'),
          content: Text(
            '¿Estás seguro de que deseas eliminar el proyecto "${projectData['name']}"? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteProject(projectData);
              },
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
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
          title: Text("Seguimientos"),
          actions: [
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
    _searchController.dispose();
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
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[850] : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar proyectos...',
                prefixIcon: Icon(Icons.search, color: Colors.blue),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CreateProjectScreen(),
                  ),
                );
                // Refrescar si se creó el proyecto
                if (result == true) {
                  setState(() {});
                }
              },
              icon: Icon(Icons.add_circle_outline, size: 24),
              label: Text(
                "CREAR PROYECTO",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 56),
                backgroundColor:
                    isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
              ),
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

                        // Filtrar por búsqueda
                        final projectName = projectData['name'] ?? '';
                        if (_searchQuery.isNotEmpty &&
                            !projectName.toLowerCase().contains(_searchQuery)) {
                          return SizedBox.shrink();
                        }

                        return _buildProjectCard(
                          projectData,
                          projectId,
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

  Widget _buildProjectCard(Map<String, dynamic> projectData, String projectId) {
    final projectName = projectData['name'] ?? 'Sin nombre';
    final projectType = projectData['type'] ?? 'No especificado';
    final description = projectData['description'] ?? 'Sin descripción';
    final workers = projectData['workers'] ?? 'N/A';

    // Calcular progreso
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: projectId)
          .snapshots(),
      builder: (context, sectionSnapshot) {
        double avgProgress = 0;
        int sectionCount = 0;

        if (sectionSnapshot.hasData && sectionSnapshot.data!.docs.isNotEmpty) {
          sectionCount = sectionSnapshot.data!.docs.length;
          double totalProgress = 0;
          for (var doc in sectionSnapshot.data!.docs) {
            totalProgress += (doc.data() as Map<String, dynamic>)['progressPercentage'] ?? 0;
          }
          avgProgress = totalProgress / sectionCount;
        }

        return Card(
          elevation: 4,
          margin: EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
              setState(() {
                selectedProject = projectId;
                showProjectDetails = true;
              });
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    isDarkMode ? Colors.grey[800]! : Colors.white,
                    isDarkMode ? Colors.grey[850]! : Colors.blue.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y tipo
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            projectName,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            projectType,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),

                    // Descripción
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 12),

                    // Información adicional
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: Colors.blue),
                        SizedBox(width: 4),
                        Text(
                          '$workers trabajadores',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.construction, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          '$sectionCount secciones',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                      ],
                    ),

                    if (sectionCount > 0) ...[
                      SizedBox(height: 12),
                      // Barra de progreso
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progreso General',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                ),
                              ),
                              Text(
                                '${avgProgress.toStringAsFixed(1)}%',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: avgProgress < 30 ? Colors.red :
                                         avgProgress < 70 ? Colors.orange : Colors.green,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: avgProgress / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey[300],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                avgProgress < 30 ? Colors.red :
                                avgProgress < 70 ? Colors.orange : Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
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
                    showInviteSection = false;
                    showProjectDetailsExpanded = false;
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
                  onPressed: () => _showDeleteConfirmationDialog(projectData),
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
              // Botón para invitar usuarios (movido al inicio)
              if (projectData['adminId'] == user?.uid)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          showInviteSection = !showInviteSection;
                          if (!showInviteSection) {
                            // Limpiar campos al cerrar
                            _emailController.clear();
                            _selectedRole = null;
                          }
                        });
                      },
                      icon: Icon(showInviteSection ? Icons.keyboard_arrow_up : Icons.person_add),
                      label: Text('Invitar Usuario al Proyecto'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(double.infinity, 50),
                        backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    if (showInviteSection)
                      Container(
                        padding: EdgeInsets.all(16.0),
                        margin: EdgeInsets.only(top: 8.0, bottom: 16.0),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDarkMode ? Colors.grey[700]! : Colors.grey,
                          ),
                          borderRadius: BorderRadius.circular(8.0),
                          color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _emailController,
                              decoration: InputDecoration(
                                labelText: 'Correo Electrónico del Usuario',
                                border: OutlineInputBorder(),
                                prefixIcon: Icon(Icons.email),
                              ),
                            ),
                            SizedBox(height: 12.0),
                            DropdownButtonFormField<String>(
                              value: _selectedRole,
                              items: ['contratista', 'supervisor'].map((role) {
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
                                prefixIcon: Icon(Icons.work),
                              ),
                            ),
                            SizedBox(height: 16.0),
                            ElevatedButton(
                              onPressed: _inviteUser,
                              style: ElevatedButton.styleFrom(
                                minimumSize: Size(double.infinity, 45),
                              ),
                              child: Text('Enviar Invitación'),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 16),
                  ],
                ),
              // Sección colapsable de detalles del proyecto
              Column(
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        showProjectDetailsExpanded = !showProjectDetailsExpanded;
                      });
                    },
                    icon: Icon(showProjectDetailsExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down),
                    label: Text('Detalles del Proyecto'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  if (showProjectDetailsExpanded)
                    Container(
                      padding: EdgeInsets.all(16.0),
                      margin: EdgeInsets.only(top: 8.0, bottom: 16.0),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isDarkMode ? Colors.grey[700]! : Colors.grey,
                        ),
                        borderRadius: BorderRadius.circular(8.0),
                        color: isDarkMode ? Colors.grey[850] : Colors.grey[50],
                      ),
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
                        ],
                      ),
                    ),
                  SizedBox(height: 16),
                ],
              ),
              // BOTONES IMPORTANTES ARRIBA (Dashboard y Materiales)
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProjectDashboardScreen(
                          projectId: selectedProject!,
                          projectData: projectData,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.dashboard),
                  label: Text("VER DASHBOARD"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55),
                    backgroundColor:
                        isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MaterialsManagementScreen(
                          projectId: selectedProject!,
                          projectName: projectData['name'] ?? 'Proyecto',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.inventory),
                  label: Text("GESTIONAR MATERIALES"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55),
                    backgroundColor:
                        isDarkMode ? Colors.green[700] : Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 24),
              // NUEVA SECCIÓN: Progreso General del Proyecto
              _buildProgressSection(),
              SizedBox(height: 24),
              // NUEVA SECCIÓN: Secciones de la Obra
              _buildProjectSections(),
              SizedBox(height: 32),
              // BOTONES SECUNDARIOS HORIZONTALES (Reporte y Chatbot)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectReportScreen(
                              projectId: selectedProject!,
                              projectData: projectData,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.assessment, size: 20),
                      label: Text(
                        "REPORTE COMPLETO",
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 55),
                        backgroundColor:
                            isDarkMode ? Colors.purple[700] : Colors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProjectChatbotScreen(
                              projectId: selectedProject!,
                              projectData: projectData,
                            ),
                          ),
                        );
                      },
                      icon: Icon(Icons.smart_toy, size: 20),
                      label: Text(
                        "ASISTENTE IA",
                        style: TextStyle(fontSize: 12),
                      ),
                      style: ElevatedButton.styleFrom(
                        minimumSize: Size(0, 55),
                        backgroundColor:
                            isDarkMode ? Colors.orange[700] : Colors.orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
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
                
                return _buildSectionCard(doc.id, data);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionCard(String sectionId, Map<String, dynamic> data) {
    double progress = (data['progressPercentage'] ?? 0).toDouble();
    
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToSectionDetails(sectionId, data),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      data['name'] ?? 'Sin nombre',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: progress < 30 ? Colors.red.withOpacity(0.2) :
                             progress < 70 ? Colors.orange.withOpacity(0.2) : 
                             Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${progress.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: progress < 30 ? Colors.red :
                               progress < 70 ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
              if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  data['description'] ?? '',
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12),
              LinearPercentIndicator(
                lineHeight: 8.0,
                percent: progress / 100,
                backgroundColor: Colors.grey[300],
                progressColor: progress < 30 ? Colors.red :
                             progress < 70 ? Colors.orange : Colors.green,
                barRadius: Radius.circular(10),
              ),
            ],
          ),
        ),
      ),
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
