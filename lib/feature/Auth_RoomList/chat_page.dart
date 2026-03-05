import 'dart:math';
import 'package:flutter/material.dart';

// THÊM: Các package để chọn file ảnh thật (cần add image_picker vào pubspec.yaml)
// import 'dart:io';
// import 'package:image_picker/image_picker.dart';

enum MessageType { text, image }

class Message {
  final String text;
  final bool isUser;
  final bool isTyping;
  final String time;
  final MessageType type;
  final String? imagePath;

  Message({
    this.text = '',
    required this.isUser,
    required this.time,
    this.isTyping = false,
    this.type = MessageType.text,
    this.imagePath,
  });
}

class ChatPage extends StatefulWidget {
  final String roomName;

  const ChatPage({
    super.key,
    required this.roomName,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Random _random = Random();

  List<Message> messages = [];
  int userMessageCount = 0;
  bool waitingForStaff = false;

  final Map<String, List<String>> botData = {
    "hello": [
      "Xin chào 👋 Tôi là CSKH ChatFlow",
      "Chào bạn 😊 Tôi có thể giúp gì?",
      "Xin chào! Bạn cần hỗ trợ gì?"
    ],
    "game": [
      "Bạn đang gặp lỗi gì trong game?",
      "Game bị lag hay không vào được?",
      "Bạn đang chơi phòng nào?"
    ],
    "giá": [
      "Bạn muốn hỏi giá dịch vụ nào?",
      "Hiện tại chúng tôi có nhiều gói.",
      "Bạn muốn xem bảng giá không?"
    ],
    "lỗi": [
      "Bạn có thể mô tả lỗi chi tiết hơn không?",
      "Lỗi này xảy ra khi nào?",
      "Bạn có thể gửi ảnh lỗi được không?"
    ]
  };

  @override
  void initState() {
    super.initState();
    _addBotMessage("Xin chào 👋 Tôi là CSKH ChatFlow.\nTôi có thể giúp gì cho bạn?");
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _getTime() {
    final now = DateTime.now();
    return "${now.hour}:${now.minute.toString().padLeft(2, '0')}";
  }

  void _addBotMessage(String text, {bool isTyping = false}) {
    messages.add(
      Message(
        text: text,
        isUser: false,
        time: _getTime(),
        isTyping: isTyping,
      ),
    );
  }

  void _sendMessage({String? text, String? imagePath}) {
    String messageText = text ?? _controller.text.trim();
    // Chặn gửi nếu cả text và ảnh đều trống
    if (messageText.isEmpty && imagePath == null) return;

    if (text == null) {
      _controller.clear();
    }

    setState(() {
      messages.add(
        Message(
          text: messageText,
          imagePath: imagePath,
          type: imagePath != null ? MessageType.image : MessageType.text,
          isUser: true,
          time: _getTime(),
        ),
      );
      userMessageCount++;
    });

    _scrollToBottom();
    _simulateBotReply(messageText, imagePath != null);
  }

  // HÀM MỚI: Xử lý gửi ảnh
  Future<void> _pickImage() async {
    // ---- [NẾU BẠN SỬ DỤNG GÓI image_picker VỚI ẢNH THẬT TRONG MÁY] ----
    // final ImagePicker picker = ImagePicker();
    // final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    // if (image != null) {
    //   _sendMessage(imagePath: image.path); // gửi đường dẫn local file
    // }

    // ---- [DEMO] giả lập gửi ảnh từ 1 link ngẫu nhiên trên mạng ----
    _sendMessage(imagePath: 'https://picsum.photos/400/300?random=${_random.nextInt(100)}');
  }

  void _simulateBotReply(String userText, bool isImage) {
    setState(() {
      _addBotMessage("", isTyping: true);
    });
    _scrollToBottom();

    // Giả lập độ trễ khi bot gõ chữ
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;

      setState(() {
        messages.removeLast(); // Xoá tin nhắn "Đang trả lời..."

        if (userMessageCount >= 10 && !waitingForStaff) {
          waitingForStaff = true;
          _addBotMessage(
            "Bạn đã gửi khá nhiều tin nhắn.\nTôi sẽ kết nối bạn tới nhân viên CSKH 👨‍💻\nVui lòng chờ trong giây lát...",
          );
        } else {
          _addBotMessage(isImage
              ? "Tôi đã nhận được hình ảnh của bạn 🖼️\nĐang tiến hành kiểm tra..."
              : _getReply(userText)
          );
        }
      });
      _scrollToBottom();
    });
  }

  String _getReply(String text) {
    text = text.toLowerCase();
    if (text.contains("xin chào") || text.contains("hello")) return _randomReply("hello");
    if (text.contains("game")) return _randomReply("game");
    if (text.contains("giá")) return _randomReply("giá");
    if (text.contains("lỗi")) return _randomReply("lỗi");

    List<String> defaultReply = [
      "Tôi đã nhận tin nhắn của bạn 😊",
      "Bạn có thể nói rõ hơn không?",
      "Tôi đang kiểm tra thông tin cho bạn.",
      "Bạn có thể mô tả chi tiết hơn?",
      "Tôi hiểu rồi 👍"
    ];
    return defaultReply[_random.nextInt(defaultReply.length)];
  }

  String _randomReply(String key) {
    List<String> replies = botData[key]!;
    return replies[_random.nextInt(replies.length)];
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildQuickButtons() {
    List<String> quick = ["Xin chào", "Game bị lỗi", "Hỏi giá", "Gặp nhân viên"];

    return SizedBox(
      height: 48,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        itemCount: quick.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ActionChip(
              backgroundColor: Colors.blue.shade50,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(
                quick[index],
                style: const TextStyle(color: Colors.blue),
              ),
              onPressed: () => _sendMessage(text: quick[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, -1)),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image, color: Colors.blue),
              tooltip: 'Gửi ảnh',
              onPressed: _pickImage, // GỌI NÚT GỬI ẢNH TẠI ĐÂY
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: "Nhập tin nhắn...",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _sendMessage(),
              child: const CircleAvatar(
                backgroundColor: Colors.blue,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        leading: const BackButton(color: Colors.black),
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.support_agent, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.roomName,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  "CSKH ChatFlow • Online",
                  style: TextStyle(fontSize: 12, color: Colors.green),
                ),
              ],
            )
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: messages[index]);
              },
            ),
          ),
          _buildQuickButtons(),
          const SizedBox(height: 8),
          _buildInputArea(),
        ],
      ),
    );
  }
}

// ---- TINH CHỈNH LẠI CHAT BUBBLE ĐỂ HỖ TRỢ ẢNH ----
class ChatBubble extends StatelessWidget {
  final Message message;

  const ChatBubble({super.key, required this.message});

  Widget _buildMessageContent(BuildContext context) {
    if (message.isTyping) {
      return const Text("Đang trả lời...");
    }

    // Hiển thị ảnh nếu đây là tin nhắn ảnh
    if (message.type == MessageType.image && message.imagePath != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            // Đổi Image.network thành Image.file(File(message.imagePath!)) nếu dùng chọn ảnh thật trong đt
            child: Image.network(
              message.imagePath!,
              width: 220,
              fit: BoxFit.cover,
              errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
            ),
          ),
          if (message.text.isNotEmpty) const SizedBox(height: 6),
          if (message.text.isNotEmpty)
            Text(
              message.text,
              style: TextStyle(color: message.isUser ? Colors.white : Colors.black),
            ),
        ],
      );
    }

    // Hiển thị text bình thường
    return Text(
      message.text,
      style: TextStyle(
        color: message.isUser ? Colors.white : Colors.black,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Căn avatar dưới đáy message
        children: [
          if (!message.isUser)
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(Icons.support_agent, color: Colors.white, size: 18),
              ),
            ),

          Flexible( // Tránh bị tràn màn hình khi chữ / ảnh lớn
            child: Column(
              crossAxisAlignment: message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(message.type == MessageType.image ? 6 : 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.blue : Colors.white,
                    // Bo góc thông minh: góc bên dưới cùng nằm chung hướng với avatar sẽ vuông lại
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: message.isUser ? const Radius.circular(16) : const Radius.circular(4),
                      bottomRight: message.isUser ? const Radius.circular(4) : const Radius.circular(16),
                    ),
                    boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 3)],
                  ),
                  child: _buildMessageContent(context),
                ),
                const SizedBox(height: 4),
                Text(
                  message.time,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                )
              ],
            ),
          ),

          if (message.isUser)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            )
        ],
      ),
    );
  }
}
