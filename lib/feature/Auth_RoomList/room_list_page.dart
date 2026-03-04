import 'package:flutter/material.dart';
import 'chat_page.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> rooms = [
      {
        "name": "Phòng Game",
        "icon": Icons.sports_esports,
        "color": Colors.deepPurple,
      },
      {
        "name": "Phòng Hỗ Trợ",
        "icon": Icons.support_agent,
        "color": Colors.blue,
      },
      {
        "name": "Phòng Âm Nhạc",
        "icon": Icons.music_note,
        "color": Colors.pink,
      },
      {
        "name": "Phòng Tổng Hợp",
        "icon": Icons.forum,
        "color": Colors.green,
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Danh Sách Phòng Chat"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, "/login");
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                backgroundColor: room["color"],
                child: Icon(
                  room["icon"],
                  color: Colors.white,
                ),
              ),
              title: Text(
                room["name"],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: const Text("Đang hoạt động"),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatPage(roomName: room["name"]),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}