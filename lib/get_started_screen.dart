import 'package:flutter/material.dart';
import 'welcome_screen.dart';

class GetStartedScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/splash_background.jpeg'),
              fit: BoxFit.cover,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(height: 100),
              Image.asset('assets/images/logo.png', height: 40),
              SizedBox(height: 60),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'START ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: 'TRACKING',
                      style: TextStyle(
                        color: const Color(0xFFFF8000),
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: '\nAND SEE THE ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: 'PROGRESS',
                      style: TextStyle(
                        color: const Color(0xFFFF8000),
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: '\nYOU\'VE\n ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: 'ALWAYS',
                      style: TextStyle(
                        color: const Color(0xFFFF8000),
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                    TextSpan(
                      text: ' WANTED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontFamily: 'Chaney',
                      ),
                    ),
                  ],
                ),
              ),
              Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => WelcomeScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF8000),
                  minimumSize: const Size(double.infinity, 68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Get started',
                  style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}
