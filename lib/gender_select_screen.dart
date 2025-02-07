import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class GenderSelectionScreen extends StatefulWidget {
  @override
  _GenderSelectionScreenState createState() => _GenderSelectionScreenState();
}

class _GenderSelectionScreenState extends State<GenderSelectionScreen> {
  String? _selectedGender;
  final FlutterSecureStorage storage = FlutterSecureStorage();
  bool isLoading = false;
  String errorMessage = '';

  Future<void> sendGenderToApi() async {
    final String? gender = _selectedGender;

    if (gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a gender')),
      );
      return;
    }

    final String apiUrl = 'http://192.168.1.138:5000/api/profile';

    String? token = await storage.read(key: 'auth_token');

    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User is not authenticated')),
      );
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'gender': gender,
        }),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushNamed(context, '/age_pick');
      } else {
        final error = jsonDecode(response.body)['message'];
        setState(() {
          errorMessage = 'Failed to save gender: $error';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred: $error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/create_profile');
          },
        ),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          children: [
            Text(
              "WHAT'S YOUR GENDER?",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontFamily: 'Chaney',
              ),
              textAlign: TextAlign.center,
            ),
            Spacer(),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'male';
                    });
                  },
                  child: CircleAvatar(
                    radius: 90,
                    backgroundColor: _selectedGender == 'male'
                        ? const Color(0xFFFF8000)
                        : Colors.grey,
                    child: Icon(
                      Icons.male,
                      color: _selectedGender == 'male' ? Colors.white : Colors.black,
                      size: 100,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "MALE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Chaney',
                  ),
                ),
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedGender = 'female';
                    });
                  },
                  child: CircleAvatar(
                    radius: 90,
                    backgroundColor: _selectedGender == 'female'
                        ? const Color(0xFFFF8000)
                        : Colors.grey,
                    child: Icon(
                      Icons.female,
                      color: _selectedGender == 'female' ? Colors.white : Colors.black,
                      size: 100,
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "FEMALE",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontFamily: 'Chaney',
                  ),
                ),
              ],
            ),
            Spacer(),
            if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: Text(
                  errorMessage,
                  style: TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8000),
                  minimumSize: const Size(double.infinity, 68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: isLoading ? null : sendGenderToApi,
                child: isLoading
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
