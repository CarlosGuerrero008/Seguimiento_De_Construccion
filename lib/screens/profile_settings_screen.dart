import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:intl/intl.dart';
import '../widgets/image_service.dart';
import '../providers/theme_provider.dart';
import 'login_screen.dart';

class ProfileSettingsScreen extends StatefulWidget {
  @override
  _ProfileSettingsScreenState createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final ImageService _imageService = ImageService();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  late TabController _tabController;

  // Controllers
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // State
  File? _imageFile;
  Uint8List? _profileImageBytes;
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;
  String _language = 'Español';
  String _dateFormat = 'dd/MM/yyyy';
  Map<String, dynamic>? _userdata;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadUserData();
    _loadPreferences();
  }

  Future<void> _loadUserData() async {
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      // Cargar imagen
      final imageBytes = await _imageService.getImage(user!.uid);
      if (imageBytes != null) {
        setState(() => _profileImageBytes = imageBytes);
      }

      // Cargar datos de Firestore
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (doc.exists) {
        setState(() {
          _userdata = doc.data();
          _nameController.text = _userdata?['username'] ?? user?.displayName ?? '';
          _phoneController.text = _userdata?['phone'] ?? '';
          _companyController.text = _userdata?['company'] ?? '';
          _positionController.text = _userdata?['position'] ?? '';
        });
      } else {
        _nameController.text = user?.displayName ?? '';
      }
    } catch (e) {
      debugPrint('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notificationsEnabled') ?? true;
      _emailNotifications = prefs.getBool('emailNotifications') ?? true;
      _pushNotifications = prefs.getBool('pushNotifications') ?? true;
      _soundEnabled = prefs.getBool('soundEnabled') ?? true;
      _vibrationEnabled = prefs.getBool('vibrationEnabled') ?? true;
      _language = prefs.getString('language') ?? 'Español';
      _dateFormat = prefs.getString('dateFormat') ?? 'dd/MM/yyyy';
    });
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    }
  }

  Future<void> _pickImage() async {
    try {
      setState(() => _isLoading = true);

      final androidInfo = await _deviceInfo.androidInfo;
      final isAndroid13OrHigher = androidInfo.version.sdkInt >= 33;
      final permission = isAndroid13OrHigher ? Permission.photos : Permission.storage;

      var status = await permission.status;

      if (status.isDenied) {
        status = await permission.request();
      }

      if (status.isGranted) {
        final pickedFile = await ImagePicker().pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );

        if (pickedFile != null) {
          setState(() => _imageFile = File(pickedFile.path));

          // Subir imagen inmediatamente
          final imageBytes = await _imageFile!.readAsBytes();
          await _imageService.uploadImage(user!.uid, imageBytes);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Foto de perfil actualizada')),
          );
        }
      } else if (status.isPermanentlyDenied) {
        await openAppSettings();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cambiar la foto')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _updateProfile() async {
    setState(() => _isLoading = true);

    try {
      // Actualizar nombre en Auth
      if (_nameController.text != user?.displayName) {
        await user?.updateDisplayName(_nameController.text);
        await user?.reload();
      }

      // Actualizar datos en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'username': _nameController.text,
        'email': user!.email,
        'phone': _phoneController.text,
        'company': _companyController.text,
        'position': _positionController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Perfil actualizado correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar perfil'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }

    if (_newPasswordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La contraseña debe tener al menos 6 caracteres')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _currentPasswordController.text,
      );

      await user!.reauthenticateWithCredential(credential);
      await user!.updatePassword(_newPasswordController.text);

      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ Contraseña actualizada correctamente'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Error al cambiar contraseña';
      if (e.code == 'wrong-password') {
        message = 'Contraseña actual incorrecta';
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Cuenta'),
          ],
        ),
        content: Text(
          '¿Estás seguro? Esta acción no se puede deshacer. Se eliminarán todos tus datos.',
          style: TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        // Eliminar datos de Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .delete();

        // Eliminar cuenta de Auth
        await user!.delete();

        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar cuenta')),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Configuracion del Perfil'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.primary100,
          indicatorColor: colorScheme.onPrimary,
          tabs: [
            Tab(icon: Icon(Icons.person), text: 'Perfil'),
            Tab(icon: Icon(Icons.lock), text: 'Seguridad'),
            Tab(icon: Icon(Icons.notifications), text: 'Notificaciones'),
            Tab(icon: Icon(Icons.settings), text: 'Preferencias'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProfileTab(),
                  _buildSecurityTab(),
                  _buildNotificationsTab(),
                  _buildPreferencesTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Foto de perfil
          GestureDetector(
            onTap: _pickImage,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!)
                      : _profileImageBytes != null
                          ? MemoryImage(_profileImageBytes!)
                          : null,
                  child: _imageFile == null && _profileImageBytes == null
                      ? Icon(Icons.person, size: 60)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                    ),
                    child: Icon(Icons.camera_alt, size: 20, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Información del usuario
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información Personal',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Nombre completo',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    initialValue: user?.email,
                    decoration: InputDecoration(
                      labelText: 'Correo electrónico',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                    readOnly: true,
                    enabled: false,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Teléfono',
                      prefixIcon: Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(),
                      hintText: '+52 123 456 7890',
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _companyController,
                    decoration: InputDecoration(
                      labelText: 'Empresa/Compañía',
                      prefixIcon: Icon(Icons.business_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _positionController,
                    decoration: InputDecoration(
                      labelText: 'Cargo/Posición',
                      prefixIcon: Icon(Icons.work_outline),
                      border: OutlineInputBorder(),
                      hintText: 'Ej: Ingeniero Civil, Supervisor',
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Información de cuenta
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Información de la Cuenta',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  _buildInfoRow(
                    'ID de Usuario',
                    user!.uid.substring(0, 8) + '...',
                    Icons.fingerprint,
                  ),
                  _buildInfoRow(
                    'Fecha de Registro',
                    user!.metadata.creationTime != null
                        ? DateFormat('dd/MM/yyyy').format(user!.metadata.creationTime!)
                        : 'N/A',
                    Icons.calendar_today,
                  ),
                  _buildInfoRow(
                    'Último Acceso',
                    user!.metadata.lastSignInTime != null
                        ? DateFormat('dd/MM/yyyy HH:mm').format(user!.metadata.lastSignInTime!)
                        : 'N/A',
                    Icons.access_time,
                  ),
                  _buildInfoRow(
                    'Email Verificado',
                    user!.emailVerified ? 'Sí' : 'No',
                    user!.emailVerified ? Icons.verified : Icons.warning,
                    color: user!.emailVerified ? Colors.green : Colors.orange,
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 24),

          // Botón guardar
          ElevatedButton.icon(
            onPressed: _updateProfile,
            icon: Icon(Icons.save),
            label: Text('GUARDAR CAMBIOS'),
            style: ElevatedButton.styleFrom(
              minimumSize: Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cambiar Contraseña',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Contraseña actual',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Nueva contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                      helperText: 'Mínimo 6 caracteres',
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: InputDecoration(
                      labelText: 'Confirmar contraseña',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: _changePassword,
                    icon: Icon(Icons.security),
                    label: Text('CAMBIAR CONTRASEÑA'),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 50),
                      backgroundColor: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Sesiones activas
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sesiones y Dispositivos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  ListTile(
                    leading: Icon(Icons.smartphone, color: AppColors.primary500),
                    title: Text('Dispositivo Actual'),
                    subtitle: Text('Último acceso: Ahora'),
                    trailing: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Activo',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),

          // Zona peligrosa
          Card(
            elevation: 2,
            color: Colors.red.shade50,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Zona Peligrosa',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.red),
                  SizedBox(height: 8),
                  Text(
                    'Eliminar tu cuenta eliminará permanentemente todos tus datos, proyectos y reportes.',
                    style: TextStyle(color: Colors.red.shade900),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: _deleteAccount,
                    icon: Icon(Icons.delete_forever, color: Colors.red),
                    label: Text('ELIMINAR CUENTA'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      minimumSize: Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Column(
              children: [
                SwitchListTile(
                  title: Text('Notificaciones'),
                  subtitle: Text('Habilitar todas las notificaciones'),
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                    _savePreference('notificationsEnabled', value);
                  },
                  secondary: Icon(Icons.notifications_active),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Notificaciones Push'),
                  subtitle: Text('Recibir notificaciones en tu dispositivo'),
                  value: _pushNotifications,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _pushNotifications = value);
                          _savePreference('pushNotifications', value);
                        }
                      : null,
                  secondary: Icon(Icons.phone_android),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Notificaciones por Email'),
                  subtitle: Text('Recibir resúmenes por correo'),
                  value: _emailNotifications,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _emailNotifications = value);
                          _savePreference('emailNotifications', value);
                        }
                      : null,
                  secondary: Icon(Icons.email),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Sonido'),
                  subtitle: Text('Reproducir sonido en notificaciones'),
                  value: _soundEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _soundEnabled = value);
                          _savePreference('soundEnabled', value);
                        }
                      : null,
                  secondary: Icon(Icons.volume_up),
                ),
                Divider(height: 1),
                SwitchListTile(
                  title: Text('Vibración'),
                  subtitle: Text('Vibrar con notificaciones'),
                  value: _vibrationEnabled,
                  onChanged: _notificationsEnabled
                      ? (value) {
                          setState(() => _vibrationEnabled = value);
                          _savePreference('vibrationEnabled', value);
                        }
                      : null,
                  secondary: Icon(Icons.vibration),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipos de Notificaciones',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Divider(),
                  CheckboxListTile(
                    title: Text('Nuevos proyectos'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: Text('Reportes diarios'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: Text('Invitaciones a proyectos'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  CheckboxListTile(
                    title: Text('Actualizaciones de progreso'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferencesTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.language),
                  title: Text('Idioma'),
                  subtitle: Text(_language),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Seleccionar Idioma'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Text('Español'),
                              value: 'Español',
                              groupValue: _language,
                              onChanged: (value) {
                                setState(() => _language = value!);
                                _savePreference('language', value!);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('English'),
                              value: 'English',
                              groupValue: _language,
                              onChanged: (value) {
                                setState(() => _language = value!);
                                _savePreference('language', value!);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.calendar_today),
                  title: Text('Formato de Fecha'),
                  subtitle: Text(_dateFormat),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Formato de Fecha'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            RadioListTile<String>(
                              title: Text('dd/MM/yyyy'),
                              subtitle: Text(DateFormat('dd/MM/yyyy').format(DateTime.now())),
                              value: 'dd/MM/yyyy',
                              groupValue: _dateFormat,
                              onChanged: (value) {
                                setState(() => _dateFormat = value!);
                                _savePreference('dateFormat', value!);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('MM/dd/yyyy'),
                              subtitle: Text(DateFormat('MM/dd/yyyy').format(DateTime.now())),
                              value: 'MM/dd/yyyy',
                              groupValue: _dateFormat,
                              onChanged: (value) {
                                setState(() => _dateFormat = value!);
                                _savePreference('dateFormat', value!);
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile<String>(
                              title: Text('yyyy-MM-dd'),
                              subtitle: Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
                              value: 'yyyy-MM-dd',
                              groupValue: _dateFormat,
                              onChanged: (value) {
                                setState(() => _dateFormat = value!);
                                _savePreference('dateFormat', value!);
                                Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Acerca de'),
                  subtitle: Text('Versión 1.0.0'),
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'Seguimientos',
                      applicationVersion: '1.0.0',
                      applicationIcon: Icon(Icons.construction, size: 48),
                      children: [
                        Text('Sistema de Seguimiento de Construcción Civil'),
                        SizedBox(height: 8),
                        Text('Desarrollado con Flutter y Firebase'),
                      ],
                    );
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.privacy_tip_outlined),
                  title: Text('Política de Privacidad'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.description_outlined),
                  title: Text('Términos y Condiciones'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.help_outline),
                  title: Text('Ayuda y Soporte'),
                  trailing: Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color ?? Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
