import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/percent_indicator.dart';

class ProjectDashboardScreen extends StatefulWidget {
  final String projectId;
  final Map<String, dynamic> projectData;

  const ProjectDashboardScreen({
    Key? key,
    required this.projectId,
    required this.projectData,
  }) : super(key: key);

  @override
  _ProjectDashboardScreenState createState() => _ProjectDashboardScreenState();
}

class _ProjectDashboardScreenState extends State<ProjectDashboardScreen> {
  final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard - ${widget.projectData['name']}'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProjectSummaryCard(),
            SizedBox(height: 16),
            _buildTimelineCard(),
            SizedBox(height: 16),
            _buildProgressCard(),
            SizedBox(height: 16),
            _buildReportsStatisticsCard(),
            SizedBox(height: 16),
            _buildSectionsProgressChart(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectSummaryCard() {
    final startDate =
        (widget.projectData['startDate'] as Timestamp?)?.toDate() ??
            DateTime.now();
    final endDate =
        (widget.projectData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final totalDays = endDate.difference(startDate).inDays;
    final elapsed = DateTime.now().difference(startDate).inDays;
    final remaining = endDate.difference(DateTime.now()).inDays;

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.business, color: Colors.blue, size: 28),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Resumen del Proyecto',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            Divider(height: 24),
            _buildInfoRow('Tipo', widget.projectData['type'] ?? 'N/A'),
            _buildInfoRow('Trabajadores', widget.projectData['workers']?.toString() ?? 'N/A'),
            if (widget.projectData['client'] != null)
              _buildInfoRow('Cliente', widget.projectData['client']),
            if (widget.projectData['location'] != null)
              _buildInfoRow('Ubicación', widget.projectData['location']),
            _buildInfoRow('Inicio', dateFormat.format(startDate)),
            _buildInfoRow('Fin previsto', dateFormat.format(endDate)),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatChip(
                  'Total',
                  '$totalDays días',
                  Colors.blue,
                  Icons.calendar_today,
                ),
                _buildStatChip(
                  'Transcurridos',
                  '${elapsed > 0 ? elapsed : 0} días',
                  Colors.green,
                  Icons.check_circle,
                ),
                _buildStatChip(
                  'Restantes',
                  '${remaining > 0 ? remaining : 0} días',
                  remaining < 0 ? Colors.red : Colors.orange,
                  Icons.schedule,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '$label:',
            style: TextStyle(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[600],
          ),
        ),
        SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildTimelineCard() {
    final startDate =
        (widget.projectData['startDate'] as Timestamp?)?.toDate() ??
            DateTime.now();
    final endDate =
        (widget.projectData['endDate'] as Timestamp?)?.toDate() ?? DateTime.now();
    final now = DateTime.now();

    double timeProgress = 0;
    if (now.isBefore(startDate)) {
      timeProgress = 0;
    } else if (now.isAfter(endDate)) {
      timeProgress = 100;
    } else {
      final total = endDate.difference(startDate).inDays;
      final elapsed = now.difference(startDate).inDays;
      timeProgress = total > 0 ? (elapsed / total * 100).clamp(0, 100) : 0;
    }

    return Card(
      elevation: 4,
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Línea de Tiempo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 30.0,
              percent: timeProgress / 100,
              center: Text(
                '${timeProgress.toStringAsFixed(1)}% del tiempo',
                style: TextStyle(fontSize: 12, color: Colors.white),
              ),
              backgroundColor: Colors.grey[300],
              progressColor: timeProgress < 30
                  ? Colors.green
                  : timeProgress < 70
                      ? Colors.orange
                      : Colors.red,
              barRadius: Radius.circular(15),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        double totalProgress = 0;
        int sectionCount = 0;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          sectionCount = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            totalProgress +=
                (doc.data() as Map<String, dynamic>)['progressPercentage'] ?? 0;
          }
          totalProgress = sectionCount > 0 ? totalProgress / sectionCount : 0;
        }

        // Calcular progreso temporal
        final startDate =
            (widget.projectData['startDate'] as Timestamp?)?.toDate() ??
                DateTime.now();
        final endDate =
            (widget.projectData['endDate'] as Timestamp?)?.toDate() ??
                DateTime.now();
        final now = DateTime.now();

        double timeProgress = 0;
        if (now.isAfter(startDate) && now.isBefore(endDate)) {
          final total = endDate.difference(startDate).inDays;
          final elapsed = now.difference(startDate).inDays;
          timeProgress = total > 0 ? (elapsed / total * 100).clamp(0, 100) : 0;
        } else if (now.isAfter(endDate)) {
          timeProgress = 100;
        }

        final isDelayed = totalProgress < timeProgress;

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progreso General',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    if (isDelayed)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning, size: 16, color: Colors.red),
                            SizedBox(width: 4),
                            Text(
                              'Retrasado',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 80.0,
                            lineWidth: 15.0,
                            percent: totalProgress / 100,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${totalProgress.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Avance',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(context).brightness == Brightness.dark
                                        ? Colors.grey[400]
                                        : Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            progressColor: totalProgress < 30
                                ? Colors.red
                                : totalProgress < 70
                                    ? Colors.orange
                                    : Colors.green,
                            backgroundColor: Colors.grey[300]!,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Trabajo Realizado',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          CircularPercentIndicator(
                            radius: 80.0,
                            lineWidth: 15.0,
                            percent: timeProgress / 100,
                            center: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${timeProgress.toStringAsFixed(1)}%',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  'Tiempo',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            progressColor: Colors.blue,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[700]!
                                : Colors.grey[300]!,
                            circularStrokeCap: CircularStrokeCap.round,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Tiempo Transcurrido',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  '$sectionCount ${sectionCount == 1 ? "sección" : "secciones"} en total',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[400]
                        : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReportsStatisticsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('dailyReports')
          .where('projectId', isEqualTo: widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        int totalReports = 0;
        int totalPhotos = 0;
        int reportsWithGPS = 0;
        Map<String, int> reportsByContractor = {};

        if (snapshot.hasData) {
          totalReports = snapshot.data!.docs.length;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // Contar fotos
            final photos = List.from(data['photosBase64'] ?? data['photoUrls'] ?? []);
            totalPhotos += photos.length;

            // Contar GPS
            if (data['latitude'] != null && data['longitude'] != null) {
              reportsWithGPS++;
            }

            // Agrupar por contratista
            final contractor = data['contractorName'] ?? 'Sin nombre';
            reportsByContractor[contractor] =
                (reportsByContractor[contractor] ?? 0) + 1;
          }
        }

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Estadísticas de Reportes',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatColumn(
                      Icons.description,
                      totalReports.toString(),
                      'Reportes',
                      Colors.blue,
                    ),
                    _buildStatColumn(
                      Icons.photo_camera,
                      totalPhotos.toString(),
                      'Fotos',
                      Colors.green,
                    ),
                    _buildStatColumn(
                      Icons.location_on,
                      reportsWithGPS.toString(),
                      'Con GPS',
                      Colors.red,
                    ),
                  ],
                ),
                if (reportsByContractor.isNotEmpty) ...[
                  SizedBox(height: 16),
                  Divider(),
                  SizedBox(height: 8),
                  Text(
                    'Reportes por Contratista',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 8),
                  ...reportsByContractor.entries.map((entry) => Padding(
                        padding: EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.person, size: 16, color: Colors.grey),
                                SizedBox(width: 8),
                                Text(entry.key),
                              ],
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${entry.value}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 32),
        ),
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

  Widget _buildSectionsProgressChart() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('projectSections')
          .where('projectId', isEqualTo: widget.projectId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            elevation: 4,
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text('No hay secciones para mostrar'),
              ),
            ),
          );
        }

        final sections = snapshot.data!.docs;

        return Card(
          elevation: 4,
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Progreso por Sección',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 20),
                SizedBox(
                  height: 300,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: 100,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              if (value.toInt() >= sections.length) {
                                return Text('');
                              }
                              final section = sections[value.toInt()].data()
                                  as Map<String, dynamic>;
                              final name = section['name'] ?? '';
                              return Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text(
                                  name.length > 8
                                      ? '${name.substring(0, 8)}...'
                                      : name,
                                  style: TextStyle(fontSize: 10),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}%',
                                style: TextStyle(fontSize: 10),
                              );
                            },
                            reservedSize: 40,
                          ),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(
                        sections.length,
                        (index) {
                          final data =
                              sections[index].data() as Map<String, dynamic>;
                          final progress =
                              (data['progressPercentage'] ?? 0).toDouble();
                          return BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: progress,
                                color: progress < 30
                                    ? Colors.red
                                    : progress < 70
                                        ? Colors.orange
                                        : Colors.green,
                                width: 20,
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(6),
                                  topRight: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
