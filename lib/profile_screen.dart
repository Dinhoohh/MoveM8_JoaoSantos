import 'package:flutter/material.dart';
import 'settings_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'edit_profile_screen.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = FlutterSecureStorage();
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  final Map<String, Map<String, dynamic>> _exerciseDetailsCache = {};

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  Future<void> fetchUserData() async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      setState(() {
        userData = json.decode(response.body);
        isLoading = false;
      });
    } else {
      print('Failed to fetch user data');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<List<Map<String, dynamic>>> fetchAllWorkouts() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/workouts/all');
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
      throw Exception('Failed to load workouts');
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

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final details = json.decode(response.body);
      _exerciseDetailsCache[exerciseId] = details;
      return details;
    } else {
      throw Exception('Failed to load exercise details');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => EditProfilePage()),
            );
          },
          child: Text(
            'Edit Profile',
            style: TextStyle(color: Color(0xFFFF8000), fontSize: 16),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage()),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Color(0xFF323232),
        selectedItemColor: Color(0xFFFF8000),
        unselectedItemColor: Color(0xFF7A7A7A), 
        currentIndex: 2,
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
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)))
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    SizedBox(height: 20),
                    CircleAvatar(
                      radius: 60,
                      backgroundImage: userData['image'] != null
                          ? (userData['image'].startsWith('http')
                              ? NetworkImage(userData['image'] as String)
                              : MemoryImage(base64Decode(userData['image'] as String)) as ImageProvider)
                          : AssetImage('assets/images/logo.png') as ImageProvider,
                      onBackgroundImageError: (exception, stackTrace) {
                        setState(() {
                          userData['image'] = null;
                        });
                      },
                    ),
                    SizedBox(height: 16),
                    Text(
                      userData['username'] ?? 'Username',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        border: Border.all(color: Color(0xFFFF8000), width: 2),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStat('${userData['weight'] ?? 'N/A'} Kg', 'Weight'),
                          _buildStat('${userData['age'] ?? 'N/A'}', 'Years Old'),
                          _buildStat('${userData['height'] ?? 'N/A'} Cm', 'Height'),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionHeader('DASHBOARD'),
                        SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _buildDashboardButton('Progress', context)),
                            Expanded(child: _buildDashboardButton('Goals', context)),
                          ],
                        ),
                        SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _buildDashboardButton('Measures', context)),
                            Expanded(child: _buildDashboardButton('Exercises', context)),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 40),
                    _buildAllWorkoutsSection(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontFamily: 'Chaney',
        ),
      ),
    );
  }

  Widget _buildDashboardButton(String label, BuildContext context) {
    return GestureDetector(
      onTap: () {
        if (label == 'Progress') {
          Navigator.pushNamed(context, '/progress');
        } else if (label == 'Measures') {
          Navigator.pushNamed(context, '/measures');
        } else if (label == 'Goals') {
          Navigator.pushNamed(context, '/update_goals');
        }
        
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Color(0xFFFF8000),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAllWorkoutsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'WORKOUTS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontFamily: 'Chaney',
              ),
            ),
          ),
        ),
        SizedBox(height: 20),
        FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchAllWorkouts(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return CircularProgressIndicator();
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}', style: TextStyle(color: Colors.red));
            } else {
              final workouts = snapshot.data!;
              workouts.sort((a, b) => DateTime.parse(b['date']).compareTo(DateTime.parse(a['date'])));
              final groupedWorkouts = <String, List<Map<String, dynamic>>>{};

              for (var workout in workouts) {
                final workoutDate = DateTime.parse(workout['date']).toLocal();
                final now = DateTime.now();
                String dateLabel;

                if (workoutDate.year == now.year && workoutDate.month == now.month && workoutDate.day == now.day) {
                  dateLabel = 'Today';
                } else if (workoutDate.year == now.year && workoutDate.month == now.month && workoutDate.day == now.day - 1) {
                  dateLabel = 'Yesterday';
                } else {
                  dateLabel = DateFormat('dd/MM/yyyy').format(workoutDate);
                }

                if (!groupedWorkouts.containsKey(dateLabel)) {
                  groupedWorkouts[dateLabel] = [];
                }
                groupedWorkouts[dateLabel]!.add(workout);
              }

              return Column(
                children: groupedWorkouts.entries.map<Widget>((entry) {
                  final dateLabel = entry.key;
                  final workoutsForDate = entry.value;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 10, left: 10, right: 10, bottom: 8),
                        child: Text(
                          dateLabel,
                          style: TextStyle(
                            color: Color(0xFFFF8000),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ...workoutsForDate.map<Widget>((workout) {
                        final duration = workout['duration'];
                        final hours = (duration / 3600).floor();
                        final minutes = ((duration % 3600) / 60).floor();
                        final seconds = (duration % 60);

                        return Container(
                          padding: EdgeInsets.all(16),
                          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
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
                                      return CircularProgressIndicator();
                                    } else if (snapshot.hasError) {
                                      return Text('Error loading exercise details');
                                    } else {
                                      final exerciseDetails = snapshot.data!;
                                      final gifUrl = exerciseDetails['gifUrl'] ?? '';
                                      return _buildExerciseRow(exercise['name'], '${exercise['sets'].length} sets', gifUrl);
                                    }
                                  },
                                );
                              }).toList(),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  );
                }).toList(),
              );
            }
          },
        ),
      ],
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

  Widget _buildExerciseRow(String exerciseName, String sets, String gifUrl) {
    return Padding(
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
                errorBuilder: (context, error, stackTrace) =>
                    CircleAvatar(
                      backgroundColor: Colors.black,
                      radius: 20,
                      child: Icon(Icons.error, color: Colors.white),
                    ),
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
    );
  }
}