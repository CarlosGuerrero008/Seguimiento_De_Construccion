import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../providers/theme_provider.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({Key? key}) : super(key: key);

  @override
  _CreateProjectScreenState createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isCreating = false;

  // Controladores
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _workersController = TextEditingController();
  final _locationController = TextEditingController();
  final _clientController = TextEditingController();
  final _budgetController = TextEditingController();

  // Datos del proyecto
  String _selectedType = 'Privada';
  String _selectedStatus = 'Planificado';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(Duration(days: 90));
  
  // Coordenadas de ubicación
  double? _latitude;
  double? _longitude;
  bool _isLoadingLocation = false;

  final List<String> _projectTypes = ['Privada', 'Pública', 'Mixta'];
  final List<String> _projectStatuses = [
    'Planificado',
    'En Progreso',
    'Pausado',
    'Completado',
    'Cancelado'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _workersController.dispose();
    _locationController.dispose();
    _clientController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Nuevo Proyecto'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: (context, details) {
              final bottomPadding = MediaQuery.of(context).viewInsets.bottom;
              return Padding(
                padding: EdgeInsets.only(
                  top: 20,
                  bottom: bottomPadding > 0 ? bottomPadding : 16,
                ),
                child: Row(
                  children: [
                  if (_currentStep < 2)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Siguiente',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  if (_currentStep == 2)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCreating ? null : _createProject,
                        icon: _isCreating
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Icon(Icons.check_circle),
                        label: Text(
                          _isCreating ? 'Creando...' : 'Crear Proyecto',
                          style: TextStyle(fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) SizedBox(width: 12),
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: details.onStepCancel,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('Atrás', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: Text('Básico'),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildBasicInfoStep(),
              ),
              Step(
                title: Text('Detalles'),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildDetailsStep(),
              ),
              Step(
                title: Text('Confirmar'),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildConfirmationStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información Básica del Proyecto',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        SizedBox(height: 20),
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(
            labelText: 'Nombre del Proyecto',
            hintText: 'Ej: Edificio Residencial Los Pinos',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.business),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El nombre es obligatorio';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _descriptionController,
          decoration: InputDecoration(
            labelText: 'Descripción',
            hintText: 'Describe brevemente el proyecto',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.description),
          ),
          maxLines: 3,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'La descripción es obligatoria';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedType,
          decoration: InputDecoration(
            labelText: 'Tipo de Obra',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.category),
          ),
          items: _projectTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedType = value!;
            });
          },
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _workersController,
          decoration: InputDecoration(
            labelText: 'Número de Trabajadores',
            hintText: 'Ej: 25',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.groups),
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'El número de trabajadores es obligatorio';
            }
            if (int.tryParse(value) == null) {
              return 'Ingresa un número válido';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDetailsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Detalles Adicionales',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextFormField(
                controller: _locationController,
                decoration: InputDecoration(
                  labelText: 'Ubicación',
                  hintText: 'Ej: Av. Principal #123, Distrito Norte',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.location_on),
                ),
                maxLines: 2,
                minLines: 1,
              ),
            ),
            SizedBox(width: 8),
            Container(
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary500,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(horizontal: 16),
                ),
                child: _isLoadingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Icon(Icons.my_location),
              ),
            ),
          ],
        ),
        if (_latitude != null && _longitude != null)
          Padding(
            padding: EdgeInsets.only(top: 8),
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Coordenadas: $_latitude, $_longitude',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        SizedBox(height: 16),
        TextFormField(
          controller: _clientController,
          decoration: InputDecoration(
            labelText: 'Cliente',
            hintText: 'Nombre del cliente o empresa',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.person),
          ),
        ),
        SizedBox(height: 16),
        TextFormField(
          controller: _budgetController,
          decoration: InputDecoration(
            labelText: 'Presupuesto (opcional)',
            hintText: 'Ej: 500000',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.attach_money),
            suffixText: '\$',
          ),
          keyboardType: TextInputType.number,
          validator: (value) {
            if (value != null &&
                value.isNotEmpty &&
                double.tryParse(value) == null) {
              return 'Ingresa un monto válido';
            }
            return null;
          },
        ),
        SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: _selectedStatus,
          decoration: InputDecoration(
            labelText: 'Estado Inicial',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.info),
          ),
          items: _projectStatuses.map((status) {
            IconData icon;
            Color color;
            switch (status) {
              case 'Planificado':
                icon = Icons.schedule;
                color = AppColors.primary500;
                break;
              case 'En Progreso':
                icon = Icons.construction;
                color = Colors.orange;
                break;
              case 'Pausado':
                icon = Icons.pause_circle;
                color = Colors.grey;
                break;
              case 'Completado':
                icon = Icons.check_circle;
                color = Colors.green;
                break;
              case 'Cancelado':
                icon = Icons.cancel;
                color = Colors.red;
                break;
              default:
                icon = Icons.help;
                color = Colors.grey;
            }
            return DropdownMenuItem(
              value: status,
              child: Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  SizedBox(width: 8),
                  Text(status),
                ],
              ),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedStatus = value!;
            });
          },
        ),
        SizedBox(height: 16),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.calendar_today, color: AppColors.primary500),
            title: Text('Fecha de Inicio'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_startDate)),
            trailing: Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _startDate,
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() {
                  _startDate = picked;
                  // Ajustar fecha fin si es anterior a la fecha de inicio
                  if (_endDate.isBefore(_startDate)) {
                    _endDate = _startDate.add(Duration(days: 90));
                  }
                });
              }
            },
          ),
        ),
        SizedBox(height: 12),
        Card(
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.event, color: Colors.green),
            title: Text('Fecha de Fin Prevista'),
            subtitle: Text(DateFormat('dd/MM/yyyy').format(_endDate)),
            trailing: Icon(Icons.edit),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _endDate,
                firstDate: _startDate,
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(() => _endDate = picked);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmationStep() {
    final days = _endDate.difference(_startDate).inDays;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Confirmación',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.primary500,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'Revisa la información antes de crear el proyecto',
          style: TextStyle(color: Colors.grey[600]),
        ),
        SizedBox(height: 20),
        Card(
          elevation: 3,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoRow('Nombre', _nameController.text, Icons.business),
                Divider(height: 24),
                _buildInfoRow('Descripción', _descriptionController.text,
                    Icons.description),
                Divider(height: 24),
                _buildInfoRow('Tipo de Obra', _selectedType, Icons.category),
                Divider(height: 24),
                _buildInfoRow('Trabajadores', _workersController.text,
                    Icons.groups),
                if (_locationController.text.isNotEmpty) ...[
                  Divider(height: 24),
                  _buildInfoRow('Ubicación', _locationController.text,
                      Icons.location_on),
                ],
                if (_clientController.text.isNotEmpty) ...[
                  Divider(height: 24),
                  _buildInfoRow(
                      'Cliente', _clientController.text, Icons.person),
                ],
                if (_budgetController.text.isNotEmpty) ...[
                  Divider(height: 24),
                  _buildInfoRow('Presupuesto',
                      '\$${_budgetController.text}', Icons.attach_money),
                ],
                Divider(height: 24),
                _buildInfoRow('Estado', _selectedStatus, Icons.info),
                Divider(height: 24),
                _buildInfoRow('Inicio',
                    DateFormat('dd/MM/yyyy').format(_startDate), Icons.calendar_today),
                Divider(height: 24),
                _buildInfoRow('Fin Previsto',
                    DateFormat('dd/MM/yyyy').format(_endDate), Icons.event),
                Divider(height: 24),
                _buildInfoRow('Duración', '$days días', Icons.schedule),
              ],
            ),
          ),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.primary900.withOpacity(0.3)
                : AppColors.primary50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.primary700
                  : AppColors.primary200,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                color: Theme.of(context).brightness == Brightness.dark
                    ? AppColors.primary300
                    : AppColors.primary500,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Una vez creado, serás el administrador del proyecto y podrás agregar secciones, materiales y usuarios.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.primary100
                        : AppColors.primary900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
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
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 1);
      }
    } else if (_currentStep == 1) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep = 2);
      }
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep -= 1);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      // Verificar si el servicio de ubicación está habilitado
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('El servicio de ubicación está desactivado'),
            backgroundColor: Colors.orange,
            action: SnackBarAction(
              label: 'Activar',
              textColor: Colors.white,
              onPressed: () {
                Geolocator.openLocationSettings();
              },
            ),
          ),
        );
        return;
      }

      // Verificar permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Permiso de ubicación denegado'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Los permisos de ubicación están permanentemente denegados. Habilítalos en configuración.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
        return;
      }

      // Obtener la posición actual
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      // Intentar obtener la dirección desde las coordenadas
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude,
          position.longitude,
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = '';

          if (place.street != null && place.street!.isNotEmpty) {
            address += place.street!;
          }
          if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.subLocality}' : place.subLocality!;
          }
          if (place.locality != null && place.locality!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.locality}' : place.locality!;
          }
          if (place.administrativeArea != null &&
              place.administrativeArea!.isNotEmpty) {
            address += address.isNotEmpty
                ? ', ${place.administrativeArea}'
                : place.administrativeArea!;
          }
          if (place.country != null && place.country!.isNotEmpty) {
            address += address.isNotEmpty ? ', ${place.country}' : place.country!;
          }

          if (address.isNotEmpty) {
            _locationController.text = address;
          } else {
            _locationController.text =
                'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
          }
        } else {
          _locationController.text =
              'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
        }
      } catch (e) {
        // Si falla la geocodificación, usar solo las coordenadas
        _locationController.text =
            'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Ubicación obtenida exitosamente'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al obtener ubicación: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Crear documento del proyecto
      final projectRef =
          FirebaseFirestore.instance.collection('projects').doc();

      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'type': _selectedType,
        'adminId': user.uid,
        'workers': int.parse(_workersController.text),
        'startDate': Timestamp.fromDate(_startDate),
        'endDate': Timestamp.fromDate(_endDate),
        'createdAt': FieldValue.serverTimestamp(),
        'status': _selectedStatus,
        if (_locationController.text.isNotEmpty)
          'location': _locationController.text.trim(),
        if (_latitude != null && _longitude != null) ...{
          'latitude': _latitude,
          'longitude': _longitude,
        },
        if (_clientController.text.isNotEmpty)
          'client': _clientController.text.trim(),
        if (_budgetController.text.isNotEmpty)
          'budget': double.parse(_budgetController.text),
      };

      await projectRef.set(projectData);

      // Crear relación usuario-proyecto (el admin es miembro automáticamente)
      await FirebaseFirestore.instance.collection('projectUsers').add({
        'projectId': projectRef.id,
        'userId': user.uid,
        'role': 'admin',
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Mostrar éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('¡Proyecto creado exitosamente!'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Regresar al home
      Navigator.pop(context, true); // Retornar true para indicar éxito
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al crear proyecto: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }
}
