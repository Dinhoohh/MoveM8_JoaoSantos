import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';

class NotificationsPage extends StatefulWidget {
  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final _storage = FlutterSecureStorage();
  List<Map<String, dynamic>> notifications = [];
  bool isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedNotifications = {};

  @override
  void initState() {
    super.initState();
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    final url = 'http://192.168.1.138:5000/api/notifications';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      setState(() {
        isLoading = false;
      });
      return;
    }

    final response = await http.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Notifications fetched successfully');
      setState(() {
        notifications = List<Map<String, dynamic>>.from(json.decode(response.body));
        groupNotificationsByDate();
        isLoading = false;
      });
    } else {
      print('Failed to fetch notifications: ${response.statusCode}');
      setState(() {
        isLoading = false;
      });
    }
  }

  void groupNotificationsByDate() {
    final now = DateTime.now();
    groupedNotifications.clear();

    for (var notification in notifications) {
      final createdAt = DateTime.parse(notification['createdAt']);
      String dateLabel;

      if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day) {
        dateLabel = 'Today';
      } else if (createdAt.year == now.year && createdAt.month == now.month && createdAt.day == now.day - 1) {
        dateLabel = 'Yesterday';
      } else {
        dateLabel = DateFormat('dd/MM/yyyy').format(createdAt);
      }

      if (!groupedNotifications.containsKey(dateLabel)) {
        groupedNotifications[dateLabel] = [];
      }
      groupedNotifications[dateLabel]!.add(notification);
    }
  }

  Future<void> markAsRead(String notificationId) async {
    final url = 'http://192.168.1.138:5000/api/notifications/$notificationId/mark-as-read';
    final token = await _storage.read(key: 'auth_token');

    if (token == null) {
      print('No token found');
      return;
    }

    final response = await http.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print('Notification marked as read');
      fetchNotifications(); 
    } else {
      print('Failed to mark notification as read: ${response.statusCode}');
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
            Navigator.pushNamed(context, '/home');
          },
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontFamily: 'Chaney',
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: Colors.black,
      body: isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF8000)))
          : ListView.builder(
              itemCount: groupedNotifications.keys.length,
              itemBuilder: (context, index) {
                final dateLabel = groupedNotifications.keys.elementAt(index);
                final notificationsForDate = groupedNotifications[dateLabel]!;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 10, left: 20, right: 20, bottom: 4),
                      child: Text(
                        dateLabel,
                        style: TextStyle(
                          color: Color(0xFFFF8000),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ...notificationsForDate.asMap().entries.map((entry) {
                      final notification = entry.value;
                      final isLast = entry.key == notificationsForDate.length - 1;
                      return Column(
                        children: [
                          Container(
                            margin: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            padding: EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: notification['isRead'] ? Colors.grey[900] : const Color(0xFFFF8000),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.notifications,
                                color: notification['isRead'] ? const Color(0xFFFF8000) : Colors.white,
                              ),
                              title: Text(
                                notification['title'],
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                ),
                              ),
                              subtitle: Text(
                                notification['message'],
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              trailing: notification['isRead']
                                  ? null
                                  : Icon(Icons.circle, color: Colors.red, size: 10),
                              onTap: () {
                                markAsRead(notification['_id']);
                              },
                            ),
                          ),
                          if (isLast) SizedBox(height: 40),
                        ],
                      );
                    }).toList(),
                  ],
                );
              },
            ),
    );
  }
}
