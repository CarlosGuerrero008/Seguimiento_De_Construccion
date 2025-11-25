import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProgressSection extends StatelessWidget {
  final String projectId;

  const ProgressSection({
    Key? key,
    required this.projectId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }

        var sections = snapshot.data!.docs;
        if (sections.isEmpty) {
          return SizedBox.shrink();
        }

        // Calcular progreso promedio
        double totalProgress = 0;
        for (var section in sections) {
          var data = section.data() as Map<String, dynamic>;
          totalProgress += (data['progressPercentage'] ?? 0).toDouble();
        }
        double averageProgress = sections.isNotEmpty ? totalProgress / sections.length : 0;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 16),
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isDarkMode ? Colors.blueGrey[800]! : Colors.blue[50]!,
                isDarkMode ? Colors.blueGrey[900]! : Colors.blue[100]!,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Text(
                'Progreso General del Proyecto',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 20),
              CircularPercentIndicator(
                radius: 80.0,
                lineWidth: 12.0,
                percent: averageProgress / 100,
                center: Text(
                  '${averageProgress.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                progressColor: averageProgress < 30
                    ? Colors.red
                    : averageProgress < 70
                        ? Colors.orange
                        : Colors.green,
                backgroundColor: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                circularStrokeCap: CircularStrokeCap.round,
              ),
              SizedBox(height: 16),
              Text(
                '${sections.length} ${sections.length == 1 ? "sección" : "secciones"} en progreso',
                style: TextStyle(
                  fontSize: 14,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
