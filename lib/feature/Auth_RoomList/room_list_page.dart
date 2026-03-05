import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'login_page.dart';

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
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Danh Sách Phòng Chat",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => const LoginPage(),
                ),
                    (route) => false,
              );
            },
          )
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rooms.length,
        itemBuilder: (context, index) {
          final room = rooms[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 18),
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(22),
              shadowColor: Colors.black12,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ChatPage(roomName: room["name"]),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor:
                        room["color"].withOpacity(0.15),
                        child: Icon(
                          room["icon"],
                          color: room["color"],
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              room["name"],
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  "Đang hoạt động",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}