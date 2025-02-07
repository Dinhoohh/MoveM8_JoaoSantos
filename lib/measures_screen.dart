import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class MeasuresPage extends StatefulWidget {
  @override
  _MeasuresPageState createState() => _MeasuresPageState();
}

class _MeasuresPageState extends State<MeasuresPage> {
  DateTime selectedDate = DateTime.now();
  File? _progressPicture;
  final ImagePicker _picker = ImagePicker();
  final storage = FlutterSecureStorage();

  final Map<String, TextEditingController> _controllers = {
    'Body Weight': TextEditingController(),
    'Body Fat (%)': TextEditingController(),
    'Waist (cm)': TextEditingController(),
    'Neck (cm)': TextEditingController(),
    'Shoulder (cm)': TextEditingController(),
    'Chest (cm)': TextEditingController(),
    'Left Bicep (cm)': TextEditingController(),
    'Right Bicep (cm)': TextEditingController(),
    'Left Forearm (cm)': TextEditingController(),
    'Right Forearm (cm)': TextEditingController(),
    'Abdomen (cm)': TextEditingController(),
    'Hips (cm)': TextEditingController(),
    'Left Thigh (cm)': TextEditingController(),
    'Right Thigh (cm)': TextEditingController(),
    'Left Calf (cm)': TextEditingController(),
    'Right Calf (cm)': TextEditingController(),
  };

  @override
  void initState() {
    super.initState();
    _fetchProfileWeight();
  }

  Future<void> _fetchProfileWeight() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.get(
      Uri.parse('http://192.168.1.138:5000/api/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        _controllers['Body Weight']?.text = data['weight']?.toString() ?? '';
      });
    } else {
      print('Failed to fetch profile weight');
    }
  }

  Future<void> _pickPicture(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _progressPicture = File(pickedFile.path);
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
                  _pickPicture(ImageSource.gallery);
                },
              ),
              ListTile(
                tileColor: Color(0xFF323232),
                leading: Icon(Icons.camera_alt, color: Color(0xFFFF8000)),
                title: Text('Camera', style: TextStyle(color: Color(0xFFFF8000))),
                onTap: () {
                  Navigator.pop(context);
                  _pickPicture(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _saveMeasures() async {
    final data = _controllers.map((key, controller) => MapEntry(key, controller.text));
    final measures = {
      'date': selectedDate.toIso8601String(),
      'bodyWeight': data['Body Weight'],
      'bodyFat': data['Body Fat (%)'],
      'waist': data['Waist (cm)'],
      'neck': data['Neck (cm)'],
      'shoulder': data['Shoulder (cm)'],
      'chest': data['Chest (cm)'],
      'leftBicep': data['Left Bicep (cm)'],
      'rightBicep': data['Right Bicep (cm)'],
      'leftForearm': data['Left Forearm (cm)'],
      'rightForearm': data['Right Forearm (cm)'],
      'abdomen': data['Abdomen (cm)'],
      'hips': data['Hips (cm)'],
      'leftThigh': data['Left Thigh (cm)'],
      'rightThigh': data['Right Thigh (cm)'],
      'leftCalf': data['Left Calf (cm)'],
      'rightCalf': data['Right Calf (cm)'],
      'progressPicture': _progressPicture != null ? base64Encode(_progressPicture!.readAsBytesSync()) : null,
    };

    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.1.138:5000/api/progress/measures'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(measures),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      print('Measurements added or updated successfully');
      if (data['Body Weight'] != null && selectedDate.isAtSameMomentAs(DateTime.now())) {
        await _updateProfileWeight(data['Body Weight']!);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Information updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      print('Failed to add or update measurements');
      print('Response: ${response.body}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update information'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _updateProfileWeight(String weight) async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.put(
      Uri.parse('http://192.168.1.138:5000/api/profile'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'weight': weight}),
    );

    if (response.statusCode == 200) {
      print('Profile weight updated successfully');
    } else {
      print('Failed to update profile weight');
      print('Response: ${response.body}');
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
          onPressed: () => Navigator.pushNamed(context, '/profile'),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 12),
            child: TextButton(
              onPressed: _saveMeasures,
              child: Text(
                'Save',
                style: TextStyle(color: Colors.black, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Color(0xFFFF8000),
                minimumSize: Size(90, 36), 
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Text(
                  'Log Measurements',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white, fontSize: 24, fontFamily: 'Chaney'),
                ),
              ),
              SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Date',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  GestureDetector(
                    onTap: () => _selectDate(context),
                    child: Text(
                      '${selectedDate.day} ${_monthName(selectedDate.month)} ${selectedDate.year}',
                      style: TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 30),
              Text(
                'Progress Picture',
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: () => _showImageSourceActionSheet(context),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.white),
                    borderRadius: BorderRadius.circular(8),
                    image: _progressPicture != null
                        ? DecorationImage(
                            image: FileImage(_progressPicture!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _progressPicture == null
                      ? Center(
                          child: Icon(
                            Icons.camera_alt,
                            color: Color(0xFFFF8000),
                            size: 50,
                          ),
                        )
                      : null,
                ),
              ),
              SizedBox(height: 30),
              Text(
                'Measurements',
                style: TextStyle(color: Colors.white, fontSize: 18, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 20),
              Container(
                child: Column(
                  children: _controllers.keys.map((key) {
                    return Container(
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.white.withOpacity(0.2),
                            width: 0.5,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 12, horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              key,
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            SizedBox(
                              width: 80,
                              child: TextField(
                                controller: _controllers[key],
                                style: TextStyle(color: Color(0xFFFF8000), fontSize: 16),
                                textAlign: TextAlign.end,
                                decoration: InputDecoration(
                                  hintText: '-',
                                  hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.6)),
                                  border: InputBorder.none,
                                ),
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }
}
