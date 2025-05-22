import 'dart:convert';

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String timestamp;
  final bool read;
  final String type;
  final Map<String, dynamic> data;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    required this.read,
    required this.type,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'timestamp': timestamp,
      'read': read,
      'type': type,
      'data': data,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      body: json['body'],
      timestamp: json['timestamp'],
      read: json['read'] ?? false,
      type: json['type'] ?? 'general',
      data: json['data'] ?? {},
    );
  }

  factory NotificationModel.fromRTDB(Map<dynamic, dynamic> map) {
    return NotificationModel(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      timestamp: map['timestamp'] ?? DateTime.now().toIso8601String(),
      read: map['read'] ?? false,
      type: map['type'] ?? 'general',
      data: Map<String, dynamic>.from(map['data'] ?? {}),
    );
  }

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? timestamp,
    bool? read,
    String? type,
    Map<String, dynamic>? data,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      read: read ?? this.read,
      type: type ?? this.type,
      data: data ?? this.data,
    );
  }
}