import 'package:flutter/material.dart';

// 1. Tạo class model để phân biệt tin nhắn của người dùng và tin nhắn Bot
class ChatMessage {
  final String text;
  final bool isMe;

  ChatMessage({required this.text, required this.isMe});
}

class ChatUI extends StatefulWidget {
  final String roomName;

  const ChatUI({super.key, required this.roomName});

  @override
  State<ChatUI> createState() => _ChatUIState();
}

class _ChatUIState extends State<ChatUI> {
  final TextEditingController _controller = TextEditingController();
  final List<ChatMessage> messages = [];

  // Biến trạng thái để kiểm tra người dùng có đang gõ chữ hay không
  bool _isComposing = false;

  void sendMessage(String text) {
    if (text.trim().isEmpty) return;

    setState(() {
      // Tin nhắn gửi đi
      messages.add(ChatMessage(text: text.trim(), isMe: true));
      _isComposing = false;
    });

    _controller.clear();

    /// Auto reply của bot sau 1 giây
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          messages.add(ChatMessage(
            text: "Bot: Tôi đã nhận log: ${text.trim()}",
            isMe: false,
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        /// ================= LIST MESSAGE ================= ///
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              return _buildMessageBubble(messages[index]);
            },
          ),
        ),

        /// ================= KHU VỰC NHẬP TEXT ================= ///
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          color: Colors.white,
          child: SafeArea(
            bottom: true, // Hỗ trợ tránh các vùng vuốt dưới cùng của iPhone/Android
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                /// Nút Dấu cộng (Luôn hiện)
                IconButton(
                  icon: const Icon(Icons.add_circle),
                  color: Colors.blue,
                  onPressed: () {
                    // Xử lý khi bấm nút Thêm
                  },
                ),

                /// Các nút Camera, Ảnh, Mic sẽ bị ẩn đi khi đang gõ chữ
                if (!_isComposing) ...[
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    color: Colors.blue,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo),
                    color: Colors.blue,
                    onPressed: () {},
                  ),
                  IconButton(
                    icon: const Icon(Icons.mic),
                    color: Colors.blue,
                    onPressed: () {},
                  ),
                ] else ...[
                  /// Nút thu gọn thanh công cụ (Icon mũi tên giống Messenger)
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios, size: 20),
                    color: Colors.blue,
                    onPressed: () {},
                  ),
                ],

                /// Text field khu vực gõ văn bản
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            maxLines: null, // Cho phép gõ xuống dòng như Zalo/Mess
                            keyboardType: TextInputType.multiline,
                            onChanged: (text) {
                              setState(() {
                                // Nếu có chữ sẽ hiện nút Send, nếu xóa hết sẽ hiện nút Like
                                _isComposing = text.trim().isNotEmpty;
                              });
                            },
                            decoration: const InputDecoration(
                              hintText: "Aa",
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                            ),
                          ),
                        ),
                        // Nút mặt cười Emoji mờ mờ ở trong khung Text
                        IconButton(
                          icon: const Icon(Icons.sentiment_satisfied_alt),
                          color: Colors.blue,
                          padding: const EdgeInsets.only(bottom: 10, right: 8),
                          constraints: const BoxConstraints(),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ),
                ),

                /// Nút Gửi hoặc Nút Like hiển thị tương ứng
                if (_isComposing)
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: () => sendMessage(_controller.text),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.thumb_up),
                    color: Colors.blue,
                    onPressed: () => sendMessage("👍"),
                  ),
              ],
            ),
          ),
        )
      ],
    );
  }

  /// Hàm hỗ trợ vẽ từng Bong bóng Chat (Message Bubble)
  Widget _buildMessageBubble(ChatMessage message) {
    bool isMe = message.isMe;

    return Align(
      // Canh phải nếu là mình gửi, canh trái nếu là người khác gửi
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            // Tạo góc nhọn chĩa về phía avatar người gửi (giống giao diện Mess)
            bottomLeft: Radius.circular(isMe ? 20 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 20),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isMe ? Colors.white : Colors.black87,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
