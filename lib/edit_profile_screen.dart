import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _storage = FlutterSecureStorage();
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic> userData = {};
  bool isLoading = true;
  File? _image;

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

  Future<void> updateUserData() async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    if (_image != null) {
      userData['image'] = base64Encode(_image!.readAsBytesSync());
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(userData),
    );

    if (response.statusCode == 200 || (response.statusCode != 200 && json.decode(response.body)['message'] == 'Profile updated successfully')) {
      print('User data updated successfully');
      Navigator.pop(context);
    } else {
      print('Failed to update user data');
      print('Response body: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update user data'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
            Navigator.pop(context);
          },
        ),
        title: Text(
          'EDIT PROFILE',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    GestureDetector(
                      onTap: () => _showImageSourceActionSheet(context),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: const Color(0xFFFF8000),
                        backgroundImage: _image != null
                            ? FileImage(_image!) as ImageProvider<Object>?
                            : (userData['image'] != null
                                ? (userData['image'].startsWith('http')
                                    ? NetworkImage(userData['image']) as ImageProvider<Object>?
                                    : MemoryImage(base64Decode(userData['image'])) as ImageProvider<Object>?)
                                : null),
                        onBackgroundImageError: userData['image'] != null
                            ? (exception, stackTrace) {
                                setState(() {
                                  userData['image'] = null;
                                });
                              }
                            : null,
                        child: _image == null && userData['image'] == null
                            ? Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 40,
                              )
                            : null,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildTextField('Username', 'username'),
                    _buildTextField('Name', 'name'),
                    _buildTextField('Age', 'age', isNumber: true),
                    _buildTextField('Height (cm)', 'height', isNumber: true),
                    _buildTextField('Weight (kg)', 'weight', isNumber: true),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          updateUserData();
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF8000),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(String label, String key, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
          SizedBox(height: 10),
          TextFormField(
            initialValue: userData[key]?.toString() ?? '',
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
            style: TextStyle(color: Colors.white),
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter $label';
              }
              return null;
            },
            onSaved: (value) {
              userData[key] = isNumber ? int.parse(value!) : value;
            },
          ),
        ],
      ),
    );
  }

}
