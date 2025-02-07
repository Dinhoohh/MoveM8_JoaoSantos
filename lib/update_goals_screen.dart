import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class UpdateGoalsScreen extends StatefulWidget {
  @override
  _UpdateGoalsScreenState createState() => _UpdateGoalsScreenState();
}

class _UpdateGoalsScreenState extends State<UpdateGoalsScreen> {
  List<String> selectedGoals = [];
  final _storage = FlutterSecureStorage();

  final List<String> goals = [
    "Lose Weight",
    "Gain Weight",
    "Muscle Mass Gain",
    "Shape Body",
    "Others"
  ];

  @override
  void initState() {
    super.initState();
    fetchSelectedGoals();
  }

  Future<void> fetchSelectedGoals() async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
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
      final data = json.decode(response.body);
      setState(() {
        selectedGoals = List<String>.from(data['goals']);
      });
    } else {
      print('Failed to fetch profile data');
    }
  }

  Future<void> updateGoalsData(List<String> goals) async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    print('Updating goals: $goals');

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'goals': goals}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Goals data updated successfully');
    } else {
      print('Failed to update goals data');
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListView(
                shrinkWrap: true,
                children: [
                  Text(
                    "UPDATE YOUR GOALS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Chaney',
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                  Text(
                    "Your current goals",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Chaney',),
                  ),
                  SizedBox(height: 10),
                  ...selectedGoals.map((goal) => buildGoalCard(goal, true)).toList(),
                  SizedBox(height: 30),
                  Text(
                    "OTHER GOALS",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: 'Chaney',),
                  ),
                  SizedBox(height: 10),
                  ...goals.where((goal) => !selectedGoals.contains(goal)).map((goal) => buildGoalCard(goal, false)).toList(),
                ],
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
                        await updateGoalsData(selectedGoals);
                        Navigator.pop(context);
                      }
                    },
                    child: Text(
                      "Update",
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
      ),
    );
  }

  Widget buildGoalCard(String goal, bool isSelected) {
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
  }
}
