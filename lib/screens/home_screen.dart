import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:async';
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
import 'package:share_plus/share_plus.dart';
import 'project_documents_screen.dart';

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
  OverlayEntry? _profileOverlayEntry;
  Uint8List? _profileImageBytes;
  bool showProjectDetailsExpanded = false;
  String _searchQuery = '';
  Timer? _projectSearchDebounce;

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

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
                    color: isDark ? Colors.grey[900] : Colors.white,
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
                                  isDark
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
                                        isDark
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
                                        isDark
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
                        onTap: () {
                          _removeOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfileSettingsScreen(),
                            ),
                          ).then((updated) {
                            // Recargar perfil cuando regrese de configuraciones
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
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
                      isDark ? Colors.blueGrey[700] : Colors.blue.shade100,
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
    );
  }

  @override
  void dispose() {
    _removeOverlay();
    _searchController.dispose();
    _projectSearchDebounce?.cancel();
    super.dispose();
  }


  Widget _buildProjectList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Barra de búsqueda
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
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
                // Cancelar búsqueda anterior
                _projectSearchDebounce?.cancel();

                // Esperar 300ms después de que el usuario deja de escribir
                _projectSearchDebounce = Timer(Duration(milliseconds: 300), () {
                  if (mounted) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  }
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
                fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
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
                    isDark ? Colors.blueGrey[700] : Colors.blue,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                    isDark ? Colors.grey[800]! : Colors.white,
                    isDark ? Colors.grey[850]! : Colors.blue.shade50,
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
                              color: isDark ? Colors.white : Colors.black87,
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
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
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
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.construction, size: 16, color: Colors.orange),
                        SizedBox(width: 4),
                        Text(
                          '$sectionCount secciones',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
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
                                  color: isDark ? Colors.grey[400] : Colors.grey[600],
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
        Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Botón para invitar usuarios (movido al inicio)
              if (projectData['adminId'] == user?.uid)
                _InviteUserSection(
                  projectId: selectedProject!,
                  onInviteSent: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Invitación enviada.')),
                    );
                  },
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
                      backgroundColor: isDark ? Colors.blueGrey[700] : Colors.blue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  AnimatedSize(
                    duration: Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: showProjectDetailsExpanded
                        ? Container(
                            padding: EdgeInsets.all(16.0),
                            margin: EdgeInsets.only(top: 8.0, bottom: 16.0),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: isDark ? Colors.grey[700]! : Colors.grey,
                              ),
                              borderRadius: BorderRadius.circular(8.0),
                              color: isDark ? Colors.grey[850] : Colors.grey[50],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                DetailItem(
                                  label: "Tipo de Obra:",
                                  value: projectData['type'] ?? "No especificado",
                                ),
                                SizedBox(height: 16),
                                DetailItem(
                                  label: "Descripción:",
                                  value: projectData['description'] ?? "Sin descripción",
                                ),
                                SizedBox(height: 16),
                                DetailItem(
                                  label: "Trabajadores:",
                                  value: projectData['workers']?.toString() ?? "No especificado",
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
                                ),
                              ],
                            ),
                          )
                        : SizedBox.shrink(),
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
                        isDark ? Colors.blueGrey[700] : Colors.blue,
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
                        isDark ? Colors.green[700] : Colors.green,
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
                        builder: (context) => ProjectDocumentsScreen(
                          projectId: selectedProject!,
                          projectName: projectData['name'] ?? 'Proyecto',
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.folder_open),
                  label: Text("DOCUMENTACIÓN"),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 55),
                    backgroundColor:
                        isDark ? Colors.indigo[700] : Colors.indigo,
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
                            isDark ? Colors.purple[700] : Colors.purple,
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
                            isDark ? Colors.orange[700] : Colors.orange,
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

  // Métodos para gestión de secciones del proyecto
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

// Widget separado para la sección de invitar usuarios
class _InviteUserSection extends StatefulWidget {
  final String projectId;
  final VoidCallback onInviteSent;

  const _InviteUserSection({
    Key? key,
    required this.projectId,
    required this.onInviteSent,
  }) : super(key: key);

  @override
  _InviteUserSectionState createState() => _InviteUserSectionState();
}

class _InviteUserSectionState extends State<_InviteUserSection> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  String? _selectedRole;
  String? _selectedLinkRole;
  bool _showEmailSuggestions = false;
  List<Map<String, dynamic>> _emailSuggestions = [];
  Timer? _debounceTimer;
  bool _isExpanded = false;
  late TabController _tabController;
  String? _generatedLink;
  String? _generatedDeepLink;
  bool _isGeneratingLink = false;
  String? _currentLinkToken;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _debounceTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _searchUsers(String query) {
    _debounceTimer?.cancel();

    if (query.isEmpty) {
      setState(() {
        _showEmailSuggestions = false;
        _emailSuggestions = [];
      });
      return;
    }

    _debounceTimer = Timer(Duration(milliseconds: 500), () async {
      try {
        final usersSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isGreaterThanOrEqualTo: query)
            .where('email', isLessThan: query + 'z')
            .limit(5)
            .get();

        if (mounted) {
          setState(() {
            _emailSuggestions = usersSnapshot.docs
                .map((doc) => {
                      'id': doc.id,
                      'email': doc.data()['email'] ?? '',
                      'name': doc.data()['name'] ?? '',
                    })
                .toList();
            _showEmailSuggestions = _emailSuggestions.isNotEmpty;
          });
        }
      } catch (e) {
        print('Error buscando usuarios: $e');
      }
    });
  }

  Future<void> _inviteUser() async {
    final user = FirebaseAuth.instance.currentUser;
    String email = _emailController.text.trim();
    String? role = _selectedRole;

    if (email.isEmpty || role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, completa todos los campos'),
        ),
      );
      return;
    }

    try {
      final userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (userSnapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Usuario no encontrado.')),
        );
        return;
      }

      final invitedUserId = userSnapshot.docs.first.id;

      await FirebaseFirestore.instance.collection('invitations').add({
        'projectId': widget.projectId,
        'userId': invitedUserId,
        'role': role,
        'status': 'pending',
        'invitedBy': user!.uid,
        'invitedAt': FieldValue.serverTimestamp(),
      });

      widget.onInviteSent();

      setState(() {
        _emailController.clear();
        _selectedRole = null;
        _showEmailSuggestions = false;
        _emailSuggestions = [];
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invitación enviada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar la invitación: $e')),
      );
    }
  }

  Future<void> _generateInvitationLink() async {
    final user = FirebaseAuth.instance.currentUser;
    String? role = _selectedLinkRole;

    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Por favor, selecciona un rol para el link'),
        ),
      );
      return;
    }

    setState(() {
      _isGeneratingLink = true;
    });

    try {
      // Generar token único
      final token = DateTime.now().millisecondsSinceEpoch.toString() +
                   (user!.uid.substring(0, 5));

      // Calcular fecha de expiración (7 días)
      final expiresAt = DateTime.now().add(Duration(days: 7));

      // Guardar link en Firestore
      await FirebaseFirestore.instance.collection('invitation_links').doc(token).set({
        'projectId': widget.projectId,
        'role': role,
        'createdBy': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': expiresAt,
        'maxUses': 10,
        'usedCount': 0,
        'isActive': true,
      });

      // Generar el link (custom scheme + https para que sea clickeable en chats)
      final deepLink = 'seguimiento-construccion://invite?token=$token';
      final httpsLink = 'https://seguimiento-construccion.com/invite?token=$token';

      setState(() {
        _generatedLink = httpsLink;
        _generatedDeepLink = deepLink;
        _currentLinkToken = token;
        _isGeneratingLink = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Link de invitación generado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() {
        _isGeneratingLink = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al generar el link: $e')),
      );
    }
  }

  Future<void> _copyToClipboard() async {
    if (_generatedLink != null) {
      final textToCopy = _generatedDeepLink != null
          ? '$_generatedLink\n$_generatedDeepLink'
          : _generatedLink!;
      await Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Link copiado al portapapeles'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _shareLink() async {
    if (_generatedLink == null) return;

    final message = StringBuffer()
      ..writeln('Únete al proyecto con este link:')
      ..writeln(_generatedLink);

    if (_generatedDeepLink != null) {
      message
        ..writeln()
        ..writeln('Si ya tienes la app instalada, también puedes usar:')
        ..writeln(_generatedDeepLink);
    }

    await Share.share(
      message.toString(),
      subject: 'Invitación al proyecto',
    );
  }

  Widget _buildEmailTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          TextField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'Correo Electrónico del Usuario',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.email),
              suffixIcon: _emailController.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _emailController.clear();
                          _showEmailSuggestions = false;
                          _emailSuggestions = [];
                        });
                      },
                    )
                  : null,
            ),
            onChanged: _searchUsers,
          ),
          if (_showEmailSuggestions && _emailSuggestions.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[800] : Colors.white,
                border: Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              constraints: BoxConstraints(maxHeight: 200),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _emailSuggestions.length,
                itemBuilder: (context, index) {
                  final suggestion = _emailSuggestions[index];
                  return ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.blue,
                      child: Text(
                        suggestion['email'][0].toUpperCase(),
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                    title: Text(
                      suggestion['email'],
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    subtitle: suggestion['name'].isNotEmpty
                        ? Text(
                            suggestion['name'],
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          )
                        : null,
                    onTap: () {
                      setState(() {
                        _emailController.text = suggestion['email'];
                        _showEmailSuggestions = false;
                        _emailSuggestions = [];
                      });
                    },
                  );
                },
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
          ElevatedButton.icon(
            onPressed: _inviteUser,
            icon: Icon(Icons.send),
            label: Text('Enviar Invitación'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: isDark ? Colors.blue[700] : Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkTab() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 16),
          // Información
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? Colors.blue[900]!.withOpacity(0.2) : Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.blue[700]! : Colors.blue[200]!,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: isDark ? Colors.blue[300] : Colors.blue[700],
                  size: 24,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Genera un link de invitación que podrás compartir. El link expira en 7 días y permite hasta 10 usos.',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.blue[200] : Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Selector de rol
          DropdownButtonFormField<String>(
            value: _selectedLinkRole,
            items: ['contratista', 'supervisor'].map((role) {
              return DropdownMenuItem(
                value: role,
                child: Text(role),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedLinkRole = value;
              });
            },
            decoration: InputDecoration(
              labelText: 'Rol para este Link',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.work_outline),
              helperText: 'Selecciona el rol que tendrán los usuarios invitados',
            ),
          ),
          SizedBox(height: 16),
          // Botón generar
          ElevatedButton.icon(
            onPressed: _isGeneratingLink ? null : _generateInvitationLink,
            icon: _isGeneratingLink
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(Icons.link),
            label: Text(_isGeneratingLink ? 'Generando...' : 'Generar Link de Invitación'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              backgroundColor: isDark ? Colors.green[700] : Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          // Link generado
          if (_generatedLink != null) ...[
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [Colors.green[900]!.withOpacity(0.3), Colors.green[800]!.withOpacity(0.2)]
                      : [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.green[700]! : Colors.green[300]!,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: isDark ? Colors.green[300] : Colors.green[700],
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Link Generado',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.green[300] : Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _generatedLink!,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: isDark ? Colors.green[200] : Colors.green[900],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        SizedBox(width: 8),
                        IconButton(
                          icon: Icon(Icons.copy, size: 20),
                          onPressed: _copyToClipboard,
                          tooltip: 'Copiar',
                          color: isDark ? Colors.blue[300] : Colors.blue[700],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyToClipboard,
                          icon: Icon(Icons.copy),
                          label: Text('Copiar Link'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.green[300] : Colors.green[700],
                            side: BorderSide(
                              color: isDark ? Colors.green[700]! : Colors.green[300]!,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareLink,
                          icon: Icon(Icons.share),
                          label: Text('Compartir'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark ? Colors.green[700] : Colors.green,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Divider(color: isDark ? Colors.grey[700] : Colors.grey[300]),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.access_time,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Expira en 7 días',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.people_outline,
                            size: 16,
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Máx. 10 usos',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _isExpanded = !_isExpanded;
              if (!_isExpanded) {
                _emailController.clear();
                _selectedRole = null;
                _selectedLinkRole = null;
                _showEmailSuggestions = false;
                _emailSuggestions = [];
                _generatedLink = null;
                _currentLinkToken = null;
              }
            });
          },
          icon: Icon(_isExpanded ? Icons.keyboard_arrow_up : Icons.person_add),
          label: Text('Invitar Usuario al Proyecto'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            backgroundColor: isDark ? Colors.blueGrey[700] : Colors.blue,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        if (_isExpanded)
          Container(
            padding: EdgeInsets.all(16.0),
            margin: EdgeInsets.only(top: 8.0, bottom: 16.0),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark ? Colors.grey[700]! : Colors.grey,
              ),
              borderRadius: BorderRadius.circular(8.0),
              color: isDark ? Colors.grey[850] : Colors.grey[50],
            ),
            child: Column(
              children: [
                // TabBar
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: isDark ? Colors.blue[700] : Colors.blue,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: isDark ? Colors.grey[400] : Colors.grey[700],
                    tabs: [
                      Tab(
                        icon: Icon(Icons.email),
                        text: 'Por Email',
                      ),
                      Tab(
                        icon: Icon(Icons.link),
                        text: 'Por Link',
                      ),
                    ],
                  ),
                ),
                // TabBarView
                SizedBox(
                  height: _generatedLink != null && _tabController.index == 1 ? 550 : 350,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildEmailTab(),
                      _buildLinkTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 16),
      ],
    );
  }
}
