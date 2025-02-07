import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:typed_data';
import 'exercise_info_screen.dart';
import 'package:badges/badges.dart' as badges;

class HomeScreen extends StatelessWidget {
  final _storage = FlutterSecureStorage();
  final Map<String, Map<String, dynamic>> _exerciseDetailsCache = {};

  Future<Map<String, dynamic>> fetchChallenge() async {
    final response = await http.get(Uri.parse('http://192.168.1.138:5000/api/challenges'));
    if (response.statusCode == 200) {
      final List<dynamic> challenges = json.decode(response.body);
      if (challenges.isNotEmpty) {
        return challenges.first;
      } else {
        throw Exception('No challenges found');
      }
    } else {
      throw Exception('Failed to load challenge');
    }
  }

  Future<List<Map<String, dynamic>>> fetchChallenges() async {
    final response = await http.get(Uri.parse('http://192.168.1.138:5000/api/challenges'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body)).take(4).toList();
    } else {
      throw Exception('Failed to load challenges');
    }
  }

  Future<Map<String, dynamic>> fetchLatestWorkout() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/workouts/latest');
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
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load latest workout');
    }
  }

  Future<List<Map<String, dynamic>>> fetchPresetRoutines() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/preset_routines');
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
      return List<Map<String, dynamic>>.from(json.decode(response.body)).take(4).toList();
    } else {
      throw Exception('Failed to load preset routines');
    }
  }

  Future<int> fetchUnreadNotificationsCount() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/notifications/unread_count');
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
      return json.decode(response.body)['unreadCount'];
    } else {
      throw Exception('Failed to load unread notifications count');
    }
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

    try {
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final details = json.decode(response.body);
        _exerciseDetailsCache[exerciseId] = details;
        return details;
      } else {
        throw Exception('Failed to load exercise details');
      }
    } catch (e) {
      print('Error fetching exercise details: $e');
      throw Exception('Failed to load exercise details');
    }
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
        automaticallyImplyLeading: false, 
        backgroundColor: Colors.black,
        centerTitle: true, 
        title: Image.asset(
          'assets/images/logo.png', 
          height: 36,
        ),
        actions: [
          FutureBuilder<int>(
            future: fetchUnreadNotificationsCount(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return IconButton(
                  icon: Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                );
              } else if (snapshot.hasError) {
                return IconButton(
                  icon: Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.pushNamed(context, '/notifications');
                  },
                );
              } else {
                final unreadCount = snapshot.data!;
                return badges.Badge(
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  badgeContent: Text(
                    unreadCount.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                  showBadge: unreadCount > 0,
                  child: IconButton(
                    icon: Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                );
              }
            },
          ),
        ],
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CHALLENGES',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchChallenges(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0xFFFF8000));
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}'); 
                    return Container(); 
                  } else {
                    final challenges = snapshot.data!;
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: challenges.map((challenge) {
                        Widget imageWidget;
                        if (_isBase64(challenge['image'])) {
                          Uint8List imageBytes = base64Decode(challenge['image']);
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Color(0xFFFF8000),
                                );
                              },
                            ),
                          );
                        } else {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              challenge['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Color(0xFFFF8000),
                                );
                              },
                            ),
                          );
                        }
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: imageWidget),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                              Center(
                                child: Text(
                                  challenge['title'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Chaney',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/challenges');
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
                    'Challenges',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              Text(
                'ROUTINES FOR YOU',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontFamily: 'Chaney',
                ),
              ),
              SizedBox(height: 20),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: fetchPresetRoutines(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0xFFFF8000));
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}');
                    return Container();
                  } else {
                    final routines = snapshot.data!;
                    return GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8.0,
                      mainAxisSpacing: 8.0,
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      children: routines.take(4).map((routine) {
                        Widget imageWidget;
                        if (_isBase64(routine['image'])) {
                          Uint8List imageBytes = base64Decode(routine['image']);
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              imageBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Color(0xFFFF8000),
                                );
                              },
                            ),
                          );
                        } else {
                          imageWidget = ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              routine['image'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                print('Error loading image: $error');
                                return Container(
                                  color: Color(0xFFFF8000),
                                );
                              },
                            ),
                          );
                        }
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Stack(
                            children: [
                              Positioned.fill(child: imageWidget),
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(10),
                                  color: Colors.black.withOpacity(0.5),
                                ),
                              ),
                              Center(
                                child: Text(
                                  routine['name'],
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'Chaney',
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    );
                  }
                },
              ),
              SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/preset_routine');
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
                    'Check Routines',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 40),
              FutureBuilder<Map<String, dynamic>>(
                future: fetchLatestWorkout(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator(color: Color(0xFFFF8000));
                  } else if (snapshot.hasError) {
                    print('Error: ${snapshot.error}'); 
                    return Container(); 
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/workout');
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
                            "Let's Workout",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  } else {
                    final workout = snapshot.data!;
                    final duration = workout['duration'];
                    final hours = (duration / 3600).floor();
                    final minutes = ((duration % 3600) / 60).floor();
                    final seconds = (duration % 60);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LAST WORKOUT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'Chaney',
                          ),
                        ),
                        SizedBox(height: 20),
                        Container(
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            border: Border.all(color: Color(0xFFFF8000), width: 2),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                workout['title'] ?? 'No Title',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontFamily: 'Chaney',
                                ),
                              ),
                              SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Time',
                                    style: TextStyle(
                                      color: Color(0xFFFF8000),
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    'Volume',
                                    style: TextStyle(
                                      color: Color(0xFFFF8000),
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${hours}h ${minutes}min ${seconds}s',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${workout['totalVolume']} kg',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              ...workout['exercises'].map<Widget>((exercise) {
                                return FutureBuilder<Map<String, dynamic>>(
                                  future: fetchExerciseDetails(exercise['exerciseId']),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return CircularProgressIndicator(color: Color(0xFFFF8000));
                                    } else if (snapshot.hasError) {
                                      return Text('Error loading exercise details');
                                    } else {
                                      final exerciseDetails = snapshot.data!;
                                      final gifUrl = exerciseDetails['gifUrl'] ?? '';
                                      return _buildExerciseRow(context, exercise['name'], '${exercise['sets'].length} sets', gifUrl, exercise);
                                    }
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        ),
                        SizedBox(height: 30),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamed(context, '/workout');
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
                              'Check Workouts',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF323232),
        selectedItemColor: Color(0xFFFF8000),
        unselectedItemColor: Color(0xFF7A7A7A),
        currentIndex: 0,
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
    );
  }

  Widget _buildExerciseRow(BuildContext context, String exerciseName, String sets, String gifUrl, Map<String, dynamic> exercise) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExerciseInfoPage(exercise: exercise),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.black,
              radius: 20,
              child: ClipOval(
                child: Image.network(
                  gifUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    print('Error loading image: $error');
                    return CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 20,
                      child: Container(
                        color: Color(0xFFFF8000),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _capitalizeWords(_limitWords(exerciseName, 4)),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
            Text(
              sets,
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _capitalizeWords(String phrase) {
    return phrase.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  String _limitWords(String phrase, int limit) {
    List<String> words = phrase.split(' ');
    if (words.length > limit) {
      words = words.sublist(0, limit);
      words.add('...');
    }
    return words.join(' ');
  }
}
