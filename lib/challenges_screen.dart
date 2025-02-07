import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class ChallengesScreen extends StatelessWidget {
  Future<List<Map<String, dynamic>>> fetchChallenges() async {
    final response = await http.get(Uri.parse('http://192.168.1.138:5000/api/challenges'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(json.decode(response.body));
    } else {
      throw Exception('Failed to load challenges');
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
          'CHALLENGES',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: fetchChallenges(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              final challenges = snapshot.data!;
              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: challenges.length,
                itemBuilder: (context, index) {
                  final challenge = challenges[index];
                  return Container(
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF8000),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                              child: Image.network(
                                challenge['image'],
                                height: 120,
                                width: MediaQuery.of(context).size.width / 2.25,
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Container(
                                  child: Text(
                                    challenge['title'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontFamily: 'Chaney',
                                      fontSize: 16,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Expanded(
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(horizontal: 16),
                            title: Padding(
                              padding: const EdgeInsets.only(top: 12.0, bottom:4),
                              child: Text(
                                challenge['description'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Text(
                                '${DateFormat('dd/MM').format(DateTime.parse(challenge['startDate']))} until ${DateFormat('dd/MM').format(DateTime.parse(challenge['endDate']))}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
