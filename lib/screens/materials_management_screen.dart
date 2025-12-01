import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:intl/intl.dart';

class MaterialsManagementScreen extends StatefulWidget {
  final String projectId;
  final String projectName;

  const MaterialsManagementScreen({
    Key? key,
    required this.projectId,
    required this.projectName,
  }) : super(key: key);

  @override
  _MaterialsManagementScreenState createState() =>
      _MaterialsManagementScreenState();
}

class _MaterialsManagementScreenState extends State<MaterialsManagementScreen> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');
  String _filterStatus = 'Todos';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Materiales - ${widget.projectName}'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              setState(() {
                _filterStatus = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Todos', child: Text('Todos')),
              PopupMenuItem(value: 'Pendiente', child: Text('Pendiente')),
              PopupMenuItem(value: 'En tránsito', child: Text('En tránsito')),
              PopupMenuItem(value: 'Entregado', child: Text('Entregado')),
              PopupMenuItem(value: 'Agotado', child: Text('Agotado')),
            ],
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.filter_list),
                  SizedBox(width: 4),
                  Text(_filterStatus, style: TextStyle(fontSize: 14)),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSummaryCard(),
          Expanded(child: _buildMaterialsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddMaterialDialog,
        icon: Icon(Icons.add),
        label: Text('Agregar Material'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSummaryCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materials')
          .where('projectId', isEqualTo: widget.projectId)
          .where('sectionId', isNull: true) // Solo materiales generales
          .snapshots(),
      builder: (context, snapshot) {
        double totalPlannedCost = 0;
        double totalUsedCost = 0;
        int totalMaterials = 0;
        int deliveredCount = 0;

        if (snapshot.hasData) {
          totalMaterials = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final quantityPlanned = (data['quantityPlanned'] ?? 0).toDouble();
            final quantityUsed = (data['quantityUsed'] ?? 0).toDouble();
            final unitCost = (data['unitCost'] ?? 0).toDouble();

            totalPlannedCost += quantityPlanned * unitCost;
            totalUsedCost += quantityUsed * unitCost;

            if (data['status'] == 'Entregado') deliveredCount++;
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildSummaryStat(
                      'Total Materiales',
                      totalMaterials.toString(),
                      Icons.inventory,
                      Colors.blue,
                    ),
                    _buildSummaryStat(
                      'Entregados',
                      deliveredCount.toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildCostStat(
                      'Presupuestado',
                      totalPlannedCost,
                      Colors.orange,
                    ),
                    _buildCostStat(
                      'Gastado',
                      totalUsedCost,
                      Colors.red,
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

  Widget _buildSummaryStat(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildCostStat(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        SizedBox(height: 4),
        Text(
          '\$${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materials')
          .where('projectId', isEqualTo: widget.projectId)
          .where('sectionId', isNull: true) // Solo materiales generales
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var materials = snapshot.data!.docs;

        // Filtrar por estado
        if (_filterStatus != 'Todos') {
          materials = materials.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['status'] == _filterStatus;
          }).toList();
        }

        if (materials.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'No hay materiales registrados',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Presiona + para agregar uno',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 100),
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
    final unit = data['unit'] ?? 'unidades';
    final status = data['status'] ?? 'Pendiente';
    final unitCost = (data['unitCost'] ?? 0).toDouble();

    final usagePercentage =
        quantityPlanned > 0 ? (quantityUsed / quantityPlanned * 100) : 0;

    // Obtener asignaciones para mostrar disponibilidad
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('materialAssignments')
          .where('materialId', isEqualTo: materialId)
          .snapshots(),
      builder: (context, assignmentsSnapshot) {
        double totalAssigned = 0;
        int sectionsCount = 0;

        if (assignmentsSnapshot.hasData) {
          sectionsCount = assignmentsSnapshot.data!.docs.length;
          for (var doc in assignmentsSnapshot.data!.docs) {
            totalAssigned += (doc.data() as Map<String, dynamic>)['quantityPlanned'] ?? 0;
          }
        }

        final available = quantityPlanned - totalAssigned;

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
      margin: EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.inventory_2, color: statusColor),
        ),
        title: Text(
          data['name'] ?? 'Sin nombre',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Cantidad: ${quantityUsed.toStringAsFixed(1)} / ${quantityPlanned.toStringAsFixed(1)} $unit',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 4),
            LinearPercentIndicator(
              lineHeight: 8.0,
              percent: (usagePercentage / 100).clamp(0, 1),
              backgroundColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[700]
                  : Colors.grey[300],
              progressColor: usagePercentage < 50
                  ? Colors.green
                  : usagePercentage < 90
                      ? Colors.orange
                      : Colors.red,
              barRadius: Radius.circular(10),
            ),
          ],
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (data['description'] != null) ...[
                  Text(
                    'Descripción:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    data['description'],
                    style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white
                          : Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo unitario:',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      '\$${unitCost.toStringAsFixed(2)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo total planificado:',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      '\$${(quantityPlanned * unitCost).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Costo utilizado:',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                    Text(
                      '\$${(quantityUsed * unitCost).toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                if (data['supplier'] != null) ...[
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.store, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Proveedor: ${data['supplier']}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                if (data['deliveryDate'] != null) ...[
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.local_shipping, size: 16, color: Colors.grey),
                      SizedBox(width: 8),
                      Text(
                        'Entrega: ${dateFormat.format((data['deliveryDate'] as Timestamp).toDate())}',
                        style: TextStyle(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ],
                SizedBox(height: 16),
                // Mostrar inventario disponible
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? (available > 0 ? Colors.blue.shade900.withOpacity(0.3) : Colors.grey.shade800)
                        : (available > 0 ? Colors.blue.shade50 : Colors.grey.shade100),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? (available > 0 ? Colors.blue.shade700 : Colors.grey.shade700)
                          : (available > 0 ? Colors.blue.shade200 : Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            size: 18,
                            color: available > 0 ? Colors.blue : Colors.grey,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Control de Inventario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Asignado a secciones:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '${totalAssigned.toStringAsFixed(1)} $unit',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Disponible:',
                            style: TextStyle(
                              fontSize: 11,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                          Text(
                            '${available.toStringAsFixed(1)} $unit',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: available > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                      if (sectionsCount > 0) ...[
                        SizedBox(height: 4),
                        Text(
                          'Usado en $sectionsCount ${sectionsCount == 1 ? 'sección' : 'secciones'}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => _showEditMaterialDialog(materialId, data),
                      icon: Icon(Icons.edit, size: 18),
                      label: Text('Editar'),
                    ),
                    SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _deleteMaterial(materialId),
                      icon: Icon(Icons.delete, size: 18, color: Colors.red),
                      label: Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ),
                  ],
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

  void _showAddMaterialDialog() {
    _showMaterialDialog();
  }

  void _showEditMaterialDialog(
      String materialId, Map<String, dynamic> currentData) {
    _showMaterialDialog(materialId: materialId, currentData: currentData);
  }

  void _showMaterialDialog({String? materialId, Map<String, dynamic>? currentData}) {
    final isEditing = materialId != null;
    final nameController =
        TextEditingController(text: currentData?['name'] ?? '');
    final descriptionController =
        TextEditingController(text: currentData?['description'] ?? '');
    final quantityPlannedController = TextEditingController(
        text: currentData?['quantityPlanned']?.toString() ?? '');
    final quantityUsedController = TextEditingController(
        text: currentData?['quantityUsed']?.toString() ?? '0');
    final unitCostController =
        TextEditingController(text: currentData?['unitCost']?.toString() ?? '');
    final supplierController =
        TextEditingController(text: currentData?['supplier'] ?? '');

    String selectedUnit = currentData?['unit'] ?? 'm³';
    String selectedStatus = currentData?['status'] ?? 'Pendiente';
    DateTime? deliveryDate = currentData?['deliveryDate'] != null
        ? (currentData!['deliveryDate'] as Timestamp).toDate()
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(isEditing ? 'Editar Material' : 'Agregar Material'),
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
                ),
                SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descripción (opcional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: quantityPlannedController,
                        decoration: InputDecoration(
                          labelText: 'Cantidad planificada',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.numberWithOptions(decimal: true),
                      ),
                    ),
                    SizedBox(width: 8),
                    DropdownButton<String>(
                      value: selectedUnit,
                      items: ['m³', 'm²', 'm', 'kg', 'ton', 'unidades', 'cajas']
                          .map((unit) => DropdownMenuItem(
                                value: unit,
                                child: Text(unit),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          selectedUnit = value!;
                        });
                      },
                    ),
                  ],
                ),
                if (isEditing) ...[
                  SizedBox(height: 12),
                  TextField(
                    controller: quantityUsedController,
                    decoration: InputDecoration(
                      labelText: 'Cantidad utilizada',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                ],
                SizedBox(height: 12),
                TextField(
                  controller: unitCostController,
                  decoration: InputDecoration(
                    labelText: 'Costo unitario (\$)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
                SizedBox(height: 12),
                TextField(
                  controller: supplierController,
                  decoration: InputDecoration(
                    labelText: 'Proveedor (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: selectedStatus,
                  decoration: InputDecoration(
                    labelText: 'Estado',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Pendiente', 'En tránsito', 'Entregado', 'Agotado']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(status),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedStatus = value!;
                    });
                  },
                ),
                SizedBox(height: 12),
                ListTile(
                  title: Text('Fecha de entrega (opcional)'),
                  subtitle: Text(
                    deliveryDate != null
                        ? DateFormat('dd/MM/yyyy').format(deliveryDate!)
                        : 'No seleccionada',
                  ),
                  trailing: Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: deliveryDate ?? DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() {
                        deliveryDate = picked;
                      });
                    }
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
                if (nameController.text.trim().isEmpty ||
                    quantityPlannedController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Por favor completa los campos requeridos')),
                  );
                  return;
                }

                final materialData = {
                  'projectId': widget.projectId,
                  'sectionId': null, // Material general del proyecto
                  'name': nameController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'unit': selectedUnit,
                  'quantityPlanned':
                      double.tryParse(quantityPlannedController.text) ?? 0,
                  'quantityUsed':
                      double.tryParse(quantityUsedController.text) ?? 0,
                  'unitCost': double.tryParse(unitCostController.text) ?? 0,
                  'supplier': supplierController.text.trim(),
                  'status': selectedStatus,
                  'deliveryDate': deliveryDate != null
                      ? Timestamp.fromDate(deliveryDate!)
                      : null,
                  if (!isEditing) 'createdAt': FieldValue.serverTimestamp(),
                };

                try {
                  if (isEditing) {
                    await FirebaseFirestore.instance
                        .collection('materials')
                        .doc(materialId)
                        .update(materialData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('materials')
                        .add(materialData);
                  }

                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(isEditing
                          ? 'Material actualizado'
                          : 'Material agregado'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _deleteMaterial(String materialId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar Material'),
        content: Text('¿Estás seguro de que deseas eliminar este material?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('materials')
                    .doc(materialId)
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
