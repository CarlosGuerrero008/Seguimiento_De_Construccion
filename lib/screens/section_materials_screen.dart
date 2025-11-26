import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/material_item.dart';

class SectionMaterialsScreen extends StatefulWidget {
  final String sectionId;
  final String sectionName;
  final String projectId;

  SectionMaterialsScreen({
    required this.sectionId,
    required this.sectionName,
    required this.projectId,
  });

  @override
  _SectionMaterialsScreenState createState() => _SectionMaterialsScreenState();
}

class _SectionMaterialsScreenState extends State<SectionMaterialsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materiales - ${widget.sectionName}'),
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddMaterialDialog,
            tooltip: 'Agregar material',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMaterialsStatus(),
          Expanded(child: _buildMaterialsList()),
        ],
      ),
    );
  }

  Widget _buildMaterialsStatus() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sectionMaterials')
          .where('sectionId', isEqualTo: widget.sectionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return SizedBox.shrink();
        }

        final materials = snapshot.data!.docs
            .map((doc) => MaterialItem.fromFirestore(
                doc.id, doc.data() as Map<String, dynamic>))
            .toList();

        if (materials.isEmpty) {
          return SizedBox.shrink();
        }

        final allAvailable = materials.every((m) => m.isAvailable);
        final someAvailable = materials.any((m) => m.isAvailable);
        final missingCount = materials.where((m) => !m.isAvailable).length;

        Color statusColor;
        IconData statusIcon;
        String statusText;

        if (allAvailable) {
          statusColor = Colors.green;
          statusIcon = Icons.check_circle;
          statusText = 'Todos los materiales disponibles';
        } else if (someAvailable) {
          statusColor = Colors.orange;
          statusIcon = Icons.warning;
          statusText = '$missingCount ${missingCount == 1 ? "material faltante" : "materiales faltantes"}';
        } else {
          statusColor = Colors.red;
          statusIcon = Icons.error;
          statusText = 'Sin materiales disponibles';
        }

        return Container(
          width: double.infinity,
          padding: EdgeInsets.all(16),
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            border: Border.all(color: statusColor, width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 32),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${materials.length} ${materials.length == 1 ? "material registrado" : "materiales registrados"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('sectionMaterials')
          .where('sectionId', isEqualTo: widget.sectionId)
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  'No hay materiales registrados',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Presiona + para agregar uno',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final material = MaterialItem.fromFirestore(
              doc.id,
              doc.data() as Map<String, dynamic>,
            );
            return _buildMaterialCard(material);
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(MaterialItem material) {
    final isAvailable = material.isAvailable;
    final percentage = material.availabilityPercentage;
    final statusColor = percentage >= 100 ? Colors.green : 
                       percentage >= 50 ? Colors.orange : Colors.red;

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showEditMaterialDialog(material),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isAvailable ? Icons.check_circle : Icons.warning,
                      color: statusColor,
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          material.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${material.quantityAvailable} / ${material.quantityNeeded} ${material.unit}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.edit, color: Colors.blue),
                            SizedBox(width: 8),
                            Text('Editar'),
                          ],
                        ),
                        value: 'edit',
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(Icons.delete, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Eliminar'),
                          ],
                        ),
                        value: 'delete',
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'edit') {
                        _showEditMaterialDialog(material);
                      } else if (value == 'delete') {
                        _confirmDeleteMaterial(material);
                      }
                    },
                  ),
                ],
              ),
              SizedBox(height: 12),
              LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: Colors.grey[300],
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${percentage.toStringAsFixed(1)}% disponible',
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!isAvailable)
                    Text(
                      'Faltan ${(material.quantityNeeded - material.quantityAvailable).toStringAsFixed(1)} ${material.unit}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
              if (material.notes != null && material.notes!.isNotEmpty) ...[
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.note, size: 16, color: Colors.grey[600]),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          material.notes!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAddMaterialDialog() {
    final nameController = TextEditingController();
    final unitController = TextEditingController(text: 'unidades');
    final neededController = TextEditingController();
    final availableController = TextEditingController(text: '0');
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Agregar Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del material',
                  hintText: 'Ej: Cemento, Arena, Ladrillos',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: 'Unidad de medida',
                  hintText: 'Ej: m3, kg, unidades, sacos',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: neededController,
                decoration: InputDecoration(
                  labelText: 'Cantidad necesaria',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: availableController,
                decoration: InputDecoration(
                  labelText: 'Cantidad disponible',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  hintText: 'Proveedor, ubicación, etc.',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              if (nameController.text.trim().isEmpty ||
                  neededController.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Completa los campos requeridos')),
                );
                return;
              }

              try {
                await FirebaseFirestore.instance.collection('sectionMaterials').add({
                  'sectionId': widget.sectionId,
                  'projectId': widget.projectId,
                  'name': nameController.text.trim(),
                  'unit': unitController.text.trim(),
                  'quantityNeeded': double.parse(neededController.text.trim()),
                  'quantityAvailable': double.parse(availableController.text.trim()),
                  'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'lastUpdated': null,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Material agregado exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Agregar'),
          ),
        ],
      ),
    );
  }

  void _showEditMaterialDialog(MaterialItem material) {
    final nameController = TextEditingController(text: material.name);
    final unitController = TextEditingController(text: material.unit);
    final neededController = TextEditingController(text: material.quantityNeeded.toString());
    final availableController = TextEditingController(text: material.quantityAvailable.toString());
    final notesController = TextEditingController(text: material.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Material'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nombre del material',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              SizedBox(height: 16),
              TextField(
                controller: unitController,
                decoration: InputDecoration(
                  labelText: 'Unidad de medida',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: neededController,
                decoration: InputDecoration(
                  labelText: 'Cantidad necesaria',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: availableController,
                decoration: InputDecoration(
                  labelText: 'Cantidad disponible',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
              SizedBox(height: 16),
              TextField(
                controller: notesController,
                decoration: InputDecoration(
                  labelText: 'Notas (opcional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
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
              try {
                await FirebaseFirestore.instance
                    .collection('sectionMaterials')
                    .doc(material.id)
                    .update({
                  'name': nameController.text.trim(),
                  'unit': unitController.text.trim(),
                  'quantityNeeded': double.parse(neededController.text.trim()),
                  'quantityAvailable': double.parse(availableController.text.trim()),
                  'notes': notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  'lastUpdated': FieldValue.serverTimestamp(),
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Material actualizado exitosamente')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: Text('Actualizar'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteMaterial(MaterialItem material) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Confirmar eliminación'),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar "${material.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('sectionMaterials')
                    .doc(material.id)
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Material eliminado')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
