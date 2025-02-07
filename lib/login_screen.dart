import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; 
import 'welcome_screen.dart'; 
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final FlutterSecureStorage storage = FlutterSecureStorage();

  bool isLoading = false;
  String errorMessage = '';
  bool _obscureText = true;

  Future<void> loginUser() async {
    final String email = emailController.text;
    final String password = passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        errorMessage = 'Please enter both email and password.';
      });
      return;
    }

    const String apiUrl = 'http://192.168.1.138:5000/api/auth/login';

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      setState(() {
        isLoading = false;
      });

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final String token = responseData['token'];
        final String nextStep = responseData['nextStep'];

        await storage.write(key: 'auth_token', value: token);

        String? savedToken = await storage.read(key: 'auth_token');
        print('Saved Token: $savedToken');

        navigateToNextStep(nextStep);
      } else {
        final error = jsonDecode(response.body)['message'];
        setState(() {
          errorMessage = 'Login failed: $error';
        });
      }
    } catch (error) {
      setState(() {
        isLoading = false;
        errorMessage = 'An error occurred: $error';
      });
    }
  }

  void navigateToNextStep(String nextStep) {
    switch (nextStep) {
      case 'home':
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 'create_profile':
        Navigator.pushReplacementNamed(context, '/setup');
        break;
      case 'weight_pick':
        Navigator.pushReplacementNamed(context, '/weight_pick');
        break;
      case 'height_pick':
        Navigator.pushReplacementNamed(context, '/height_pick');
        break;
      case 'age_pick':
        Navigator.pushReplacementNamed(context, '/age_pick');
        break;
      case 'goal_pick':
        Navigator.pushReplacementNamed(context, '/goal_pick');
        break;
      case 'activity_level':
        Navigator.pushReplacementNamed(context, '/activity_level');
        break;
      default:
        Navigator.pushReplacementNamed(context, '/home');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF9A4F03), Color(0xFF1F1F1F)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: MediaQuery.of(context).viewPadding.top + 30),
                Center(
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 42,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'WELCOME BACK AND LOGIN',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontFamily: 'Chaney',
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 48),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Email',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: emailController,
                      style: TextStyle(color: Colors.white),
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
                          borderSide: BorderSide(color: const Color(0xFFFF8000)),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 40),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Password',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 20),
                    TextField(
                      controller: passwordController,
                      obscureText: _obscureText,
                      style: TextStyle(color: Colors.white),
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
                          borderSide: BorderSide(color: const Color(0xFFFF8000)),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureText ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureText = !_obscureText;
                            });
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Forgot Password?',
                      style: TextStyle(
                        color: const Color(0xFFFF8000),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: isLoading ? null : loginUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8000),
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          'Next',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      errorMessage,
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                SizedBox(height: 20),
                Text(
                  'or login with',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _socialButton(FontAwesomeIcons.google),
                    SizedBox(width: 10),
                    _socialButton(FontAwesomeIcons.facebook),
                  ],
                ),
                SizedBox(height: 40),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/signup');
                  },
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: 'Don\'t have an account? ',
                      style: TextStyle(color: Colors.white),
                      children: [
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(color: const Color(0xFFFF8000)),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 56),
              ],
            ),
          ),
          Positioned(
            top: 40,
            left: 16,
            child: GestureDetector(
              onTap: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => WelcomeScreen()),
                );
              },
              child: Icon(
                Icons.arrow_back,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton(IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(8),
      child: IconButton(
        icon: FaIcon(
          icon,
          color: const Color(0xFFFF8000),
        ),
        onPressed: () {
          // Socials may be 
        },
      ),
    );
  }
}
