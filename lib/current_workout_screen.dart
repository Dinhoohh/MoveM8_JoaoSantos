import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'exercise_info_screen.dart';
import 'add_exercises_screen.dart';

class CurrentWorkoutPage extends StatefulWidget {
  final String title;
  final List<Map<String, dynamic>> exercises;

  CurrentWorkoutPage({
    required this.title,
    required this.exercises,
  });

  @override
  _CurrentWorkoutPageState createState() => _CurrentWorkoutPageState();
}

class _CurrentWorkoutPageState extends State<CurrentWorkoutPage> {
  late Stopwatch _stopwatch;
  late String _formattedTime;
  List<Map<String, dynamic>> _loggedExercises = [];
  final _storage = FlutterSecureStorage();
  final Map<String, Map<String, dynamic>> _exerciseDetailsCache = {};

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _formattedTime = "00:00:00";
    _startTimer();
    _loggedExercises = widget.exercises.map((exercise) {
      exercise['setsDetails'] = exercise['sets'] ?? [{'weight': 0.0, 'reps': 0, 'completed': false}];
      return exercise;
    }).toList();
    _fetchAllExerciseDetails();
  }

  Future<void> _fetchAllExerciseDetails() async {
    for (var exercise in _loggedExercises) {
      final exerciseId = exercise['exerciseId'];
      if (!_exerciseDetailsCache.containsKey(exerciseId)) {
        final details = await fetchExerciseDetails(exerciseId);
        setState(() {
          _exerciseDetailsCache[exerciseId] = details;
        });
      }
    }
  }

  Future<void> _fetchExerciseDetailsAndCache(String exerciseId) async {
    if (!_exerciseDetailsCache.containsKey(exerciseId)) {
      final details = await fetchExerciseDetails(exerciseId);
      setState(() {
        _exerciseDetailsCache[exerciseId] = details;
      });
    }
  }

  void _startTimer() {
    _stopwatch.start();
    Future.delayed(Duration(seconds: 1), _updateTime);
  }

  void _updateTime() {
    if (_stopwatch.isRunning) {
      setState(() {
        final seconds = _stopwatch.elapsed.inSeconds % 60;
        final minutes = _stopwatch.elapsed.inMinutes % 60;
        final hours = _stopwatch.elapsed.inHours;
        _formattedTime = '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      });
      Future.delayed(Duration(seconds: 1), _updateTime);
    }
  }

  void _showFinishConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Finish Workout', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to finish your workout?', style: TextStyle(color: Colors.white70)),
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
                _stopwatch.stop();
                _logWorkoutToDatabase();
                Navigator.of(context).pop();
                Navigator.pushNamed(context, '/profile');
              },
            ),
          ],
        );
      },
    );
  }

  void _showExitConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Exit Workout', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to exit your workout? This means your workout will be discarded.', style: TextStyle(color: Colors.white70)),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Exit', style: TextStyle(color: Color(0xFFFF8000))),
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

  void _logWorkoutToDatabase() async {
    final url = Uri.parse('http://192.168.1.138:5000/api/workouts');
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
      'title': widget.title,
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
      'duration': _stopwatch.elapsed.inSeconds,
    });

    try {
      final response = await http.post(url, headers: headers, body: body);
      if (response.statusCode == 201) {
        print('Workout logged successfully');
        Navigator.pushNamed(context, '/workout'); 
      } else if (response.statusCode == 500) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Internal Server Error: Please try again later'),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        final responseBody = json.decode(response.body);
        if (responseBody['message'] == 'All exercise lookups failed') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to log workout: All exercise lookups failed'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          print('Failed to log workout: ${response.body}');
        }
      }
    } catch (error) {
      print('Error logging workout: $error');
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

  int _calculateTotalSets() {
    return _loggedExercises.fold<int>(0, (total, exercise) {
      final sets = exercise['setsDetails'] as List<dynamic>? ?? [];
      return total + sets.length;
    });
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
      await _fetchExerciseDetailsAndCache(result['id']);
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _loggedExercises.removeAt(index);
    });
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
  void dispose() {
    _stopwatch.stop();
    super.dispose();
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
            _showExitConfirmationDialog();
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _formattedTime,
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Chaney',
                fontSize: 20,
              ),
            ),
            ElevatedButton(
              onPressed: () {
                _showFinishConfirmationDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFFFF8000),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50),
                ),
              ),
              child: Text(
                'Finish',
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
                    Text(
                      widget.title.toUpperCase(),
                      style: TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 20,
                        fontFamily: 'Chaney',
                      ),
                      textAlign: TextAlign.center, 
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Complete the exercises below',
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
                          return _buildExerciseCard(context, index);
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExerciseCard(BuildContext context, int index) {
    final exercise = _loggedExercises[index];
    final setsDetails = exercise['setsDetails'] as List<dynamic>? ?? [];
    final exerciseDetails = _exerciseDetailsCache[exercise['exerciseId']];

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
                if (exerciseDetails != null)
                  CircleAvatar(
                    backgroundColor: Colors.black,
                    radius: 30,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ExerciseInfoPage(
                              exercise: {
                                'exerciseId': exercise['exerciseId'],
                                'name': exercise['name'] ?? 'Unknown',
                                'bodyPart': exercise['bodyPart'] ?? 'Unknown',
                                'equipment': exercise['equipment'] ?? 'Body Weight',
                                'target': exercise['target'] ?? 'N/A',
                                'gifUrl': exercise['gifUrl'] ?? '',
                                'secondaryMuscles': exercise['secondaryMuscles'] ?? [],
                                'instructions': exercise['instructions'] ?? [],
                              },
                            ),
                          ),
                        );
                      },
                      child: ClipOval(
                        child: Image.network(
                          exerciseDetails['gifUrl'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(Icons.error, color: Colors.white),
                        ),
                      ),
                    ),
                  )
                else
                  CircularProgressIndicator(),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise['name'] ?? 'Unknown',
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
                        'SET',
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
                        'WEIGHT',
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
                        'REPS',
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
              children: List.generate(setsDetails.length, (setIndex) {
                return Column(
                  children: [
                    SetRow(
                      exerciseIndex: index,
                      setIndex: setIndex,
                      setDetails: setsDetails[setIndex],
                      logExercise: _logExercise,
                      toggleSetCompletion: _toggleSetCompletion,
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
  }
}

class Utils {
  static String sanitizeWeightInput(String input) {
    input = input.replaceAll(RegExp(r'\.+'), '.');
    if (input.startsWith('.')) {
      input = '0' + input;
    }
    if (input.endsWith('.')) {
      input = input.substring(0, input.length - 1);
    }
    return input;
  }
}

class SetRow extends StatefulWidget {
  final int exerciseIndex;
  final int setIndex;
  final Map<String, dynamic> setDetails;
  final Function(int, int, double, int) logExercise;
  final Function(int, int) toggleSetCompletion;

  SetRow({
    required this.exerciseIndex,
    required this.setIndex,
    required this.setDetails,
    required this.logExercise,
    required this.toggleSetCompletion,
  });

  @override
  _SetRowState createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.setDetails['weight']?.toString() ?? '0.0');
    _repsController = TextEditingController(text: widget.setDetails['reps']?.toString() ?? '0');
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Expanded(
            child: Align(
              alignment: Alignment.center,
              child: Text(
                '${widget.setIndex + 1}',
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: TextField(
                controller: _weightController,
                decoration: InputDecoration(
                  hintText: 'Weight',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')), 
                ],
                onChanged: (value) {
                  value = Utils.sanitizeWeightInput(value);
                  final weight = double.tryParse(value) ?? 0.0;
                  widget.logExercise(widget.exerciseIndex, widget.setIndex, weight, widget.setDetails['reps'] ?? 0);
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
                controller: _repsController,
                decoration: InputDecoration(
                  hintText: 'Reps',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: widget.setDetails['completed'] ?? false ? Color(0xFFFF8000) : Colors.white70),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly], 
                onChanged: (value) {
                  final reps = int.tryParse(value) ?? 0;
                  widget.logExercise(widget.exerciseIndex, widget.setIndex, widget.setDetails['weight'] ?? 0.0, reps);
                },
                style: TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 30,
            height: 30,
            child: Checkbox(
              value: widget.setDetails['completed'] ?? false,
              onChanged: (bool? value) {
                if ((widget.setDetails['weight'] ?? 0.0) == 0.0 || (widget.setDetails['reps'] ?? 0) == 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Please fill in weight and reps before marking as completed'),
                      backgroundColor: Colors.red,
                    ),
                  );
                } else {
                  setState(() {
                    widget.toggleSetCompletion(widget.exerciseIndex, widget.setIndex);
                  });
                }
              },
              activeColor: Color(0xFFFF8000),
              checkColor: Colors.white,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              side: BorderSide(width: 2.0, color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
