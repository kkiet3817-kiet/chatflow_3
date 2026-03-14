import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';

class NotePage extends StatefulWidget {
  final String currentUserId;
  const NotePage({super.key, required this.currentUserId});

  @override
  State<NotePage> createState() => _NotePageState();
}

class _NotePageState extends State<NotePage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _noteController = TextEditingController();
  
  File? _selectedAudio;
  String? _audioName;
  bool _isSending = false;

  Future<void> _pickAudio() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedAudio = File(result.files.single.path!);
          _audioName = result.files.single.name;
        });
      }
    } catch (e) {
      debugPrint("Lỗi chọn nhạc: $e");
    }
  }

  Future<void> _postNote() async {
    if (_noteController.text.trim().isEmpty && _selectedAudio == null) return;

    setState(() => _isSending = true);
    try {
      String? audioUrl;
      if (_selectedAudio != null) {
        String fileName = "note_audio_${widget.currentUserId}_${DateTime.now().millisecondsSinceEpoch}.mp3";
        Reference ref = _storage.ref().child("note_audios").child(fileName);
        await ref.putFile(_selectedAudio!);
        audioUrl = await ref.getDownloadURL();
      }

      await _firestore.collection('notes').doc(widget.currentUserId).set({
        'userId': widget.currentUserId,
        'content': _noteController.text.trim(),
        'audioUrl': audioUrl,
        'audioName': _audioName,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      });
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã chia sẻ ghi chú!")));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Ghi chú mới", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          TextButton(
            onPressed: _isSending ? null : _postNote,
            child: Text(_isSending ? "Đang gửi..." : "Chia sẻ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('users').doc(widget.currentUserId).snapshots(),
                  builder: (context, snap) {
                    String avatar = "";
                    if (snap.hasData && snap.data!.exists) {
                      avatar = (snap.data!.data() as Map<String, dynamic>)['avatarUrl'] ?? "";
                    }
                    return CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=${widget.currentUserId}"),
                    );
                  }
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: TextField(
                          controller: _noteController,
                          maxLength: 60,
                          maxLines: 3,
                          autofocus: true,
                          decoration: const InputDecoration(
                            hintText: "Chia sẻ ý nghĩ của bạn...",
                            border: InputBorder.none,
                            counterText: "",
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_audioName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.music_note, color: Colors.blue, size: 18),
                              const SizedBox(width: 5),
                              Flexible(child: Text(_audioName!, style: const TextStyle(color: Colors.blue, fontSize: 12), overflow: TextOverflow.ellipsis)),
                              const SizedBox(width: 5),
                              GestureDetector(
                                onTap: () => setState(() { _selectedAudio = null; _audioName = null; }),
                                child: const Icon(Icons.close, color: Colors.blue, size: 18),
                              ),
                            ],
                          ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _pickAudio,
                          icon: const Icon(Icons.music_note, size: 18),
                          label: const Text("Thêm nhạc"),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text("Bạn bè có thể xem và nghe ghi chú của bạn trong 24 giờ.", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
