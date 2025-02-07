import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class WeightPickerPage extends StatefulWidget {
  @override
  _WeightPickerPageState createState() => _WeightPickerPageState();
}

class _WeightPickerPageState extends State<WeightPickerPage> {
  double selectedWeight = 70.0;
  late PageController _pageController;
  final TextEditingController _weightController = TextEditingController();
  final _storage = FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.3, initialPage: ((selectedWeight - 30) * 10).toInt());
    _weightController.text = selectedWeight.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> logWeightData(double weight) async {
    final url = 'http://192.168.1.138:5000/api/profile';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({'weight': weight}),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Weight data logged successfully');
    } else {
      print('Failed to log weight data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() {
          selectedWeight = double.tryParse(_weightController.text) ?? selectedWeight;
          _pageController.jumpToPage(((selectedWeight - 30) * 10).toInt());
        });
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          backgroundColor: Colors.black,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/height_pick');
            },
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Text(
                    "WHAT'S YOUR WEIGHT?",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontFamily: 'Chaney',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 150),
                Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: TextField(
                            controller: _weightController,
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            style: TextStyle(color: Colors.white, fontSize: 80, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            decoration: InputDecoration(
                              hintText: "Enter your weight",
                              hintStyle: TextStyle(color: Colors.grey, fontSize: 20, fontWeight: FontWeight.bold),
                              enabledBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                              focusedBorder: UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.transparent),
                              ),
                            ),
                            onSubmitted: (value) {
                              setState(() {
                                selectedWeight = double.tryParse(value) ?? selectedWeight;
                                _pageController.jumpToPage(((selectedWeight - 30) * 10).toInt());
                              });
                            },
                          ),
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              height: 100,
                              child: PageView.builder(
                                controller: _pageController,
                                scrollDirection: Axis.horizontal,
                                onPageChanged: (index) {
                                  setState(() {
                                    selectedWeight = 30 + (index / 10);
                                    _weightController.text = selectedWeight.toStringAsFixed(1);
                                  });
                                },
                                itemCount: 1210,
                                itemBuilder: (context, index) {
                                  final weight = 30 + (index / 10);
                                  final isSelected = weight == selectedWeight;

                                  return AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    curve: Curves.easeInOut,
                                    alignment: Alignment.center,
                                    child: Text(
                                      weight.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: isSelected ? 32 : 20,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? Colors.white : Colors.grey,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: -10,
                              child: Icon(Icons.arrow_drop_up, color: const Color(0xFFFF8000), size: 40),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 50),
              ],
            ),
            Positioned(
              bottom: 56,
              left: 20,
              right: 20,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8000),
                    minimumSize: const Size(double.infinity, 68),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: () async {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      selectedWeight = double.tryParse(_weightController.text) ?? selectedWeight;
                      _pageController.jumpToPage(((selectedWeight - 30) * 10).toInt());
                    });
                    if (selectedWeight > 0) {
                      print("Selected Weight: ${selectedWeight.toStringAsFixed(1)} kg");
                      await logWeightData(selectedWeight);
                      Navigator.pushNamed(context, '/goal');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Please select a weight',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          backgroundColor: Colors.grey,
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(top: 10, left: 10, right: 10),
                        ),
                      );
                    }
                  },
                  child: Text(
                    "Continue",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
