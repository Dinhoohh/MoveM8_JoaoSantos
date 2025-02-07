import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'exercise_info_screen.dart';

class AddExercisesPage extends StatefulWidget {
  @override
  _AddExercisesPageState createState() => _AddExercisesPageState();
}

class _AddExercisesPageState extends State<AddExercisesPage> {
  List<dynamic> exercises = [];
  List<dynamic> filteredExercises = [];
  List<dynamic> equipmentList = [];
  List<dynamic> muscleList = [];
  bool isLoading = true;
  String selectedFilter = 'All';
  String selectedEquipment = '';
  String selectedMuscle = '';
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchExercises();
    searchController.addListener(_onSearchChanged);
  }

  Future<void> fetchExercises({String filter = '', String? category}) async {
    const String apiUrl = 'https://exercisedb.p.rapidapi.com/exercises';
    const Map<String, String> headers = {
      'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
      'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
    };

    String url = apiUrl;

    if (filter.isNotEmpty) {
      if (filter == 'equipment' && category != null) {
        url = '$apiUrl/equipment/$category?limit=1';
      } else if (filter == 'muscle' && category != null) {
        url = '$apiUrl/bodyPart/$category?limit=1';
      }
    }

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          exercises = data;
          filteredExercises = exercises;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load exercises');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching exercises: $error');
    }
  }

  void _onSearchChanged() {
    String query = searchController.text.toLowerCase();
    setState(() {
      filteredExercises = exercises.where((exercise) {
        String exerciseName = exercise['name'].toLowerCase();
        return exerciseName.contains(query);
      }).toList();
    });
  }

  Future<void> fetchEquipmentOrMuscleList(String type) async {
    String url = type == 'equipment'
        ? 'https://exercisedb.p.rapidapi.com/exercises/equipmentList'
        : 'https://exercisedb.p.rapidapi.com/exercises/bodyPartList';

    const Map<String, String> headers = {
      'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
      'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
    };

    try {
      final response = await http.get(Uri.parse(url), headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          if (type == 'equipment') {
            equipmentList = data;
          } else {
            muscleList = data;
          }
        });
      } else {
        throw Exception('Failed to load $type list');
      }
    } catch (error) {
      print('Error fetching $type list: $error');
    }
  }

  void updateFilter(String filter, {String? category}) {
    setState(() {
      selectedFilter = filter;
      isLoading = true;
    });

    if (filter == 'Equipment') {
      fetchEquipmentOrMuscleList('equipment');
    } else if (filter == 'Muscle') {
      fetchEquipmentOrMuscleList('muscle');
    } else {
      fetchExercises(filter: filter.toLowerCase(), category: category);
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
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
          'Add Exercises',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Chaney',
            fontSize: 24,
          ),
        ),
      ),
      body: Container(
        color: Colors.black,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search for exercises',
                  hintStyle: TextStyle(color: Colors.white70),
                  filled: true,
                  fillColor: Colors.black,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Color(0xFFFF8000)),
                  ),
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        updateFilter('All');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedFilter == 'All'
                            ? Color(0xFFFF8000)
                            : Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Exercises',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        updateFilter('Equipment');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedFilter == 'Equipment'
                            ? Color(0xFFFF8000)
                            : Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Equipment',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        updateFilter('Muscle');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: selectedFilter == 'Muscle'
                            ? Color(0xFFFF8000)
                            : Colors.grey[800],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Body Part',
                        style: TextStyle(fontSize: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (selectedFilter == 'Equipment')
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: equipmentList.length,
                        itemBuilder: (context, index) {
                          String equipment = equipmentList[index];
                          return Column(
                            children: [
                              Divider(color: Colors.grey[700], height: 0.5),
                              ListTile(
                                title: Text(
                                  equipment[0].toUpperCase() + equipment.substring(1),
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedEquipment = equipment;
                                    selectedFilter = 'equipment';
                                    isLoading = true;
                                  });
                                  fetchExercises(
                                      filter: 'equipment', category: selectedEquipment);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedFilter == 'Muscle')
              Expanded(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: muscleList.length,
                        itemBuilder: (context, index) {
                          String muscle = muscleList[index];
                          return Column(
                            children: [
                              Divider(color: Colors.grey[700], height: 0.5),
                              ListTile(
                                title: Text(
                                  muscle[0].toUpperCase() + muscle.substring(1),
                                  style: TextStyle(color: Colors.white),
                                ),
                                onTap: () {
                                  setState(() {
                                    selectedMuscle = muscle;
                                    selectedFilter = 'muscle';
                                    isLoading = true;
                                  });
                                  fetchExercises(
                                      filter: 'muscle', category: selectedMuscle);
                                },
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            if (selectedFilter == 'All' || selectedFilter == 'equipment' || selectedFilter == 'muscle')
              Expanded(
                child: isLoading
                    ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)))
                    : ListView.builder(
                        itemCount: filteredExercises.length,
                        itemBuilder: (context, index) {
                          final exercise = filteredExercises[index];
                          String exerciseName = exercise['name'];
                          exerciseName = exerciseName.split(' ').map((word) {
                            if (word.isEmpty) return word;
                            return word[0].toUpperCase() + word.substring(1).toLowerCase();
                          }).join(' ');
                          String bodyPart = exercise['bodyPart'];
                          return Card(
                            color: Colors.black,
                            margin: EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                ListTile(
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
                                    exerciseName,
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  subtitle: Text(
                                    '${bodyPart[0].toUpperCase() + bodyPart.substring(1)}',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  trailing: IconButton(
                                    icon: Icon(Icons.add, color: Color(0xFFFF8000)),
                                    onPressed: () {
                                      Navigator.pop(context, {
                                        'id': exercise['id'], 
                                        'name': exercise['name'],
                                        'bodyPart': exercise['bodyPart'],
                                        'gifUrl': exercise['gifUrl'],
                                        'secondaryMuscles': exercise['secondaryMuscles'], 
                                        'instructions': exercise['instructions'], 
                                      });
                                    },
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ExerciseInfoPage(
                                          exercise: {
                                            'exerciseId': exercise['id'],
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
                                ),
                                Divider(color: Colors.grey[700], height: 0.5),
                              ],
                            ),
                          );
                        },
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
