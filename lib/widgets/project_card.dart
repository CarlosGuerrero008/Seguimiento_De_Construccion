import 'package:flutter/material.dart';

class ProjectCard extends StatelessWidget {
  final String projectName;
  final String projectId;
  final VoidCallback onTap;

  const ProjectCard({
    Key? key,
    required this.projectName,
    required this.projectId,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: Icon(Icons.folder, color: Colors.blue, size: 40),
        title: Text(
          projectName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text('ID: $projectId'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
