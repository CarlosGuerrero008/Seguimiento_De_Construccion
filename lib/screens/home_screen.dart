import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:typed_data';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import '../widgets/image_service.dart'; // Asegúrate de importar tu ImageService

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

  Future<void> _loadProfileImage() async {
    if (user == null) return;
    
    try {
      final imageBytes = await _imageService.getImage(user!.uid);
      if (imageBytes != null) {
        setState(() {
          _profileImageBytes = imageBytes;
        });
      }
    } catch (e) {
      debugPrint('Error cargando imagen: $e');
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
    if (user?.displayName != null && user!.displayName!.isNotEmpty) {
      return user!.displayName!;
    } else if (user?.email != null) {
      return user!.email!.split('@')[0];
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
                              backgroundImage: _profileImageBytes != null
                                ? MemoryImage(_profileImageBytes!)
                                : null,
                              child: _profileImageBytes == null
                                ? Icon(Icons.person, size: 30)
                                : null,
                              backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue.shade100,
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(getUserName(), 
                                    style: TextStyle(
                                      fontSize: 18, 
                                      fontWeight: FontWeight.bold,
                                      color: isDarkMode ? Colors.white : Colors.black,
                                    )),
                                SizedBox(height: 4),
                                Text(user?.email ?? '', 
                                    style: TextStyle(
                                      fontSize: 14, 
                                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600]
                                    )),
                              ],
                            ),
                          ],
                        ),
                      ),
                      
                      _buildProfileOption(
                        icon: Icons.settings,
                        text: "Administrar tu cuenta",
                        onTap: () {
                          _removeOverlay();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => EditProfileScreen()),
                          ).then((updated) {
                            if (updated == true) {
                              _loadProfileImage(); // Recargar imagen si hubo cambios
                            }
                          });
                        },
                      ),
                      
                      Divider(height: 1),
                      
                      _buildProfileOption(
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

    Overlay.of(context)?.insert(_profileOverlayEntry!);
  }

  void _removeOverlay() {
    if (_profileOverlayEntry != null) {
      _profileOverlayEntry?.remove();
      _profileOverlayEntry = null;
    }
  }

  Widget _buildProfileOption({required IconData icon, required String text, Color? color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              icon, 
              color: color ?? (isDarkMode ? Colors.grey[300] : Colors.grey[700]),
            ),
            SizedBox(width: 16),
            Text(
              text, 
              style: TextStyle(
                fontSize: 14,
                color: color ?? (isDarkMode ? Colors.white : Colors.black),
              ),
            ),
          ],
        ),
      ),
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
            IconButton(
              icon: Icon(Icons.brightness_6),
              onPressed: toggleTheme,
            ),
            IconButton(
              icon: Icon(Icons.notifications),
              onPressed: () {},
            ),
            GestureDetector(
              onTap: () => _showProfilePanel(context),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  radius: 18,
                  backgroundImage: _profileImageBytes != null
                    ? MemoryImage(_profileImageBytes!)
                    : null,
                  child: _profileImageBytes == null
                    ? Icon(Icons.person, size: 18)
                    : null,
                  backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue.shade100,
                ),
              ),
            ),
          ],
        ),
        body: showProjectDetails ? _buildProjectDetails() : _buildProjectList(),
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
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
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
      cardTheme: CardTheme(
        color: Colors.grey[800],
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
      ),
    )
    );
  }

  Widget _buildProjectList() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text("CREAR PROYECTO"),
            ),
          ),
          ListView(
            padding: EdgeInsets.all(16),
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            children: [
              _buildProjectCard("Proyecto 1"),
              SizedBox(height: 16),
              _buildProjectCard("Proyecto 2"),
              SizedBox(height: 16),
              _buildProjectCard("Proyecto 3"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectDetails() {
    return Column(
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
                  });
                },
              ),
              Text(
                selectedProject ?? "Proyecto 1",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Divider(color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailItem("Contratista:", "Nombre del contratista"),
                SizedBox(height: 16),
                _buildDetailItem("Tiempo:", "3 meses"),
                SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(200, 50),
                      backgroundColor: isDarkMode ? Colors.blueGrey[700] : Colors.blue,
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
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProjectCard(String projectName) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () {
          setState(() {
            selectedProject = projectName;
            showProjectDetails = true;
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            projectName,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.grey[400] : Colors.grey.shade600,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        ),
      ],
    );
  }
}