import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:percent_indicator/percent_indicator.dart';

class SectionCard extends StatelessWidget {
  final String sectionId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const SectionCard({
    Key? key,
    required this.sectionId,
    required this.data,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    double progress = (data['progressPercentage'] ?? 0).toDouble();
    
    return Card(
      elevation: 2,
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.construction,
                    color: Colors.orange,
                    size: 24,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      data['name'] ?? 'Sin nombre',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Badge de materiales
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('sectionMaterials')
                        .where('sectionId', isEqualTo: sectionId)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SizedBox.shrink();
                      }

                      final materials = snapshot.data!.docs;
                      final allAvailable = materials.every((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final available = (data['quantityAvailable'] ?? 0).toDouble();
                        final needed = (data['quantityNeeded'] ?? 0).toDouble();
                        return available >= needed;
                      });

                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: allAvailable ? Colors.green : Colors.red,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              allAvailable ? Icons.check_circle : Icons.warning,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 4),
                            Text(
                              allAvailable ? 'Disponible' : 'Sin materiales',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Icon(Icons.arrow_forward_ios, size: 16),
                ],
              ),
              if (data['description'] != null && data['description'].toString().isNotEmpty) ...[
                SizedBox(height: 8),
                Text(
                  data['description'],
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: LinearPercentIndicator(
                      lineHeight: 8,
                      percent: progress / 100,
                      backgroundColor: isDarkMode ? Colors.grey[800] : Colors.grey[300],
                      progressColor: progress < 30
                          ? Colors.red
                          : progress < 70
                              ? Colors.orange
                              : Colors.green,
                      barRadius: Radius.circular(4),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text(
                    '${progress.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              if (data['lastUpdated'] != null) ...[
                SizedBox(height: 8),
                Text(
                  'Última actualización: ${_formatDate(data['lastUpdated'])}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    try {
      DateTime date = (timestamp as Timestamp).toDate();
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}
