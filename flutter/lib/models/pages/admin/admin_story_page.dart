import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminStoryPage extends StatefulWidget {
  const AdminStoryPage({super.key});

  @override
  State<AdminStoryPage> createState() => _AdminStoryPageState();
}

class _AdminStoryPageState extends State<AdminStoryPage>
    // AutomaticKeepAliveClientMixin giúp giữ trạng thái của widget khi chuyển đổi giữa các tab
    with AutomaticKeepAliveClientMixin {
  final CollectionReference users =
      FirebaseFirestore.instance.collection('users');
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  final int limit = 10;
  DocumentSnapshot? lastDocument; // Lưu tài liệu cuối cùng để phân trang
  bool hasMore = true;

  // Danh sách các auth provider phổ biến
  final List<String> authProviders = [
    'email',
    'google.com',
  ];
  String? selectedAuthProvider;

  Future<List<QueryDocumentSnapshot>> getUsers() async {
    try {
      Query query = users.orderBy('createdAt', descending: true).limit(limit);
      // Nếu có tài liệu cuối cùng, sử dụng startAfterDocument để phân trang
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument!);
      }
      // Thực hiện truy vấn để lấy dữ liệu
      final snapshot = await query.get();
      // Kiểm tra xem có dữ liệu hay không
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
      await getUsers();
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
    required String nickname,
    required String email,
    required String password,
    required String authProvider,
  }) async {
    setState(() => isLoading = true);
    try {
      final data = {
        'nickname': nickname,
        'email': email,
        'authProvider': authProvider,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Chỉ thêm password nếu provider là email và password không rỗng
      if (authProvider == 'email' && password.isNotEmpty) {
        data['password'] = password;
        
        // Nếu là tài khoản mới, tạo user trong Firebase Auth
        if (document == null) {
          try {
            await _auth.createUserWithEmailAndPassword(
              email: email,
              password: password,
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Lỗi tạo tài khoản: ${e.toString()}")),
            );
            return;
          }
        }
      }

      if (document == null) {
      await users.doc(email).set(data); // Sử dụng email làm ID
    } else {
      await users.doc(document.id).update(data);
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
  // Hiển thị hộp thoại xác nhận
  bool confirmDelete = await showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: const Color(0xFF003E32),
      title: const Text(
        "Xác nhận",
        style: TextStyle(color: Colors.greenAccent),
      ),
      content: const Text(
        "Bạn có chắc chắn muốn xóa tài khoản này không?",
        style: TextStyle(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false), // Không xóa
          child: const Text(
            "Không",
            style: TextStyle(color: Colors.white70),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true), // Đồng ý xóa
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
          ),
          child: const Text("Có"),
        ),
      ],
    ),
  );

  // Nếu người dùng chọn "Có", tiến hành xóa
  if (confirmDelete == true) {
    setState(() => isLoading = true);
    try {
      await users.doc(docId).delete();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi xóa: ${e.toString()}")),
      );
    } finally {
      setState(() => isLoading = false);
    }
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
        title: const Text("Quản lý độc giả",
            style: TextStyle(color: Colors.white)),
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
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Icon(Icons.people, size: 60, color: Colors.greenAccent),
            const SizedBox(height: 10),
            const Text(
              "Quản lý Độc Giả",
              style: TextStyle(
                color: Colors.greenAccent,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: FutureBuilder<List<QueryDocumentSnapshot>>(
                future: getUsers(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Lỗi tải dữ liệu",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Text(
                        "Không có độc giả nào",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

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
                              const Icon(Icons.person, color: Colors.white70),
                          title: Text(
                            data?['nickname'] ?? 'Không có nickname',
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Email: ${data?['email'] ?? 'Không có email'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              Text(
                                "Auth Provider: ${data?['authProvider'] ?? 'Không rõ'}",
                                style: const TextStyle(color: Colors.white70),
                              ),
                              if (data?['authProvider'] == 'email' &&
                                  data?['password'] != null)
                                Text(
                                  "Password: ${data?['password']}",
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
                                onPressed: () => showUserDialog(document: doc),
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
        onPressed: isLoading ? null : () => showUserDialog(),
        child: const Icon(Icons.add, color: Colors.black),
      ),
    );
  }

  void showUserDialog({DocumentSnapshot? document}) {
    final nicknameController =
        TextEditingController(text: document?['nickname'] ?? '');
    final emailController =
        TextEditingController(text: document?['email'] ?? '');
    final passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    // Thiết lập auth provider ban đầu
    selectedAuthProvider = document?['authProvider'] as String? ?? 'email';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
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
                        document == null ? "Thêm độc giả mới" : "Chỉnh sửa độc giả",
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Nickname
                      TextFormField(
                        controller: nicknameController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Nickname",
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
                            ? 'Vui lòng nhập nickname'
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      TextFormField(
                        controller: emailController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Email",
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
                            value?.isEmpty ?? true ? 'Vui lòng nhập email' : null,
                      ),
                      const SizedBox(height: 15),

                      // Mật khẩu (chỉ hiển thị khi authProvider là email)
                      if (selectedAuthProvider == 'email')
                        TextFormField(
                          controller: passwordController,
                          obscureText: true,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: document == null ? "Mật khẩu" : "Mật khẩu mới (để trống nếu không đổi)",
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
                          validator: (value) {
                            if (selectedAuthProvider == 'email' && 
                                document == null && 
                                (value == null || value.isEmpty)) {
                              return 'Vui lòng nhập mật khẩu';
                            }
                            return null;
                          },
                        ),
                      if (selectedAuthProvider == 'email')
                        const SizedBox(height: 15),

                      // Auth Provider Dropdown
                      DropdownButtonFormField<String>(
                        value: selectedAuthProvider,
                        dropdownColor: const Color(0xFF003E32),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          labelText: "Auth Provider",
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
                        items: authProviders.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedAuthProvider = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Vui lòng chọn auth provider' : null,
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
                                  nickname: nicknameController.text.trim(),
                                  email: emailController.text.trim(),
                                  password: passwordController.text.trim(),
                                  authProvider: selectedAuthProvider!,
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
          );
        },
      ),
    );
  }
}