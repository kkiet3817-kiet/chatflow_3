import 'package:flutter/material.dart';
import '../services/message_local_service.dart';
import '../services/user_status_service.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {

  TextEditingController controller = TextEditingController();

  List<String> messages = [];

  bool isOnline = true;

  @override
  void initState() {
    super.initState();

    loadMessages();

    UserStatusService.statusStream().listen((status) {
      setState(() {
        isOnline = status;
      });
    });
  }

  void loadMessages() async {
    messages = await MessageLocalService.loadMessages();

    setState(() {});
  }

  void sendMessage() async {
    if (controller.text.isEmpty) return;

    await MessageLocalService.saveMessage(controller.text);

    controller.clear();

    loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Chat"),
            Text(
              isOnline ? "Online" : "Offline",
              style: TextStyle(
                fontSize: 12,
                color: isOnline ? Colors.green : Colors.red,
              ),
            )
          ],
        ),
      ),

      body: Column(
        children: [

          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context,index){
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),

          Row(
            children: [

              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: InputDecoration(
                      hintText: "Type message"
                  ),
                ),
              ),

              IconButton(
                icon: Icon(Icons.send),
                onPressed: sendMessage,
              )

            ],
          )

        ],
      ),
    );
  }
}