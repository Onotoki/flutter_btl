import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminStoryPage extends StatefulWidget {
  const AdminStoryPage({super.key});

  @override
  State<AdminStoryPage> createState() => _AdminStoryPageState();
}

class _AdminStoryPageState extends State<AdminStoryPage>
    with AutomaticKeepAliveClientMixin {
  final CollectionReference stories =
      FirebaseFirestore.instance.collection('stories');
  bool isLoading = false;
  final int limit = 10;
  DocumentSnapshot? lastDocument;
  bool hasMore = true;

  // Danh sách thể loại truyện
  final List<String> categories = [
    'Kinh dị',
    'Lãng mạn',
    'Trinh thám',
    'Khoa học viễn tưởng',
    'Fantasy',
    'Hài hước',
    'Tâm lý',
    'Lịch sử'
  ];
  String? selectedCategory;

  Future<List<QueryDocumentSnapshot>> getStories() async {
    try {
      Query query = stories.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }

      final snapshot = await query.get();

      if (snapshot.docs.length < limit) {
        hasMore = false;
      } else {
        lastDocument = snapshot.docs.last;
      }

      return snapshot.docs;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải dữ liệu: ${e.toString()}")),
      );
      return [];
    }
  }

  Future<void> loadMore() async {
    if (isLoading || !hasMore) return;

    setState(() => isLoading = true);
    try {
      await getStories();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi tải thêm: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleAddOrUpdate({
    DocumentSnapshot? document,
    required String title,
    required String author,
    required String category,
    required String storyUrl,
  }) async {
    setState(() => isLoading = true);
    try {
      final data = {
        'title': title,
        'author': author,
        'category': category,
        'storyUrl': storyUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

      if (document == null) {
        await stories.add(data);
      } else {
        await stories.doc(document.id).update(data);
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _handleDelete(String docId) async {
    setState(() => isLoading = true);
    try {
      await stories.doc(docId).delete();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xóa: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: const Color(0xFF003E32),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title:
            const Text("Quản lý truyện", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ],
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
                    itemCount: snapshot.data!.length + (hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == snapshot.data!.length) {
                        return Center(
                          child: TextButton(
                            onPressed: isLoading ? null : loadMore,
                            child: isLoading
                                ? CircularProgressIndicator()
                                : const Text(
                                    "Tải thêm",
                                    style: TextStyle(color: Colors.greenAccent),
                                  ),
                          ),
                        );
                      }

                      final doc = snapshot.data![index];
                      final data = doc.data() as Map<String, dynamic>?;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          leading:
                              const Icon(Icons.book, color: Colors.white70),
                          title: Text(
                            data?['title'] ?? 'Không có tiêu đề',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Tác giả: ${data?['author'] ?? 'Không rõ'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Thể loại: ${data?['category'] ?? 'Chưa phân loại'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.greenAccent),
                                onPressed: () => showStoryDialog(document: doc),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.redAccent),
                                onPressed: () => _handleDelete(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.greenAccent,
        onPressed: isLoading ? null : () => showStoryDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void showStoryDialog({DocumentSnapshot? document}) {
    final titleController =
        TextEditingController(text: document?['title'] ?? '');
    final authorController =
        TextEditingController(text: document?['author'] ?? '');
    final storyUrlController =
        TextEditingController(text: document?['storyUrl'] ?? '');
    final formKey = GlobalKey<FormState>();

    // Thiết lập thể loại ban đầu
    if (document != null) {
      final data = document.data() as Map<String, dynamic>?;
      selectedCategory = data?['category'] ?? categories.first;
    } else {
      selectedCategory = categories.first;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF003E32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    document == null ? "Thêm truyện mới" : "Chỉnh sửa truyện",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Ô nhập tiêu đề
                  TextFormField(
                    controller: titleController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Tiêu đề",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Vui lòng nhập tiêu đề' : null,
                  ),
                  const SizedBox(height: 15),

                  // Ô nhập tác giả
                  TextFormField(
                    controller: authorController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Tác giả",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Vui lòng nhập tác giả' : null,
                  ),
                  const SizedBox(height: 15),

                  // Dropdown chọn thể loại
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    dropdownColor: const Color(0xFF003E32),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "Thể loại",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                    items: categories.map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn thể loại' : null,
                  ),
                  const SizedBox(height: 15),

                  // Ô nhập URL truyện
                  TextFormField(
                    controller: storyUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: "URL truyện",
                      labelStyle: const TextStyle(color: Colors.white70),
                      filled: true,
                      fillColor: Colors.white10,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Colors.greenAccent),
                      ),
                    ),
                    validator: (value) => value?.isEmpty ?? true
                        ? 'Vui lòng nhập URL truyện'
                        : null,
                  ),
                  const SizedBox(height: 25),

                  // Nút hành động
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Hủy",
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: () async {
                          if (formKey.currentState!.validate()) {
                            Navigator.pop(context);
                            await _handleAddOrUpdate(
                              document: document,
                              title: titleController.text.trim(),
                              author: authorController.text.trim(),
                              category: selectedCategory!,
                              storyUrl: storyUrlController.text.trim(),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text(
                          "Lưu",
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
