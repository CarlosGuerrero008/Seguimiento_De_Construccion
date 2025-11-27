import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SectionMaterialsScreen extends StatefulWidget {
  final String projectId;
  final String sectionId;
  final String sectionName;

  const SectionMaterialsScreen({
    Key? key,
    required this.projectId,
    required this.sectionId,
    required this.sectionName,
  }) : super(key: key);

  @override
  _SectionMaterialsScreenState createState() => _SectionMaterialsScreenState();
}

class _SectionMaterialsScreenState extends State<SectionMaterialsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materiales - ${widget.sectionName}'),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(child: _buildMaterialsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAssignMaterialDialog,
        icon: Icon(Icons.add_shopping_cart),
        label: Text('Asignar Material'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materialAssignments')
          .where('projectId', isEqualTo: widget.projectId)
          .where('sectionId', isEqualTo: widget.sectionId)
          .snapshots(),
      builder: (context, snapshot) {
        double totalUsedCost = 0;
        int totalMaterials = 0;

        if (snapshot.hasData) {
          totalMaterials = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final quantityUsed = (data['quantityUsed'] ?? 0).toDouble();
            final unitCost = (data['unitCost'] ?? 0).toDouble();
            totalUsedCost += quantityUsed * unitCost;
          }
        }

        return Card(
          margin: EdgeInsets.all(16),
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Materiales Asignados',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '$totalMaterials materiales',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green),
                          Text(
                            '\$${totalUsedCost.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                          Text(
                            'Costo Usado',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materialAssignments')
          .where('projectId', isEqualTo: widget.projectId)
          .where('sectionId', isEqualTo: widget.sectionId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        final materials = snapshot.data!.docs;

        if (materials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay materiales asignados',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                Text(
                  'Presiona el botón + para asignar',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16),
          itemCount: materials.length,
          itemBuilder: (context, index) {
            final doc = materials[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildMaterialCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildMaterialCard(String materialId, Map<String, dynamic> data) {
    final quantityPlanned = (data['quantityPlanned'] ?? 0).toDouble();
    final quantityUsed = (data['quantityUsed'] ?? 0).toDouble();
    final unitCost = (data['unitCost'] ?? 0).toDouble();
    final status = data['status'] ?? 'Pendiente';
    final unit = data['unit'] ?? 'unidades';

    final usagePercentage = quantityPlanned > 0
        ? (quantityUsed / quantityPlanned * 100)
        : 0.0;

    Color statusColor;
    switch (status) {
      case 'Entregado':
        statusColor = Colors.green;
        break;
      case 'En tránsito':
        statusColor = Colors.orange;
        break;
      case 'Agotado':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: EdgeInsets.all(12),
        title: Text(
          data['name'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.inventory, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Usado: ${quantityUsed.toStringAsFixed(1)} / ${quantityPlanned.toStringAsFixed(1)} $unit',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Costo: \$${(quantityUsed * unitCost).toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 13),
                ),
              ],
            ),
            SizedBox(height: 8),
            LinearProgressIndicator(
              value: (usagePercentage / 100).clamp(0.0, 1.0),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                usagePercentage > 100 ? Colors.red :
                usagePercentage > 75 ? Colors.orange : Colors.green,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '${usagePercentage.toStringAsFixed(1)}% utilizado',
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        onTap: () => _showEditUsageDialog(materialId, data),
      ),
    );
  }

  void _showAssignMaterialDialog() async {
    // Obtener materiales generales del proyecto
    final generalMaterials = await FirebaseFirestore.instance
        .collection('materials')
        .where('projectId', isEqualTo: widget.projectId)
        .where('sectionId', isNull: true)
        .get();

    if (generalMaterials.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No hay materiales generales disponibles. Primero agrega materiales al proyecto.'),
          backgroundColor: Colors.orange,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
      return;
    }

    // Obtener asignaciones existentes en esta sección
    final existingAssignments = await FirebaseFirestore.instance
        .collection('materialAssignments')
        .where('projectId', isEqualTo: widget.projectId)
        .where('sectionId', isEqualTo: widget.sectionId)
        .get();

    // Crear set de IDs de materiales ya asignados
    final assignedMaterialIds = existingAssignments.docs
        .map((doc) => doc.data()['materialId'] as String)
        .toSet();

    showDialog(
      context: context,
      builder: (context) {
        String? selectedMaterialId;
        Map<String, dynamic>? selectedMaterialData;
        double availableQuantity = 0;
        final quantityController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('Asignar Material a Sección'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Selecciona el material',
                      border: OutlineInputBorder(),
                      helperText: 'Solo se muestran materiales no asignados',
                      helperMaxLines: 2,
                    ),
                    items: generalMaterials.docs
                        .where((doc) => !assignedMaterialIds.contains(doc.id))
                        .map((doc) {
                      final data = doc.data();
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(
                          '${data['name']} (${data['quantityPlanned']} ${data['unit']})',
                        ),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value != null) {
                        // Obtener datos del material
                        final materialDoc = await FirebaseFirestore.instance
                            .collection('materials')
                            .doc(value)
                            .get();

                        final materialData = materialDoc.data()!;
                        final totalPlanned = (materialData['quantityPlanned'] ?? 0).toDouble();

                        // Calcular total ya asignado a todas las secciones
                        final allAssignments = await FirebaseFirestore.instance
                            .collection('materialAssignments')
                            .where('materialId', isEqualTo: value)
                            .get();

                        double totalAssigned = 0;
                        for (var doc in allAssignments.docs) {
                          totalAssigned += (doc.data()['quantityPlanned'] ?? 0).toDouble();
                        }

                        setState(() {
                          selectedMaterialId = value;
                          selectedMaterialData = materialData;
                          availableQuantity = totalPlanned - totalAssigned;
                        });
                      }
                    },
                  ),
                  if (selectedMaterialId != null) ...[
                    SizedBox(height: 12),
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: availableQuantity > 0 ? Colors.green.shade50 : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: availableQuantity > 0 ? Colors.green : Colors.red,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            availableQuantity > 0 ? Icons.check_circle : Icons.warning,
                            color: availableQuantity > 0 ? Colors.green : Colors.red,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Disponible: ${availableQuantity.toStringAsFixed(1)} ${selectedMaterialData!['unit']}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: availableQuantity > 0 ? Colors.green.shade900 : Colors.red.shade900,
                                  ),
                                ),
                                Text(
                                  'Total: ${selectedMaterialData!['quantityPlanned']} ${selectedMaterialData!['unit']}',
                                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  TextField(
                    controller: quantityController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad planificada para esta sección',
                      border: OutlineInputBorder(),
                      suffixText: selectedMaterialData?['unit'] ?? '',
                      helperText: selectedMaterialId != null
                          ? 'Máximo: ${availableQuantity.toStringAsFixed(1)}'
                          : null,
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    enabled: selectedMaterialId != null && availableQuantity > 0,
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
                  if (selectedMaterialId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Selecciona un material')),
                    );
                    return;
                  }

                  if (quantityController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ingresa la cantidad')),
                    );
                    return;
                  }

                  final requestedQuantity = double.tryParse(quantityController.text) ?? 0;

                  // Validar que no exceda el disponible
                  if (requestedQuantity > availableQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'La cantidad solicitada (${requestedQuantity.toStringAsFixed(1)}) excede lo disponible (${availableQuantity.toStringAsFixed(1)} ${selectedMaterialData!['unit']})'
                        ),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 4),
                      ),
                    );
                    return;
                  }

                  if (requestedQuantity <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('La cantidad debe ser mayor a 0')),
                    );
                    return;
                  }

                  try {
                    // Crear asignación en materialAssignments
                    await FirebaseFirestore.instance.collection('materialAssignments').add({
                      'materialId': selectedMaterialId,
                      'projectId': widget.projectId,
                      'sectionId': widget.sectionId,
                      'sectionName': widget.sectionName,
                      'name': selectedMaterialData!['name'],
                      'description': selectedMaterialData!['description'],
                      'unit': selectedMaterialData!['unit'],
                      'quantityPlanned': requestedQuantity,
                      'quantityUsed': 0.0,
                      'unitCost': selectedMaterialData!['unitCost'],
                      'status': 'Pendiente',
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('✓ Material asignado exitosamente'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Error: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                child: Text('Asignar'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditUsageDialog(String assignmentId, Map<String, dynamic> data) {
    final quantityUsedController = TextEditingController(
      text: data['quantityUsed']?.toString() ?? '0',
    );
    final quantityPlanned = (data['quantityPlanned'] ?? 0).toDouble();
    String selectedStatus = data['status'] ?? 'Pendiente';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Actualizar Uso del Material'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['name'] ?? 'Sin nombre',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Cantidad planificada: ${quantityPlanned.toStringAsFixed(1)} ${data['unit']}',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                Divider(height: 24),
                TextField(
                  controller: quantityUsedController,
                  decoration: InputDecoration(
                    labelText: 'Cantidad Usada',
                    border: OutlineInputBorder(),
                    suffixText: data['unit'],
                    helperText: 'Máximo: ${quantityPlanned.toStringAsFixed(1)}',
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'Pendiente',
                    'En uso',
                    'Completado',
                    'Agotado'
                  ].map((status) {
                    return DropdownMenuItem(
                      value: status,
                      child: Text(status),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => selectedStatus = value!);
                  },
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
                final newQuantityUsed = double.tryParse(quantityUsedController.text) ?? 0;

                // Validar que no exceda lo planificado
                if (newQuantityUsed > quantityPlanned) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'La cantidad usada (${newQuantityUsed.toStringAsFixed(1)}) no puede exceder lo planificado (${quantityPlanned.toStringAsFixed(1)})'
                      ),
                      backgroundColor: Colors.red,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  return;
                }

                try {
                  final oldQuantityUsed = (data['quantityUsed'] ?? 0).toDouble();
                  final materialId = data['materialId'];

                  // 1. Actualizar la asignación
                  await FirebaseFirestore.instance
                      .collection('materialAssignments')
                      .doc(assignmentId)
                      .update({
                    'quantityUsed': newQuantityUsed,
                    'status': selectedStatus,
                  });

                  // 2. Actualizar el material general
                  // Obtener el material general
                  final materialDoc = await FirebaseFirestore.instance
                      .collection('materials')
                      .doc(materialId)
                      .get();

                  if (materialDoc.exists) {
                    final currentTotalUsed = (materialDoc.data()!['quantityUsed'] ?? 0).toDouble();

                    // Calcular el nuevo total: restar el uso anterior de esta asignación y sumar el nuevo
                    final newTotalUsed = currentTotalUsed - oldQuantityUsed + newQuantityUsed;

                    // Actualizar el material general
                    await FirebaseFirestore.instance
                        .collection('materials')
                        .doc(materialId)
                        .update({
                      'quantityUsed': newTotalUsed,
                    });
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✓ Material actualizado. Inventario global sincronizado.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
