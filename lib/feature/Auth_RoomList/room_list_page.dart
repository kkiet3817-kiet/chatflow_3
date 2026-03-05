import 'package:flutter/material.dart';
import 'chat_page.dart';

class RoomListPage extends StatelessWidget {
  const RoomListPage({super.key});

  @override
  Widget build(BuildContext context) {

    final rooms = [
      {"name": "Phòng Game", "icon": Icons.sports_esports},
      {"name": "Phòng Hỗ Trợ", "icon": Icons.support_agent},
      {"name": "Phòng Âm Nhạc", "icon": Icons.music_note},
      {"name": "Phòng Tổng Hợp", "icon": Icons.forum},
    ];

    return Scaffold(

      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        title: const Text("Danh Sách Phòng Chat"),
        centerTitle: true,
        elevation: 0,
        backgroundColor: const Color(0xFF4facfe),
      ),

      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: rooms.length,

        itemBuilder: (context, index) {

          final room = rooms[index];

          return GestureDetector(

            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ChatPage(roomName: room["name"].toString()),
                ),
              );
            },

            child: Container(
              margin: const EdgeInsets.only(bottom: 18),
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 5),
                  )
                ],
              ),

              child: Row(
                children: [

                  Container(
                    width: 50,
                    height: 50,

                    decoration: BoxDecoration(
                      color: const Color(0xFF4facfe).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(15),
                    ),

                    child: Icon(
                      room["icon"] as IconData,
                      color: const Color(0xFF4facfe),
                      size: 26,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text(
                          room["name"].toString(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 5),

                        const Text(
                          "Đang hoạt động",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 18,
                    color: Colors.grey,
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}