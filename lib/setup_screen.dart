import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'create_profile_screen.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final FlutterSecureStorage storage = FlutterSecureStorage();

  Future<void> navigateToCreateProfile() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Authentication token not found. Please log in again.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateProfileScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/consistency.jpeg',
              width: double.infinity,
              height: screenHeight * 0.6,
              fit: BoxFit.cover,
            ),
            SizedBox(height: 68),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: "CONSISTENCY",
                      style: TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: " IS THE KEY TO ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: "SUCCESS",
                      style: TextStyle(
                        color: Color(0xFFFF8000),
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 68),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8000),
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: navigateToCreateProfile,
                  child: Text(
                    'I\'m Ready',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 56),
          ],
        ),
      ),
    );
  }
}
