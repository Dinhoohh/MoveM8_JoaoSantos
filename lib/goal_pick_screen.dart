import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GoalPickerScreen extends StatefulWidget {
  @override
  _GoalPickerScreenState createState() => _GoalPickerScreenState();
}

class _GoalPickerScreenState extends State<GoalPickerScreen> {
  List<String> selectedGoals = [];
  final _storage = FlutterSecureStorage();

  final List<String> goals = [
    "Lose Weight",
    "Gain Weight",
    "Muscle Mass Gain",
    "Shape Body",
    "Others"
  ];

  Future<void> logGoalsData(List<String> goals) async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    print('Sending goals: $goals');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'goals': goals}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Goals data logged successfully');
    } else {
      print('Failed to log goals data');
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
            Navigator.pushNamed(context, '/weight_pick');
          },
        ),
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Text(
              "WHAT'S YOUR GOAL?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Chaney',
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 30),
            Expanded(
              child: Center(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: goals.length,
                  itemBuilder: (context, index) {
                    final goal = goals[index];
                    final isSelected = selectedGoals.contains(goal);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            selectedGoals.remove(goal);
                          } else {
                            selectedGoals.add(goal);
                          }
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: 15),
                        padding: EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF8000) : Colors.grey,
                            width: 4,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              goal,
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 18,
                              ),
                            ),
                            if (isSelected)
                              Icon(
                                Icons.check_circle,
                                color: const Color(0xFFFF8000),
                                size: 40,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
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
                    if (selectedGoals.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select at least one goal.',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Colors.red,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    } else {
                      print("Selected Goals: ${selectedGoals.join(', ')}");
                      await logGoalsData(selectedGoals);
                      Navigator.pushNamed(context, '/activity_level');
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

