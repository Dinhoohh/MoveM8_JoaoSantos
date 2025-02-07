import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class HeightPickerPage extends StatefulWidget {
  @override
  _HeightPickerPageState createState() => _HeightPickerPageState();
}

class _HeightPickerPageState extends State<HeightPickerPage> {
  int selectedHeight = 175;
  final _storage = FlutterSecureStorage();

  Future<void> logHeightData(int height) async {
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
      body: json.encode({'height': height}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Height data logged successfully');
    } else {
      print('Failed to log height data');
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
            Navigator.pushNamed(context, '/age_pick');
          },
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Text(
              "WHAT'S YOUR HEIGHT?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Chaney',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 250,
            left: 0,
            right: 0,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: "$selectedHeight",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: " Cm",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 200,
                  child: ListWheelScrollView.useDelegate(
                    physics: FixedExtentScrollPhysics(),
                    itemExtent: 40,
                    onSelectedItemChanged: (index) {
                      setState(() {
                        selectedHeight = 145 + index;
                      });
                    },
                    childDelegate: ListWheelChildBuilderDelegate(
                      builder: (context, index) {
                        final height = 145 + index;
                        final isSelected = height == selectedHeight;

                        return Center(
                          child: Text(
                            height.toString(),
                            style: TextStyle(
                              fontSize: isSelected ? 32 : 20,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : Colors.grey,
                            ),
                          ),
                        );
                      },
                      childCount: 66,
                    ),
                  ),
                ),
                Positioned(
                  left: 90,
                  child: Container(
                    height: 2,
                    width: 50,
                    color: const Color(0xFFFF8000),
                  ),
                ),
                Positioned(
                  right: 90,
                  child: Icon(Icons.arrow_right, color: const Color(0xFFFF8000), size: 40),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 56,
            left: 20,
            right: 20,
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
                  print("Selected Height: $selectedHeight Cm");
                  await logHeightData(selectedHeight);
                  Navigator.pushNamed(context, '/weight_pick');
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
    );
  }
}
