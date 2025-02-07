import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:MoveM8/home_screen.dart';

class ActivityLevelPickerScreen extends StatefulWidget {
  @override
  _ActivityLevelPickerScreenState createState() =>
      _ActivityLevelPickerScreenState();
}

class _ActivityLevelPickerScreenState extends State<ActivityLevelPickerScreen> {
  String selectedLevel = '';
  final _storage = FlutterSecureStorage();

  final List<String> levels = [
    "Beginner",
    "Intermediate",
    "Advanced",
  ];

  Future<void> logActivityLevelData(String activityLevel) async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'activityLevel': activityLevel}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Activity level data logged successfully');
    } else {
      print('Failed to log activity level data');
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
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            SizedBox(height: 20),
            Text(
              "WHAT'S YOUR PHYSICAL ACTIVITY LEVEL?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Chaney',
                letterSpacing: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(levels.length, (index) {
                    final level = levels[index];
                    final isSelected = selectedLevel == level;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedLevel = level;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.black : Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF8000) : Colors.grey,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            level,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 56.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8000),
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    if (selectedLevel.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select your activity level.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      print("Selected Activity Level: $selectedLevel");
                      
                      await logActivityLevelData(selectedLevel);

                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (context) => HomeScreen()),
                      );
                    }
                  },
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
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
