import 'package:flutter/material.dart';
import 'package:MoveM8/add_exercises_screen.dart';
import 'package:flutter/services.dart';
import 'exercise_info_screen.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class RoutinePage extends StatefulWidget {
  @override
  _RoutinePageState createState() => _RoutinePageState();
}

class _RoutinePageState extends State<RoutinePage> {
  List<Map<String, dynamic>> _loggedExercises = [];
  final _storage = FlutterSecureStorage();
  String _routineTitle = '';
  final _titleController = TextEditingController();
  final Map<String, Map<String, dynamic>> _exerciseDetailsCache = {};

  void _showFinishConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Save Routine', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Are you sure you want to save your routine?', style: TextStyle(color: Colors.white70)),
              SizedBox(height: 16),
              TextField(
                controller: _titleController,
                onChanged: (value) {
                  setState(() {
                    _routineTitle = value;
                  });
                },
                style: TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Enter routine title',
                  hintStyle: TextStyle(color: Colors.white70),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white70),
                  ),
                  focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  errorText: _routineTitle.isEmpty ? 'Title cannot be empty' : null,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Finish', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                if (_routineTitle.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please enter a routine title'),
                      backgroundColor: Color(0xFFFF8000),
                    ),
                  );
                } else {
                  _logRoutineToDatabase();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _logRoutineToDatabase() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/routines');
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    final body = json.encode({
      'title': _routineTitle,
      'exercises': _loggedExercises.map((exercise) {
        return {
          'exerciseId': exercise['exerciseId'],
          'name': exercise['name'],
          'sets': exercise['setsDetails'].map((set) {
            return {
              'weight': set['weight'],
              'reps': set['reps'],
            };
          }).toList(),
        };
      }).toList(),
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        print('Routine logged successfully');
        Navigator.pushNamed(context, '/workout'); 
      } else {
        print('Failed to log routine: ${response.body}');
      }
    } catch (error) {
      print('Error logging routine: $error');
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
        }).join(' ');
        _loggedExercises.add({
          'exerciseId': result['id'], 
          'name': exerciseName,
          'bodyPart': result['bodyPart'],
          'gifUrl': result['gifUrl'],
          'secondaryMuscles': result['secondaryMuscles'], 
          'instructions': result['instructions'], 
          'sets': 1, 
          'weight': 0.0,
          'reps': 0,
          'setsDetails': [{'weight': 0.0, 'reps': 0, 'completed': false}], 
        });
      });
    }
  }

  void _logExercise(int index, int setIndex, double weight, int reps) {
    setState(() {
      if (_loggedExercises[index]['setsDetails'] == null) {
        _loggedExercises[index]['setsDetails'] = [];
      }
      if (_loggedExercises[index]['setsDetails'].length <= setIndex) {
        _loggedExercises[index]['setsDetails'].add({'weight': weight, 'reps': reps, 'completed': false});
      } else {
        _loggedExercises[index]['setsDetails'][setIndex]['weight'] = weight;
        _loggedExercises[index]['setsDetails'][setIndex]['reps'] = reps;
      }
    });
  }

  String _sanitizeWeightInput(String input) {
    input = input.replaceAll(RegExp(r'\.+'), '.');
    if (input.startsWith('.')) { 
      input = '0' + input;
    }
    if (input.endsWith('.')) { 
      input = input.substring(0, input.length - 1);
    }
    return input;
  }

  int _calculateTotalSets() {
    return _loggedExercises.fold<int>(0, (total, exercise) => total + (exercise['sets'] ?? 0) as int);
  }

  double _calculateTotalVolume() {
    return _loggedExercises.fold(0.0, (total, exercise) {
      final setsDetails = exercise['setsDetails'] ?? [];
      return total + setsDetails.fold(0.0, (setTotal, set) {
        if (set['completed'] ?? false) {
          final weight = set['weight'] ?? 0.0;
          final reps = set['reps'] ?? 0;
          return setTotal + (weight * reps);
        }
        return setTotal;
      });
    });
  }

  void _addSet(int index) {
    setState(() {
      _loggedExercises[index]['sets'] = (_loggedExercises[index]['sets'] ?? 0) + 1;
      if (_loggedExercises[index]['setsDetails'] == null) {
        _loggedExercises[index]['setsDetails'] = [];
      }
      _loggedExercises[index]['setsDetails'].add({'weight': 0.0, 'reps': 0, 'completed': false}); 
    });
  }

  void _toggleSetCompletion(int exerciseIndex, int setIndex) {
    setState(() {
      _loggedExercises[exerciseIndex]['setsDetails'][setIndex]['completed'] =
          !(_loggedExercises[exerciseIndex]['setsDetails'][setIndex]['completed'] ?? false);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _loggedExercises.removeAt(index);
    });
  }

  void _showDiscardConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Discard Routine', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to discard your routine? This action cannot be undone.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Discard', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/workout');
              },
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> fetchExerciseDetails(String exerciseId) async {
    if (_exerciseDetailsCache.containsKey(exerciseId)) {
      return _exerciseDetailsCache[exerciseId]!;
    }

    final url = Uri.parse('https://exercisedb.p.rapidapi.com/exercises/exercise/$exerciseId');
    final headers = {
      'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
      'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
    };

    final response = await http.get(url, headers: headers);

    if (response.statusCode == 200) {
      final exerciseDetails = json.decode(response.body);
      _exerciseDetailsCache[exerciseId] = exerciseDetails;
      return exerciseDetails;
    } else {
      throw Exception('Failed to load exercise details');
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
            Navigator.pushNamed(context, '/workout');
          },
        ),
        title: Row(
          children: [
            Spacer(), 
            ElevatedButton(
              onPressed: () {
                _showFinishConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      'Sets',
                      style: TextStyle(color: Color(0xFFFF8000), fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_calculateTotalSets()}',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text(
                      'Volume',
                      style: TextStyle(color: Color(0xFFFF8000), fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '${_calculateTotalVolume().toStringAsFixed(1)} kg',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
              ],
            ),
            Divider(color: Colors.grey[700], thickness: 1, height: 32),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Center(
                      child: Text(
                        'CREATE ROUTINE',
                        style: TextStyle(
                          color: Color(0xFFFF8000),
                          fontSize: 20,
                          fontFamily: 'Chaney',
                        ),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Add exercises to create your routine',
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 24),
                    if (_loggedExercises.isNotEmpty)
                      ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: _loggedExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = _loggedExercises[index];
                          return Card(
                            color: Colors.black,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.black,
                                        radius: 30,
                                        child: GestureDetector(
                                          onTap: () {
                                            print('Navigating to ExerciseInfoPage with data: $exercise');
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => ExerciseInfoPage(
                                                  exercise: {
                                                    'name': exercise['name'],
                                                    'bodyPart': exercise['bodyPart'],
                                                    'equipment': exercise['equipment'] ?? 'Body Weight',
                                                    'target': exercise['target'] ?? 'N/A',
                                                    'gifUrl': exercise['gifUrl'],
                                                    'secondaryMuscles': exercise['secondaryMuscles'] ?? [], 
                                                    'instructions': exercise['instructions'] ?? [], 
                                                  },
                                                ),
                                              ),
                                            );
                                          },
                                          child: ClipOval(
                                            child: Image.network(
                                              exercise['gifUrl'],
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  Icon(Icons.error, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              exercise['name'],
                                              style: TextStyle(color: Colors.white, fontSize: 18),
                                            ),
                                            SizedBox(height: 8),
                                          ],
                                        ),
                                      ),
                                      PopupMenuButton<String>(
                                        icon: Icon(Icons.more_vert, color: Colors.white),
                                        onSelected: (String result) {
                                          if (result == 'Remove') {
                                            _removeExercise(index);
                                          }
                                        },
                                        itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'Remove',
                                            child: Text('Remove'),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Set',
                                              style: TextStyle(color: Colors.white70, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Weight',
                                              style: TextStyle(color: Colors.white70, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                                          child: Align(
                                            alignment: Alignment.center,
                                            child: Text(
                                              'Reps',
                                              style: TextStyle(color: Colors.white70, fontSize: 16),
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 40), 
                                    ],
                                  ),
                                  SizedBox(height: 8),
                                  Column(
                                    children: List.generate(exercise['sets'] ?? 1, (setIndex) {
                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Align(
                                                    alignment: Alignment.center,
                                                    child: Text(
                                                      '${setIndex + 1}',
                                                      style: TextStyle(color: Colors.white, fontSize: 16),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                        hintText: 'Weight',
                                                        hintStyle: TextStyle(color: Colors.white70),
                                                        border: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                                                      ),
                                                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                                                      inputFormatters: [
                                                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), 
                                                      ],
                                                      onChanged: (value) {
                                                        value = _sanitizeWeightInput(value);
                                                        final weight = double.tryParse(value) ?? 0.0;
                                                        _logExercise(index, setIndex, weight, exercise['setsDetails'][setIndex]['reps'] ?? 0);
                                                      },
                                                      style: TextStyle(color: Colors.white),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Expanded(
                                                  child: Padding(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                                    child: TextField(
                                                      decoration: InputDecoration(
                                                        hintText: 'Reps',
                                                        hintStyle: TextStyle(color: Colors.white70),
                                                        border: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        focusedBorder: OutlineInputBorder(
                                                          borderSide: BorderSide(color: exercise['setsDetails'][setIndex]['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                                                          borderRadius: BorderRadius.circular(8.0),
                                                        ),
                                                        contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                                                      ),
                                                      keyboardType: TextInputType.number,
                                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                                                      onChanged: (value) {
                                                        final reps = int.tryParse(value) ?? 0;
                                                        _logExercise(index, setIndex, exercise['setsDetails'][setIndex]['weight'] ?? 0.0, reps);
                                                      },
                                                      style: TextStyle(color: Colors.white),
                                                      textAlign: TextAlign.center,
                                                    ),
                                                  ),
                                                ),
                                                Checkbox(
                                                  value: exercise['setsDetails'][setIndex]['completed'] ?? false,
                                                  onChanged: (bool? value) {
                                                    _toggleSetCompletion(index, setIndex);
                                                  },
                                                  activeColor: Color(0xFFFF8000),
                                                  checkColor: Colors.white,
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(height: 12), 
                                          Divider(color: Color(0xFFFF8000), height: 0.5),
                                          SizedBox(height: 12), 
                                        ],
                                      );
                                    }),
                                  ),
                                  SizedBox(height: 8),
                                  ElevatedButton(
                                    onPressed: () => _addSet(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Color(0xFFFF8000),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: Text(
                                      'Add Set',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ],
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
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        _showDiscardConfirmationDialog();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 16),
                        minimumSize: Size(double.infinity, 56),
                      ),
                      child: Text(
                        'Discard Routine',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
