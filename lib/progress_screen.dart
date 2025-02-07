import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ProgressPage extends StatefulWidget {
  @override
  _ProgressPageState createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  List<dynamic> progressData = [];
  DateTime? selectedDate;
  List<DateTime> loggedDates = [];
  final storage = FlutterSecureStorage();
  bool hasWorkedOut = false;
  Map<String, int> bodyRegionSets = {
    'BACK': 0,
    'CHEST': 0,
    'ARMS': 0,
    'LEGS': 0,
    'SHOULDERS': 0,
    'CORE': 0,
  };
  List<FlSpot> weightData = [];
  List<String> progressPictures = [];

  @override
  void initState() {
    super.initState();
    checkWorkouts();
    _fetchProgressData();
  }

  Future<void> checkWorkouts() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No token found');
    }
    final response = await http.get(
      Uri.parse('http://192.168.1.138:5000/api/workouts/all'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );
    if (response.statusCode == 200) {
      final workouts = json.decode(response.body);
      setState(() {
        hasWorkedOut = workouts.isNotEmpty;
        if (hasWorkedOut) {
          final bodyPartMapping = {
            'BACK': 'BACK',
            'CHEST': 'CHEST',
            'LOWER ARMS': 'ARMS',
            'UPPER ARMS': 'ARMS',
            'LOWER LEGS': 'LEGS',
            'UPPER LEGS': 'LEGS',
            'NECK': 'SHOULDERS',
            'SHOULDERS': 'SHOULDERS',
            'WAIST': 'CORE'
          };
          for (var workout in workouts) {
            for (var exercise in workout['exercises']) {
              final bodyPart = bodyPartMapping[exercise['bodyPart'].toUpperCase()] ?? exercise['bodyPart'].toUpperCase();
              if (bodyRegionSets.containsKey(bodyPart)) {
                bodyRegionSets[bodyPart] = (bodyRegionSets[bodyPart] ?? 0) + (exercise['sets'].length as int);
              }
            }
          }
        }
      });
    } else {
      throw Exception('Failed to load workouts');
    }
  }

  Future<void> _fetchProgressData() async {
    String? token = await storage.read(key: 'auth_token');
    if (token == null) {
      throw Exception('No token found');
    }
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.138:5000/api/progress/progress'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final progress = json.decode(response.body);
        setState(() {
          weightData = progress.map<FlSpot>((entry) {
            final date = DateTime.parse(entry['date']);
            final weight = entry['bodyMeasurements']?['weight'];
            return FlSpot(date.millisecondsSinceEpoch.toDouble(), weight?.toDouble() ?? 0.0);
          }).toList();
          weightData.sort((a, b) => a.x.compareTo(b.x));
          loggedDates = progress.map<DateTime>((entry) => DateTime.parse(entry['date'])).toList();
          progressPictures = progress.map<String>((entry) => entry['progressPictures']?.first as String? ?? '').toList();
        });
      } else {
        throw Exception('Failed to load progress data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching progress data: $e');
      throw Exception('Failed to load progress data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/profile');
          },
        ),
        title: Text(
          'PROGRESS',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 20),
              Center(
                child: Image.asset(
                  hasWorkedOut ? 'assets/images/heatmapFB.png' : 'assets/images/heatmap0.png',
                  height: 280,
                ),
              ),
              Text(
                'MUSCLE HEATMAP',
                style: TextStyle(
                  color: Color(0xFFFF8000),
                  fontSize: 16,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 40),
              Text(
                'REGIONS WORKED',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('BACK', bodyRegionSets['BACK'] ?? 0),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('CHEST', bodyRegionSets['CHEST'] ?? 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('ARMS', bodyRegionSets['ARMS'] ?? 0),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('LEGS', bodyRegionSets['LEGS'] ?? 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('SHOULDERS', bodyRegionSets['SHOULDERS'] ?? 0),
                          ),
                        ),
                      ),
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: SizedBox(
                            height: 80,
                            child: _buildRegionCard('CORE', bodyRegionSets['CORE'] ?? 0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              SizedBox(height: 40),
              Text(
                'WEIGHT PROGRESS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              _buildProgressChart(),
              SizedBox(height: 40),
              Text(
                'your pictures',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              _buildProgressPictures(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRegionCard(String region, int sets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Color(0xFFFF8000), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(height: 8),
            Text(
              region,
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontFamily: 'Chaney',
              ),
            ),
            SizedBox(height: 4),
            Text(
              '$sets Sets',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressChart() {
    return Container(
      height: 300,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Color(0xFFFF8000), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: false,
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
                  if (loggedDates.any((loggedDate) => loggedDate.isAtSameMomentAs(date))) {
                    final formattedDate = DateFormat('MM/dd').format(date);
                    return Padding(
                      padding: const EdgeInsets.only(top: 2.0),
                      child: Text(
                        formattedDate,
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  } else {
                    return Container();
                  }
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weightData,
              isCurved: true,
              gradient: LinearGradient(
                colors: [Color(0xFFFF8000), Color(0xFFFF8000)],
              ),
              barWidth: 4,
              belowBarData: BarAreaData(show: false),
              dotData: FlDotData(show: true),
            ),
          ],
          minY: weightData.isNotEmpty
              ? weightData.map((e) => e.y).reduce((a, b) => a < b ? a : b)
              : 0,
          maxY: weightData.isNotEmpty
              ? weightData.map((e) => e.y).reduce((a, b) => a > b ? a : b)
              : 0,
        ),
      ),
    );
  }

  Widget _buildProgressPictures() {
    return Container(
      height: 300,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: progressPictures.length,
        itemBuilder: (context, index) {
          final base64String = progressPictures[index];
          final date = loggedDates[index];
          if (base64String.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(
                      base64Decode(base64String),
                      fit: BoxFit.cover,
                      height: 250,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    DateFormat('MM/dd/yyyy').format(date),
                    style: TextStyle(color: Color(0xFFFF8000)),
                  ),
                ],
              ),
            );
          } else {
            return Container();
          }
        },
      ),
    );
  }
}