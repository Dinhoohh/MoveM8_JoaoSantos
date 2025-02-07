import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WorkoutPage extends StatelessWidget {
  final List<String> addedExercises;
  final _storage = FlutterSecureStorage();
  final Map<String, Map<String, dynamic>> _exerciseDetailsCache = {};

  WorkoutPage({Key? key, required this.addedExercises}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchSavedRoutines() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/routines/all');
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      throw Exception('No token found');
    }

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load saved routines');
    }
  }

  Future<bool> isAdmin() async {
    final token = await _storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return false;
    }

    final payload = json.decode(
        ascii.decode(base64.decode(base64.normalize(token.split('.')[1]))));
    print('Token payload: $payload');
    return payload['role'] == 'admin';
  }

  Future<Map<String, dynamic>> fetchExerciseDetails(String exerciseId) async {
    if (_exerciseDetailsCache.containsKey(exerciseId)) {
      return _exerciseDetailsCache[exerciseId]!;
    }

    final url = Uri.parse('https://exercisedb.p.rapidapi.com/exercises/exercise/$exerciseId');
    final headers = {
      'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
      'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
    };

    for (int attempt = 1; attempt <= 2; attempt++) {
      try {
        final response = await http.get(url, headers: headers);
        if (response.statusCode == 200) {
          final exerciseDetails = json.decode(response.body);
          _exerciseDetailsCache[exerciseId] = exerciseDetails;
          return exerciseDetails;
        } else {
          throw Exception('Failed to load exercise details');
        }
      } catch (e) {
        if (attempt == 2) {
          throw Exception('Failed to load exercise details after 2 attempts');
        }
      }
    }

    return {};
  }

  String capitalize(String input) {
    return input.split(' ').map((word) => word[0].toUpperCase() + word.substring(1)).join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Color(0xFF323232),
          selectedItemColor: Color(0xFFFF8000),
          unselectedItemColor: Color(0xFF7A7A7A), 
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushNamed(context, '/home');
                break;
              case 1:
                Navigator.pushNamed(context, '/workout');
                break;
              case 2:
                Navigator.pushNamed(context, '/profile');
                break;
            }
          },
          iconSize: 40,
            items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_filled),
              label: 'HOME',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_rounded),
              label: 'WORKOUT',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'PROFILE',
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'WORKOUTS',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWorkoutButton(context, 'Start Empty Workout', Icons.flash_on_outlined, margin: EdgeInsets.only(right: 8)),
                  _buildWorkoutButton(context, 'Last Workouts', Icons.loop_outlined, margin: EdgeInsets.only(left: 8)),
                ],
              ),
              SizedBox(height: 40),
              Text(
                'DISCOVER',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildWorkoutButton(context, 'Preset Routines', Icons.folder_outlined, margin: EdgeInsets.only(right: 8)),
                  _buildWorkoutButton(context, 'Challenges', Icons.auto_graph_outlined, margin: EdgeInsets.only(left: 8)),
                ],
              ),
              SizedBox(height: 40),
              FutureBuilder<bool>(
                future: isAdmin(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container();
                  } else if (snapshot.hasError || !snapshot.data!) {
                    print('Admin check error: ${snapshot.error}');
                    print('Admin check result: ${snapshot.data}');
                    return Container();
                  } else {
                    print('Admin section visible');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'ADMIN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Chaney',
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildWorkoutButton(context, 'Create Preset Routine', Icons.add_circle_outline, margin: EdgeInsets.only(right: 8)),
                        SizedBox(height: 40),
                      ],
                    );
                  }
                },
              ),
              Text(
                'MY ROUTINES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchSavedRoutines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Container();
                  } else {
                    final routines = snapshot.data!;
                    return Column(
                      children: routines.map((routine) {
                        final title = routine['title'] ?? 'No Title';
                        final exercises = (routine['exercises'] as List<dynamic>?)
                            ?.map((e) => e as Map<String, dynamic>)
                            .toList() ?? [];
                        return _buildRoutineCard(context, title, exercises);
                      }).toList(),
                    );
                  }
                },
              ),
              SizedBox(height: 25),
              if (addedExercises.isNotEmpty) ...[
                Text(
                  'ADDED EXERCISES',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontFamily: 'Chaney',
                  ),
                ),
                SizedBox(height: 20),
                Column(
                  children: addedExercises.map((exercise) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            exercise,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
                SizedBox(height: 40),
              ],
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/routine'); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFFFF8000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      minimumSize: Size(double.infinity, 56),
                    ),
                    child: Text(
                      'Create Routine',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWorkoutButton(BuildContext context, String label, IconData icon, {EdgeInsets margin = EdgeInsets.zero}) {
    return Flexible(
      fit: FlexFit.loose,
      child: Column(
        children: [
          GestureDetector(
            onTap: () {
              if (label == 'Start Empty Workout') {
                Navigator.pushNamed(context, '/quick_start');
              } else if (label == 'Challenges') {
                Navigator.pushNamed(context, '/challenges'); 
              } else if (label == 'Create Preset Routine') {
                Navigator.pushNamed(context, '/create_preset_routine');
              } else if (label == 'Preset Routines') {
                Navigator.pushNamed(context, '/preset_routine');
              }
            },
            child: Container(
              height: 100,
              margin: margin,
              decoration: BoxDecoration(
                color: Color(0xFFFF8000),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Center(
                child: Icon(icon, color: Colors.black, size: 50),
              ),
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoutineCard(BuildContext context, String title, List<Map<String, dynamic>> exercises) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Color(0xFF7A7A7A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontFamily: 'Chaney',
              ),
            ),
            SizedBox(height: 16),
            Column(
              children: exercises.take(3).map((exercise) {
                return FutureBuilder<Map<String, dynamic>>(
                  future: fetchExerciseDetails(exercise['exerciseId']),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return CircularProgressIndicator();
                    } else if (snapshot.hasError) {
                      return Text('Error loading exercise details');
                    } else {
                      final exerciseDetails = snapshot.data!;
                      final gifUrl = exerciseDetails['gifUrl'] ?? '';
                      return Padding(
                        padding: EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.black,
                              radius: 30,
                              child: ClipOval(
                                child: Image.network(
                                  gifUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      CircleAvatar(
                                        backgroundColor: Colors.black,
                                        radius: 20,
                                        child: Icon(Icons.error, color: Colors.white),
                                      ),
                                ),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    capitalize(exerciseDetails['name']),
                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                  ),
                                  SizedBox(height: 8),
                                ],
                              ),
                            ),
                            Text(
                              '${exercise['sets']?.length ?? 0} sets',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              }).toList(),
            ),
            if (exercises.length > 3)
              Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text(
                  '${exercises.length - 3} more exercises',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ),
            SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/current_workout',
                    arguments: {
                      'title': title,
                      'exercises': exercises,
                    },
                  );
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
          ],
        ),
      ),
    );
  }
}
