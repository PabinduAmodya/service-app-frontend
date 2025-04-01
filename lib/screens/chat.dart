import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChatScreen extends StatefulWidget {
  final String workerId;
  final String workerName;
  final String userToken;

  const ChatScreen({
    Key? key, 
    required this.workerId, 
    required this.workerName,
    required this.userToken
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  List<dynamic> _messages = [];
  String? _chatId;
  String? _currentUserId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _getCurrentUserId();
  }

  Future<void> _getCurrentUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      setState(() {
        _currentUserId = prefs.getString('user_id');
      });
      _startChat();
    } catch (e) {
      _showErrorSnackBar('Error retrieving user ID: $e');
    }
  }

  Future<void> _startChat() async {
    if (_currentUserId == null) {
      _showErrorSnackBar('User ID not found');
      return;
    }

    try {
      // Detailed logging
      debugPrint('Starting Chat with:');
      debugPrint('Worker ID: ${widget.workerId}');
      debugPrint('Worker Name: ${widget.workerName}');
      debugPrint('Current User ID: $_currentUserId');

      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/chats/start'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}'
        },
        body: json.encode({
          'workerId': widget.workerId,
          'userId': _currentUserId
        }),
      );

      // More detailed logging
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = json.decode(response.body);
        setState(() {
          _chatId = responseBody['chatId'];
          _isLoading = false;
        });
        _fetchMessages();
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorSnackBar('Failed to start chat: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showErrorSnackBar('Error starting chat: $e');
    }
  }

  Future<void> _fetchMessages() async {
    if (_chatId == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/api/chats/$_chatId/messages'),
        headers: {
          'Authorization': 'Bearer ${widget.userToken}'
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages = json.decode(response.body);
        });
      } else {
        _showErrorSnackBar('Failed to fetch messages');
      }
    } catch (e) {
      _showErrorSnackBar('Error fetching messages: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _chatId == null) return;

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/api/chats/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${widget.userToken}'
        },
        body: json.encode({
          'chatId': _chatId,
          'message': message,
          'senderId': _currentUserId
        }),
      );

      if (response.statusCode == 201) {
        _messageController.clear();
        _fetchMessages();
      } else {
        _showErrorSnackBar('Failed to send message');
      }
    } catch (e) {
      _showErrorSnackBar('Error sending message: $e');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          widget.workerName,
          style: const TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading 
        ? Center(
            child: CircularProgressIndicator(
              color: Colors.yellow[700],
            ),
          )
        : Column(
            children: [
              Expanded(
                child: _messages.isEmpty
                  ? Center(
                      child: Text(
                        'No messages yet',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 16,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final message = _messages[_messages.length - 1 - index];
                        final bool isMe = message['senderId'] == _currentUserId;

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.yellow[700] : Colors.grey[800],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              message['message'],
                              style: TextStyle(
                                color: isMe ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          fillColor: Colors.grey[800],
                          filled: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 10),
                    CircleAvatar(
                      backgroundColor: Colors.yellow[700],
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.black),
                        onPressed: _sendMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}