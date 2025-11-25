import 'package:flutter/material.dart';

class DeleteProjectDialog extends StatefulWidget {
  final Map<String, dynamic> projectData;
  final Function(Map<String, dynamic>) onDelete;

  const DeleteProjectDialog({
    Key? key,
    required this.projectData,
    required this.onDelete,
  }) : super(key: key);

  @override
  _DeleteProjectDialogState createState() => _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends State<DeleteProjectDialog> {
  final confirmController = TextEditingController();
  bool canDelete = false;

  @override
  void dispose() {
    confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectName = widget.projectData['name'] ?? '';

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.red, size: 30),
          SizedBox(width: 8),
          Expanded(child: Text('Eliminar Proyecto')),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Esta acción eliminará permanentemente el proyecto:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                projectName,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Esto eliminará:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text('• Todas las secciones del proyecto'),
            Text('• Todos los reportes diarios'),
            Text('• Todas las invitaciones'),
            Text('• Todo el historial de actualizaciones'),
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.orange[800]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Esta acción no se puede deshacer',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[900],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              'Para confirmar, escribe el nombre del proyecto:',
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 8),
            TextField(
              controller: confirmController,
              decoration: InputDecoration(
                hintText: projectName,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
              onChanged: (value) {
                setState(() {
                  canDelete = value.trim() == projectName;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: canDelete
              ? () {
                  Navigator.of(context).pop();
                  widget.onDelete(widget.projectData);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          child: Text('Eliminar Proyecto'),
        ),
      ],
    );
  }
}
