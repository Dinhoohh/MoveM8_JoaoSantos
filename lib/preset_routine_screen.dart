import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'current_workout_screen.dart';

class PresetRoutineScreen extends StatefulWidget {
  @override
  _PresetRoutineScreenState createState() => _PresetRoutineScreenState();
}

class _PresetRoutineScreenState extends State<PresetRoutineScreen> {
  List<Map<String, dynamic>> routines = [];
  final _storage = FlutterSecureStorage();
  bool isAdmin = false;

  @override
  void initState() {
    super.initState();
    fetchRoutines();
    checkAdminStatus();
  }

  Future<void> checkAdminStatus() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final payload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1]))));
    setState(() {
      isAdmin = payload['role'] == 'admin';
    });
  }

  Future<void> fetchRoutines() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.138:5000/api/preset_routines'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        routines = data.map((routine) {
          List<Map<String, dynamic>> exercises = List<Map<String, dynamic>>.from(routine['exercises']);
          exercises = exercises.map((exercise) {
            exercise['name'] = _capitalizeFirstLetter(exercise['name']);
            return exercise;
          }).toList();
          return {
            'id': routine['_id'],
            'name': routine['name'],
            'description': routine['description'],
            'image': routine['image'],
            'goal': routine['goal'],
            'exercises': exercises,
          };
        }).toList();
      });
    } else {
      print('Failed to load routines');
    }
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1);
    }).join(' ');
  }

  Future<void> deleteRoutine(String id) async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.delete(
      Uri.parse('http://192.168.1.138:5000/api/preset_routines/$id'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        routines.removeWhere((routine) => routine['id'] == id);
      });
    } else {
      print('Failed to delete routine');
    }
  }

  Future<void> confirmDeleteRoutine(String id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.black,
          title: Text(
            'Confirm Delete',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  'Are you sure you want to delete this routine? This action cannot be undone.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                deleteRoutine(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> startPresetRoutine(Map<String, dynamic> routine) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CurrentWorkoutPage(
          title: routine['name'],
          exercises: routine['exercises'],
        ),
      ),
    );
  }

  bool _isBase64(String str) {
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          'ROUTINES FY',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          itemCount: routines.length,
          itemBuilder: (context, index) {
            final routine = routines[index];
            final image = routine['image'];
            Widget imageWidget;

            if (_isBase64(image)) {
              Uint8List imageBytes = base64Decode(image);
              imageWidget = ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.memory(
                  imageBytes,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      height: 240,
                      color: Color(0xFFFF8000),
                      child: Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              );
            } else {
              imageWidget = ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  image,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return Container(
                      height: 240,
                      color: Color(0xFFFF8000),
                      child: Center(
                        child: Icon(Icons.error, color: Colors.red),
                      ),
                    );
                  },
                ),
              );
            }

            return Card(
              color: Color(0xFF7A7A7A),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              elevation: 5,
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              child: GestureDetector(
                onLongPress: isAdmin
                    ? () {
                        confirmDeleteRoutine(routine['id']);
                      }
                    : null,
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: imageWidget,
                    ),
                    Container(
                      height: 240,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${routine['exercises'].length} exercises',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${routine['goal']}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Spacer(),
                          Align(
                            alignment: Alignment.center,
                            child: ElevatedButton(
                              onPressed: () {
                                startPresetRoutine(routine);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFFF8000),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 10, horizontal: 40),
                                child: Text(
                                  'Start',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Spacer(),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Text(
                              routine['name']!,
                              style: TextStyle(
                                fontSize: 16,
                                fontFamily: 'Chaney',
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 20.0, bottom: 20.0),
                            child: Text(
                              routine['description']!,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
