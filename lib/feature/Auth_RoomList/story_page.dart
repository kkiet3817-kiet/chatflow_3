import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class StoryPage extends StatefulWidget {
  final String currentUserId;
  const StoryPage({super.key, required this.currentUserId});

  @override
  State<StoryPage> createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _uploadStory() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (image == null) return;

    setState(() => _isUploading = true);
    try {
      String fileName = "story_${widget.currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg";
      Reference ref = _storage.ref().child("stories").child(fileName);
      await ref.putFile(File(image.path));
      String url = await ref.getDownloadURL();

      await _firestore.collection('stories').add({
        'userId': widget.currentUserId,
        'imageUrl': url,
        'createdAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(hours: 24))),
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Đã đăng tin thành công!")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tin", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.add_a_photo), onPressed: _uploadStory),
        ],
      ),
      body: _isUploading 
          ? const Center(child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [CircularProgressIndicator(), SizedBox(height: 10), Text("Đang tải tin...")],
            ))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('stories').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text("Lỗi tải tin: ${snapshot.error}", textAlign: TextAlign.center),
                  ));
                }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Chưa có tin nào. Hãy là người đầu tiên!"));
                }
                
                final now = DateTime.now();
                final stories = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  if (data['expiresAt'] == null) return true;
                  try {
                    Timestamp expiresAt = data['expiresAt'] is Timestamp 
                        ? data['expiresAt'] 
                        : Timestamp.fromDate(DateTime.parse(data['expiresAt'].toString()));
                    return expiresAt.toDate().isAfter(now);
                  } catch (e) {
                    return true; 
                  }
                }).toList();

                if (stories.isEmpty) return const Center(child: Text("Chưa có tin nào. Hãy là người đầu tiên!"));

                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: stories.length,
                  itemBuilder: (context, index) {
                    final data = stories[index].data() as Map<String, dynamic>;
                    return _buildStoryItem(data);
                  },
                );
              },
            ),
    );
  }

  Widget _buildStoryItem(Map<String, dynamic> data) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(data['userId']).snapshots(),
      builder: (context, userSnap) {
        String name = data['userId'];
        String avatar = "";
        if (userSnap.hasData && userSnap.data!.exists) {
          final uData = userSnap.data!.data() as Map<String, dynamic>;
          name = uData['displayName'] ?? uData['username'] ?? name;
          avatar = uData['avatarUrl'] ?? "";
        }

        return GestureDetector(
          onTap: () => _showFullStory(data['imageUrl'] ?? "", name),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: Colors.grey.shade200,
              image: data['imageUrl'] != null && data['imageUrl'].toString().isNotEmpty
                ? DecorationImage(image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)
                : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 10, left: 10,
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white,
                    backgroundImage: NetworkImage(avatar.isNotEmpty ? avatar : "https://ui-avatars.com/api/?name=$name"),
                    child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blue, width: 2))),
                  ),
                ),
                Positioned(
                  bottom: 10, left: 10, right: 10,
                  child: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12, shadows: [Shadow(blurRadius: 5, color: Colors.black)]), overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showFullStory(String imageUrl, String name) {
    if (imageUrl.isEmpty) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: Image.network(
            imageUrl, 
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            },
            errorBuilder: (context, error, stackTrace) => const Center(child: Text("Lỗi tải ảnh", style: TextStyle(color: Colors.white))),
          )),
          Positioned(
            top: 50, left: 20,
            child: Row(children: [
              const BackButton(color: Colors.white),
              const SizedBox(width: 10),
              Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ]),
          ),
        ],
      ),
    )));
  }
}
