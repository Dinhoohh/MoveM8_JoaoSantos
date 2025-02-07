import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AgePickerPage extends StatefulWidget {
  @override
  _AgePickerPageState createState() => _AgePickerPageState();
}

class _AgePickerPageState extends State<AgePickerPage> {
  int selectedAge = 21;
  late PageController _pageController;
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.3, initialPage: selectedAge - 12);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> logAgeData(int age) async {
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
      body: json.encode({'age': age}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Age data logged successfully');
    } else {
      print('Failed to log age data');
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
            Navigator.pushNamed(context, '/gender_select');
          },
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Text(
              "HOW OLD ARE YOU?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Chaney',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "$selectedAge",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 100,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        onPageChanged: (index) {
                          setState(() {
                            selectedAge = 12 + index;
                          });
                        },
                        itemCount: 78,
                        itemBuilder: (context, index) {
                          final age = 12 + index;
                          final isSelected = age == selectedAge;

                          return AnimatedContainer(
                            duration: Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            alignment: Alignment.center,
                            child: Text(
                              age.toString(),
                              style: TextStyle(
                                fontSize: isSelected ? 32 : 20,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? Colors.white : Colors.grey,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Positioned(
                      bottom: -10,
                      child: Icon(Icons.arrow_drop_up, color: const Color(0xFFFF8000), size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
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
                  if (selectedAge > 0) {
                    print("Selected Age: $selectedAge");
                    await logAgeData(selectedAge);
                    Navigator.pushNamed(context, '/height_pick');
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Please select an age',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                        backgroundColor: Colors.grey,
                        behavior: SnackBarBehavior.floating,
                        margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                      ),
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
          SizedBox(height: 56),
        ],
      ),
    );
  }
}
