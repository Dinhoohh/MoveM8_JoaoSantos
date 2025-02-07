import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class CreateProfileScreen extends StatefulWidget {
  @override
  _CreateProfileScreenState createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  File? _image;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  final _storage = FlutterSecureStorage();

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  void _showImageSourceActionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                tileColor: Color(0xFF323232),
                leading: Icon(Icons.photo_library, color: Color(0xFFFF8000)),
                title: Text('Gallery', style: TextStyle(color: Color(0xFFFF8000))),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                tileColor: Color(0xFF323232),
                leading: Icon(Icons.camera_alt, color: Color(0xFFFF8000)),
                title: Text('Camera', style: TextStyle(color: Color(0xFFFF8000))),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitProfile() async {
    final name = _nameController.text.trim();
    final username = _usernameController.text.trim();

    if (name.isEmpty || username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Both name and username are required.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final profileData = {
      'name': name,
      'username': username,
      'image': _image != null ? base64Encode(_image!.readAsBytesSync()) : null,
    };

    try {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Authentication token not found. Please log in again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      print('Retrieved Token: $token');

      final response = await http.post(
        Uri.parse('http://192.168.1.138:5000/api/profile'),
        body: json.encode(profileData),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.pushNamed(context, '/gender_select');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating profile. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error connecting to server.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushNamed(context, '/setup');
          },
        ),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          'CREATE YOUR PROFILE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontFamily: 'Chaney',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 80),
                        GestureDetector(
                          onTap: () => _showImageSourceActionSheet(context),
                          child: CircleAvatar(
                            radius: 60,
                            backgroundColor: const Color(0xFFFF8000),
                            backgroundImage: _image != null ? FileImage(_image!) : null,
                            child: _image == null
                                ? Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 40,
                                  )
                                : null,
                          ),
                        ),
                        SizedBox(height: 48),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Name',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _nameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFFF8000)),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Username',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        TextField(
                          controller: _usernameController,
                          style: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: Colors.transparent,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.white),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Color(0xFFFF8000)),
                            ),
                          ),
                        ),
                        SizedBox(height: 40),
                      ],
                    ),
                  ),
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
                onPressed: () {
                  _submitProfile();
                },
                child: Text(
                  'Continue',
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
