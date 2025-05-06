import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStoryPage extends StatefulWidget {
  const AdminStoryPage({super.key});

  @override
  State<AdminStoryPage> createState() => _AdminStoryPageState();
}

class _AdminStoryPageState extends State<AdminStoryPage> {
  final CollectionReference stories = FirebaseFirestore.instance.collection('stories');

  final TextEditingController titleController = TextEditingController();
  final TextEditingController authorController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController coverUrlController = TextEditingController();

  void showStoryDialog({DocumentSnapshot? doc}) {
    bool isEdit = doc != null;
    if (isEdit) {
      titleController.text = doc['title'];
      authorController.text = doc['author'];
      descriptionController.text = doc['description'];
      coverUrlController.text = doc['coverUrl'];
    } else {
      titleController.clear();
      authorController.clear();
      descriptionController.clear();
      coverUrlController.clear();
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF003E32),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          isEdit ? 'Sửa truyện' : 'Thêm truyện',
          style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            children: [
              buildInputField(titleController, 'Tên truyện'),
              const SizedBox(height: 12),
              buildInputField(authorController, 'Tác giả'),
              const SizedBox(height: 12),
              buildInputField(descriptionController, 'Mô tả'),
              const SizedBox(height: 12),
              buildInputField(coverUrlController, 'URL ảnh bìa'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.greenAccent,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              if (titleController.text.isEmpty) return;

              Map<String, dynamic> data = {
                'title': titleController.text,
                'author': authorController.text,
                'description': descriptionController.text,
                'coverUrl': coverUrlController.text,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (isEdit) {
                await stories.doc(doc!.id).update(data);
              } else {
                await stories.add(data);
              }

              Navigator.pop(context);
            },
            child: Text(isEdit ? 'Cập nhật' : 'Thêm'),
          ),
        ],
      ),
    );
  }

  Widget buildInputField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void deleteStory(String id) {
    stories.doc(id).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        title: const Text('Quản lý truyện', style: TextStyle(color: Colors.greenAccent)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stories.orderBy('updatedAt', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi khi tải dữ liệu', style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.greenAccent));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final story = docs[index];
              return Card(
                color: Colors.white10,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: story['coverUrl'] != null && story['coverUrl'].isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(story['coverUrl'], width: 50, height: 50, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.book, color: Colors.white),
                  title: Text(story['title'], style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                  subtitle: Text('Tác giả: ${story['author']}', style: const TextStyle(color: Colors.white70)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () => showStoryDialog(doc: story),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => deleteStory(story.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showStoryDialog(),
        backgroundColor: Colors.greenAccent,
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }
}
