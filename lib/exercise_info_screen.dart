import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ExerciseInfoPage extends StatefulWidget {
  final Map<String, dynamic> exercise;

  ExerciseInfoPage({required this.exercise});

  @override
  _ExerciseInfoPageState createState() => _ExerciseInfoPageState();
}

class _ExerciseInfoPageState extends State<ExerciseInfoPage> with SingleTickerProviderStateMixin {
  bool showSummary = true;
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Future<Map<String, dynamic>> _exerciseDetailsFuture;

  @override
  void initState() {
    super.initState();
    _exerciseDetailsFuture = _fetchExerciseDetails();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: Offset(0.0, -1.0),
      end: Offset(0.0, 0.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    _controller.forward();
  }

  Future<Map<String, dynamic>> _fetchExerciseDetails() async {
    final exerciseId = widget.exercise['exerciseId'];
    if (exerciseId == null) {
      throw Exception('Invalid exercise ID');
    }
    final url = Uri.parse('https://exercisedb.p.rapidapi.com/exercises/exercise/$exerciseId');

    try {
      final response = await http.get(url, headers: {
        'X-RapidAPI-Host': 'exercisedb.p.rapidapi.com',
        'X-RapidAPI-Key': 'e1c043c4c3mshaf08b9dfe8dfef3p1e933ejsn844764bef27c',
      });
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to fetch exercise details: ${response.body}');
      }
    } catch (error) {
      throw Exception('Error fetching exercise details: $error');
    }
  }

  

  @override
  void dispose() {
    _controller.dispose();
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
            Navigator.pop(context);
          },
        ),
        title: Text(
          widget.exercise['name'] != null ? widget.exercise['name'][0].toUpperCase() + widget.exercise['name'].substring(1) : 'N/A',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'Chaney',
            fontSize: 24,
          ),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _exerciseDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(child: Text('No data available'));
          } else {
            final exerciseDetails = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      color: Colors.black,
                      padding: EdgeInsets.only(top: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(right: 8),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showSummary = true;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: showSummary ? Color(0xFFFF8000) : Colors.grey,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: Size(double.infinity, 48), 
                                ),
                                child: Text(
                                  'Summary',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Container(
                              margin: EdgeInsets.only(left: 8),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    showSummary = false;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: showSummary ? Colors.grey : Color(0xFFFF8000),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  padding: EdgeInsets.symmetric(vertical: 16),
                                  minimumSize: Size(double.infinity, 48), 
                                ),
                                child: Text(
                                  'How To',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20), 
                  Center(
                    child: Container(
                      width: double.infinity,
                      height: 400,
                      child: Image.network(
                        exerciseDetails['gifUrl'] ?? '',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Icon(Icons.error, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                  Expanded(
                    child: Container(
                      color: Colors.black,
                      child: AnimatedSwitcher(
                        duration: Duration(milliseconds: 300),
                        child: showSummary ? _buildSummaryContent(exerciseDetails) : _buildHowToContent(exerciseDetails),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          final offsetAnimation = Tween<Offset>(
                            begin: showSummary ? Offset(-1.0, 0.0) : Offset(1.0, 0.0),
                            end: Offset(0.0, 0.0),
                          ).animate(animation);
                          return SlideTransition(position: offsetAnimation, child: child);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildSummaryContent(Map<String, dynamic> exerciseDetails) {
    return Container(
      key: ValueKey('Summary'),
      alignment: Alignment.topLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Body Part: ',
                  style: TextStyle(color: Color(0xFFFF8000), fontSize: 18),
                ),
                TextSpan(
                  text: exerciseDetails['bodyPart'] != null ? exerciseDetails['bodyPart'][0].toUpperCase() + exerciseDetails['bodyPart'].substring(1) : 'N/A',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Equipment: ',
                  style: TextStyle(color: Color(0xFFFF8000), fontSize: 18),
                ),
                TextSpan(
                  text: exerciseDetails['equipment'] != null ? exerciseDetails['equipment'][0].toUpperCase() + exerciseDetails['equipment'].substring(1) : 'N/A',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Target Muscle: ',
                  style: TextStyle(color: Color(0xFFFF8000), fontSize: 18),
                ),
                TextSpan(
                  text: exerciseDetails['target'] != null ? exerciseDetails['target'][0].toUpperCase() + exerciseDetails['target'].substring(1) : 'N/A',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          if (exerciseDetails['secondaryMuscles'] != null && exerciseDetails['secondaryMuscles'].isNotEmpty)
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Secondary Muscles: ',
                    style: TextStyle(color: Color(0xFFFF8000), fontSize: 18),
                  ),
                  TextSpan(
                    text: exerciseDetails['secondaryMuscles'].map((muscle) => muscle[0].toUpperCase() + muscle.substring(1)).join(', '),
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHowToContent(Map<String, dynamic> exerciseDetails) {
    return Column(
      key: ValueKey('HowTo'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        exerciseDetails['instructions'] != null && exerciseDetails['instructions'].isNotEmpty
            ? Expanded(
                child: ListView(
                  children: [
                    ...exerciseDetails['instructions'].asMap().entries.map<Widget>((entry) {
                      int index = entry.key + 1;
                      String instruction = entry.value;
                      return Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '$index. ',
                                style: TextStyle(color: Color(0xFFFF8000), fontSize: 20),
                              ),
                              TextSpan(
                                text: instruction,
                                style: TextStyle(color: Colors.white, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              )
            : Center(
                key: ValueKey('NoInstructions'),
                child: Text(
                  'No instructions available.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
      ],
    );
  }
}
