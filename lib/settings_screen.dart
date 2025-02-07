import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:http/http.dart' as http;
import 'welcome_screen.dart';

class SettingsPage extends StatelessWidget {
  final FlutterSecureStorage _storage = FlutterSecureStorage();

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
          'SETTINGS',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 24,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.all(16),
        children: [
          _buildSectionHeader('ACCOUNT'),
          _buildListTile(context, 'Profile', Icons.person),
          _buildListTile(context, 'Account', Icons.account_circle),
          _buildListTile(context, 'Statistics', Icons.bar_chart),
          _buildListTile(context, 'Import Data', Icons.cloud_download),
          SizedBox(height: 20),
          _buildSectionHeader('PREFERENCES'),
          _buildListTile(context, 'Units', Icons.straighten),
          _buildListTile(context, 'Themes', Icons.color_lens),
          _buildListTile(context, 'Languages', Icons.language),
          _buildListTile(context, 'Notifications', Icons.notifications),
          _buildListTile(context, 'Other Preferences', Icons.settings),
          SizedBox(height: 20),
          _buildSectionHeader('GUIDES'),
          _buildListTile(context, 'FAQs', Icons.help),
          _buildListTile(context, 'App Reviews', Icons.rate_review),
          _buildListTile(context, 'About', Icons.info),
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () async {
                bool confirmLogout = await _showLogoutConfirmationDialog(context);
                if (confirmLogout) {
                  await _logout(context);
                }
              },
              child: Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 40),
          Center(
            child: GestureDetector(
              onTap: () async {
                bool confirmDelete = await _showDeleteConfirmationDialog(context);
                if (confirmDelete) {
                  await _deleteAccount(context);
                }
              },
              child: Text(
                'Delete Account',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    await _storage.delete(key: 'auth_token');
    print("Logged out successfully");

    Navigator.pushReplacement(
      context,
      CupertinoPageRoute(builder: (context) => WelcomeScreen()),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final token = await _storage.read(key: 'auth_token');
    print('Token: $token');

    final response = await http.delete(
      Uri.parse('http://192.168.1.138:5000/api/user/delete'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    print('Delete account response status: ${response.statusCode}');
    print('Delete account response body: ${response.body}');

    if (response.statusCode == 200) {
      await _storage.deleteAll();
      print("Account deleted successfully");
      Navigator.pushReplacement(
        context,
        CupertinoPageRoute(builder: (context) => WelcomeScreen()),
      );
    } else {
      print('Failed to delete account');
    }
  }

  Future<bool> _showLogoutConfirmationDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Confirm Logout', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to logout?', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    )) ?? false;
  }

  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    return (await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color.fromARGB(255, 19, 19, 19),
          title: Text('Confirm Delete', style: TextStyle(color: Colors.white)),
          content: Text('Are you sure you want to delete your account? This cannot be undone.', style: TextStyle(color: Colors.white70)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('Cancel', style: TextStyle(color: Color(0xFFFF8000))),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    )) ?? false;
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          color: Color(0xFFFF8000),
          fontSize: 18,
          fontFamily: 'Chaney',
        ),
      ),
    );
  }

  Widget _buildListTile(BuildContext context, String title, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      trailing: Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
      onTap: () {
      },
    );
  }
}
