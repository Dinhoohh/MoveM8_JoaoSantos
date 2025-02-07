import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'add_exercises_screen.dart';

class CreatePresetScreen extends StatefulWidget {
  @override
  _CreatePresetScreenState createState() => _CreatePresetScreenState();
}

class _CreatePresetScreenState extends State<CreatePresetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storage = FlutterSecureStorage();
  XFile? _image;
  final ImagePicker _picker = ImagePicker();
  List<Map<String, dynamic>> _exercises = [];
  String _selectedGoal = 'Lose Weight';
  final List<String> _goals = ['Lose Weight', 'Gain Weight', 'Muscle Mass Gain', 'Shape Body', 'Others'];

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = pickedFile;
      });
    }
  }

  Future<void> _createPresetRoutine() async {
    if (_formKey.currentState!.validate()) {
      final token = await _storage.read(key: 'auth_token');
      if (token == null) {
        throw Exception('No token found');
      }

      final response = await http.post(
        Uri.parse('http://192.168.1.138:5000/api/preset_routines'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'name': _nameController.text,
          'description': _descriptionController.text,
          'goal': _selectedGoal,
          'exercises': _exercises,
          'image': _image != null ? base64Encode(await _image!.readAsBytes()) : null,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Preset routine created successfully')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create preset routine')));
      }
    }
  }

  void _addExercise() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddExercisesPage()),
    );
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        String exerciseName = result['name'];
        exerciseName = exerciseName.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).take(4).join(' ');

        String bodyPart = result['bodyPart'];
        bodyPart = bodyPart.split(' ').map((word) {
          if (word.isEmpty) return word;
          return word[0].toUpperCase() + word.substring(1).toLowerCase();
        }).join(' ');

        _exercises.add({
          'exerciseId': result['id'],
          'name': exerciseName,
          'bodyPart': bodyPart,
          'gifUrl': result['gifUrl'],
          'secondaryMuscles': result['secondaryMuscles'],
          'instructions': result['instructions'],
        });
      });
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
        title: Text(
          'CREATE PRESET ROUTINE',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Image',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 10),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    border: Border.all(color: Color(0xFFFF8000)),
                    borderRadius: BorderRadius.circular(8),
                    image: _image != null
                        ? DecorationImage(
                            image: NetworkImage(_image!.path),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _image == null
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
              SizedBox(height: 16),
              Text(
                'Name',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _nameController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Description',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _descriptionController,
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.black,
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Text(
                'Goal',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Chaney'),
              ),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Color(0xFFFF8000)),
                ),
                child: DropdownButtonFormField<String>(
                  value: _selectedGoal,
                  items: _goals.map((String goal) {
                    return DropdownMenuItem<String>(
                      value: goal,
                      child: Text(goal, style: TextStyle(color: Colors.white)),
                    );
                  }).toList(),
                  onChanged: (newValue) {
                    setState(() {
                      _selectedGoal = newValue!;
                    });
                  },
                  dropdownColor: Colors.black,
                  decoration: InputDecoration(
                    enabledBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    focusedBorder: UnderlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Exercises',
                style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Chaney'),
              ),
              if (_exercises.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _exercises.length,
                  itemBuilder: (context, index) {
                    final exercise = _exercises[index];
                    return Card(
                      color: Colors.black,
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.black,
                          child: ClipOval(
                            child: Image.network(
                              exercise['gifUrl'],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.error, color: Colors.white),
                            ),
                          ),
                        ),
                        title: Text(
                          exercise['name'],
                          style: TextStyle(color: Colors.white),
                        ),
                        subtitle: Text(
                          exercise['bodyPart'],
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    );
                  },
                ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addExercise,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFFF8000),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add, color: Colors.white, size: 30),
                    SizedBox(width: 8),
                    Text(
                      'Add Exercises',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 32),
              Center(
                child: ElevatedButton(
                  onPressed: _createPresetRoutine,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8000),
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    'Create Routine',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
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
}
