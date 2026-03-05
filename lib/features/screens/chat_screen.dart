import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final User user;
  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  // Store the message being currently edited
  Message? _editingMessage;

  List<Message> get _messages {
    return dummyMessagesPerUser[widget.user.id] ?? <Message>[];
  }

  void _addMessage(Message message) {
    if (!dummyMessagesPerUser.containsKey(widget.user.id)) {
      dummyMessagesPerUser[widget.user.id] = [];
    }
    dummyMessagesPerUser[widget.user.id]!.add(message);
  }

  void _showOptions(BuildContext context, Message message, bool isMe) {
    if (message.isUnsent) return; // Don't show options for unsent messages

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            if (isMe) ...[
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Chỉnh sửa'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _editingMessage = message;
                    _textController.text = message.text;
                  });
                },
              ),
              ListTile(
                leading: const Icon(Icons.undo, color: Colors.orange),
                title: const Text('Thu hồi'),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    message.isUnsent = true;
                    message.text = "Tin nhắn đã bị thu hồi";
                  });
                },
              ),
            ],
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Xóa ở phía bạn'),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _messages.removeWhere((i) => i.id == message.id);
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  _buildMessage(Message message, bool isMe) {
    return GestureDetector(
      onLongPress: () => _showOptions(context, message, isMe),
      onDoubleTap: () {
        if (!message.isUnsent) {
          setState(() {
            message.isLiked = !message.isLiked;
          });
        }
      },
      child: Container(
        margin: isMe
            ? const EdgeInsets.only(top: 8.0, bottom: 8.0, left: 80.0)
            : const EdgeInsets.only(top: 8.0, bottom: 8.0, right: 80.0),
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 25.0, vertical: 15.0),
              decoration: BoxDecoration(
                color: message.isUnsent
                    ? Colors.transparent
                    : (isMe ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.grey[200]),
                border: message.isUnsent ? Border.all(color: Colors.grey.shade400) : null,
                borderRadius: isMe
                    ? const BorderRadius.only(
                        topLeft: Radius.circular(15.0),
                        bottomLeft: Radius.circular(15.0),
                        topRight: Radius.circular(15.0),
                      )
                    : const BorderRadius.only(
                        topRight: Radius.circular(15.0),
                        bottomRight: Radius.circular(15.0),
                        topLeft: Radius.circular(15.0),
                      ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isUnsent ? Colors.grey : Colors.black87,
                      fontSize: 16.0,
                      fontStyle: message.isUnsent ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                  const SizedBox(height: 5.0),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message.isEdited && !message.isUnsent)
                        const Padding(
                          padding: EdgeInsets.only(right: 5.0),
                          child: Text(
                            'Đã chỉnh sửa',
                            style: TextStyle(color: Colors.black54, fontSize: 10.0),
                          ),
                        ),
                      Text(
                        '${message.time.hour}:${message.time.minute.toString().padLeft(2, '0')}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12.0,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (message.isLiked)
              Positioned(
                bottom: -10,
                right: isMe ? 10 : null,
                left: isMe ? null : 10,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 2.0,
                        spreadRadius: 1.0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite,
                    size: 16.0,
                    color: Colors.red,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  _buildMessageComposer() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      height: 70.0,
      color: Colors.white,
      child: Row(
        children: [
          if (_editingMessage != null)
             IconButton(
               icon: const Icon(Icons.close),
               color: Colors.red,
               onPressed: () {
                 setState(() {
                   _editingMessage = null;
                   _textController.clear();
                 });
               },
             )
          else
            IconButton(
              icon: const Icon(Icons.photo),
              iconSize: 25.0,
              color: Theme.of(context).colorScheme.primary,
              onPressed: () {},
            ),
          Expanded(
            child: TextField(
              controller: _textController,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration.collapsed(
                hintText: _editingMessage != null ? 'Đang sửa tin nhắn...' : 'Nhập tin nhắn...',
              ),
            ),
          ),
          IconButton(
            icon: Icon(
                _editingMessage != null ? Icons.check : Icons.send,
            ),
            iconSize: 25.0,
            color: Theme.of(context).colorScheme.primary,
            onPressed: () {
               if (_textController.text.isNotEmpty) {
                 final text = _textController.text;
                 setState(() {
                   if (_editingMessage != null) {
                     // Editing existing message
                     _editingMessage!.text = text;
                     _editingMessage!.isEdited = true;
                     _editingMessage = null;
                   } else {
                     // Add new user message
                     _addMessage(Message(
                         id: DateTime.now().toString(),
                         sender: currentUser,
                         text: text,
                         time: DateTime.now(),
                     ));
                     
                     // Simulate auto reply delay only for new messages
                     Future.delayed(const Duration(seconds: 1), () {
                       if (!mounted) return;
                       
                       setState(() {
                         String replyText = "Xin chào! Mình hiện tại không có mặt. Bạn cần giúp gì không?";
                         String lowerText = text.toLowerCase();
                         
                         // ==== CHỦ ĐỀ: GAME ====
                         if (lowerText.contains("game") || lowerText.contains("chơi game") || lowerText.contains("pc")) {
                           replyText = "Mình lúc nào cũng sẵn sàng! Cậu định chơi game gì đây?";
                         } else if (lowerText.contains("liên quân") || lowerText.contains("lq") || lowerText.contains("arena")) {
                           replyText = "Vào rank luôn không? Tớ chơi đi rừng bao gánh team nhé!";
                         } else if (lowerText.contains("lol") || lowerText.contains("lmht") || lowerText.contains("liên minh")) {
                           replyText = "Tối nay cày rank LMHT không? Mình đang chuỗi thắng đây. Rủ thêm team đi!";
                         } else if (lowerText.contains("pubg") || lowerText.contains("chạy bo") || lowerText.contains("bắn súng")) {
                           replyText = "Nhảy khu đông đi cho nhộn nhịp, súng xịn nhường cậu hết, tớ núp lùm cho!";
                         } else if (lowerText.contains("gánh") || lowerText.contains("kéo rank")) {
                           replyText = "Yên tâm đi, mình là game thủ chuyên nghiệp mà (mặc dù chỉ là AI thôi :D).";
                         } else if (lowerText.contains("thua") || lowerText.contains("chuỗi thua") || lowerText.contains("chán game")) {
                           replyText = "Thua keo này ta bày keo khác, nghỉ tay uống nước trân châu rồi comeback mạnh mẽ nha.";
                         } else if (lowerText.contains("tối nay") && lowerText.contains("leo rank")) {
                           replyText = "Lên lịch luôn! Tối nay ăn uống xong qua mạng quẩy tới sáng luôn nhé.";
                         } else if (lowerText.contains("nạp thẻ") || lowerText.contains("nạp game") || lowerText.contains("mua skin")) {
                           replyText = "Game là để giải trí thôi, nạp ít thôi giữ lúa nạp trà sữa ngon hơn cậu ạ!";
                         } else if (lowerText.contains("afk") || lowerText.contains("treo máy") || lowerText.contains("đi net")) {
                           replyText = "Sợ nhất là đồng đội AFK đấy, cậu đừng có treo máy nha, rớt rank khóc đấy!";
                         } else if (lowerText.contains("feed") || lowerText.contains("troll") || lowerText.contains("gà")) {
                           replyText = "Game mà, ai cũng có lúc feed, quan trọng là vui vẻ là chính, chửi đồng đội làm gì.";
                         
                         // ==== CHỦ ĐỀ: ÂM NHẠC ====
                         } else if (lowerText.contains("nhạc") || lowerText.contains("nghe nhạc") || lowerText.contains("giai điệu")) {
                           replyText = "Cậu thích nghe thể loại gì? Mình thì cực thích Lofi để thư giãn đầu óc.";
                         } else if (lowerText.contains("hát") || lowerText.contains("karaoke")) {
                           replyText = "Mình mà có thanh quản là mượn mic hát xong cho rụng rời con tim cậu luôn!";
                         } else if (lowerText.contains("bài hát") || lowerText.contains("bài gì") || lowerText.contains("hit")) {
                           replyText = "Dạo này cậu hay replay bài gì? Chia sẻ Spotify qua cho mình với!";
                         } else if (lowerText.contains("rap") || lowerText.contains("rapper") || lowerText.contains("hip hop")) {
                           replyText = "Nghe rap Việt hay ghê, mình mê mấy câu punchline bắt tai cực kì.";
                         } else if (lowerText.contains("bolero") || lowerText.contains("nhạc vàng") || lowerText.contains("xưa")) {
                           replyText = "Bolero nghe thấm thật sự, nhất là lúc trời mưa mang theo chút nỗi niềm.";
                         } else if (lowerText.contains("sơn tùng") || lowerText.contains("mtp") || lowerText.contains("sky")) {
                           replyText = "Có chắc yêu là đây? Nhạc Sếp Tùng thì lúc nào cũng chất, bật là quẩy thôi.";
                         } else if (lowerText.contains("buồn") && lowerText.contains("nhạc")) {
                           replyText = "Trời đang tự nhiên buồn mà bật nhạc suy là dễ rớt nước mắt lắm nha nha.";
                         } else if (lowerText.contains("chill") || lowerText.contains("lofi") || lowerText.contains("thư giãn")) {
                           replyText = "Đeo tai nghe vào, bật nhạc lofi nhâm nhi li cà phê nhìn ra mưa thì best!";
                         } else if (lowerText.contains("kpop") || lowerText.contains("blackpink") || lowerText.contains("bts")) {
                           replyText = "Nhạc Kpop vũ đạo cuốn quá trời. Cậu thích đu idol nhóm nào thế?";
                         } else if (lowerText.contains("đàn") || lowerText.contains("guitar") || lowerText.contains("piano")) {
                           replyText = "Biết chơi nhạc cụ ngầu lắm đó, tớ mà có tay tớ cũng học đánh guitar cua gái.";
                         
                         // ==== CHỦ ĐỀ: TRÒ CHUYỆN (CHUNG) ====
                         } else if (lowerText.contains("chào") || lowerText.contains("hi") || lowerText.contains("hello")) {
                           replyText = "Chào bạn! Chúc bạn tươi vui cả ngày nhé, nay có đi đâu chơi không?";
                         } else if (lowerText.contains("tên") || lowerText.contains("ai")) {
                           replyText = "Xin Chào. Rất vui được gặp bạn! Mình là con Bot dễ thương lạc loài vào đây.";
                         } else if (lowerText.contains("rảnh") || lowerText.contains("sao á") || lowerText.contains("không")) {
                           replyText = "À mình vừa được cậu tặng cho 2 vé xem phim, mai cậu đi với mình nhé.";
                         } else if (lowerText.contains("vậy hả") || lowerText.contains("thế à") || lowerText.contains("hả") || lowerText.contains("kể")) {
                           replyText = "Uhm, đúng rồi đó cậu, chuyện dài lắm hôm nào đi cafe mình kể tiếp mảng tối.";
                         } else if (lowerText.contains("uhm") || lowerText.contains("được") || lowerText.contains("ok")) {
                           replyText = "Kê mai gặp nhé, cậu nhớ tới đó nha, tới trễ là mình phạt chầu nước!";
                         } else if (lowerText.contains("khỏe") || lowerText.contains("mệt")) {
                           replyText = "Cảm ơn bạn, mình là máy nên khỏe re à! Bạn có mệt thì nằm nghỉ một chút nha.";
                         } else if (lowerText.contains("ăn") || lowerText.contains("đói") || lowerText.contains("trưa") || lowerText.contains("tối")) {
                           replyText = "Mình không biết ăn thức ăn loài người, nhưng mình khuyên cậu đi ăn phở nóng đi!";
                         } else if (lowerText.contains("ngủ") || lowerText.contains("buồn ngủ") || lowerText.contains("buồn")) {
                           replyText = "Mệt rã rời thì nên đi ngủ thôi. Thức khuya sinh bệnh đấy. Nhắm mắt mơ đẹp nhé!";
                         } else if (lowerText.contains("thời tiết") || lowerText.contains("nắng") || lowerText.contains("mưa")) {
                           replyText = "Nay thời tiết đỏng đảnh ghê, cậu đi đường nhớ mang đồ cẩn thận kẻo cảm nha.";
                         } else if (lowerText.contains("tạm biệt") || lowerText.contains("bye") || lowerText.contains("pp")) {
                           replyText = "Tạm biệt bạn nhé! Hẹn gặp lại. Chăm sóc bản thân nhé cậu!";
                         }
    
                         _addMessage(Message(
                           id: DateTime.now().toString(),
                           sender: widget.user,
                           text: replyText,
                           time: DateTime.now(),
                         ));
                       });
                     });
                   }
                   _textController.clear();
                 });
               }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: NetworkImage(widget.user.avatarUrl),
            ),
            const SizedBox(width: 10),
            Text(
              widget.user.name,
              style: const TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        elevation: 1.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {},
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            if (_editingMessage != null)
              Container(
                 color: Colors.blue.withOpacity(0.1),
                 padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                 width: double.infinity,
                 child: Row(
                   children: [
                     const Icon(Icons.edit, size: 16, color: Colors.blue),
                     const SizedBox(width: 8),
                     Expanded(
                       child: Text(
                         'Đang chỉnh sửa: ${_editingMessage!.text}',
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                         style: const TextStyle(color: Colors.blue, fontStyle: FontStyle.italic),
                       ),
                     ),
                   ],
                 )
              ),
            Expanded(
              child: ListView.builder(
                reverse: false,
                padding: const EdgeInsets.only(top: 15.0),
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  final Message message = _messages[index];
                  final bool isMe = message.sender.id == currentUser.id;
                  return _buildMessage(message, isMe);
                },
              ),
            ),
            _buildMessageComposer(),
          ],
        ),
      ),
    );
  }
}

