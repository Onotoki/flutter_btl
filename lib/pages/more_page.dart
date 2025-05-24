import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/reading_books.dart';
import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Person extends StatelessWidget {
  Person({super.key});
  
  final List<String> listMode = ['lightTheme', 'darkTheme'];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;
    
    return SafeArea(
      child: Scaffold(
        body: StreamBuilder<DocumentSnapshot>(
          stream: user != null 
              ? _firestore.collection('users').doc(user.uid).snapshots()
              : null,
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() as Map<String, dynamic>?;
            final displayName = userData?['nickname'] ?? user?.displayName ?? 'UserName';
            final email = user?.email ?? 'Email';
            final photoUrl = userData?['profileImage'] ?? user?.photoURL ?? 'lib/images/book.jpg';

            return Column(
              children: [
                // Phần thông tin user
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 35,
                        backgroundImage: photoUrl.startsWith('http')
                            ? NetworkImage(photoUrl)
                            : AssetImage(photoUrl) as ImageProvider,
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () => _showEditDialog(context, displayName, email),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: const TextStyle(fontSize: 18),
                            ),
                            Text(email),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                const SizedBox(height: 35),

                // Các menu chức năng
                Column(
                  children: [
                    _buildListTile(
                      context,
                      icon: Icons.menu_book,
                      title: 'Đang đọc',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ReadingBooks()),
                      ),
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.contact_emergency,
                      title: 'Liên hệ',
                      onTap: () {},
                    ),
                    _buildListTile(
                      context,
                      icon: Icons.security,
                      title: 'Chính sách bảo mật',
                      onTap: () {},
                    ),
                    _buildThemeListTile(context),
                    _buildLogoutTile(context),
                  ],
                )
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Color? color,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 10),
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(color: color)),
        trailing: color == null ? const Icon(Icons.navigate_next_rounded) : null,
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeListTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 10),
        leading: const Icon(Icons.color_lens),
        title: const Text('Màu nền'),
        trailing: DropdownButton<String>(
          underline: const SizedBox(),
          menuWidth: 130,
          padding: const EdgeInsets.all(10),
          value: context.watch<ThemeCubit>().state is LightTheme
              ? 'lightTheme'
              : 'darkTheme',
          isDense: true,
          items: listMode.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value),
              onTap: () {
                if (value == 'lightTheme') {
                  context.read<ThemeCubit>().lightThemeEvent();
                } else {
                  context.read<ThemeCubit>().darkThemeEvent();
                }
              },
            );
          }).toList(),
          onChanged: (_) {},
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.primary,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 10),
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text(
          'Đăng xuất',
          style: TextStyle(color: Colors.red),
        ),
        onTap: () async {
          try {
            // Hiển thị dialog xác nhận
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Xác nhận'),
                content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Huỷ'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const IntroPage()),
                (route) => false,
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi khi đăng xuất: ${e.toString()}')),
            );
          }
        },
      ),
    );
  }

  void _showEditDialog(BuildContext context, String currentName, String currentEmail) {
    final _formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final passwordController = TextEditingController();

    InputDecoration _inputDecoration(String label) => InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey, width: 0.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: _inputDecoration('Tên hiển thị'),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: _inputDecoration('Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Không được để trống';
                    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                    return emailRegex.hasMatch(v) ? null : 'Email không hợp lệ';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: passwordController,
                  decoration: _inputDecoration('Mật khẩu mới (để trống nếu không đổi)'),
                  obscureText: true,
                ),
              ],
            ),
          ),
        ),
        actions: [
          Row(
            children: [
              Button_Info(
                text: 'Lưu',
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                flex: 2,
                ontap: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final user = _auth.currentUser;
                      if (user != null) {
                        // Cập nhật display name
                        await user.updateDisplayName(nameController.text);
                        
                        // Cập nhật trong Firestore
                        await _firestore.collection('users').doc(user.uid).update({
                          'nickname': nameController.text,
                          'email': emailController.text,
                        });

                        // Nếu thay đổi email
                        if (emailController.text != currentEmail) {
                          await user.updateEmail(emailController.text);
                        }

                        // Nếu có nhập mật khẩu mới
                        if (passwordController.text.isNotEmpty) {
                          await user.updatePassword(passwordController.text);
                        }
                      }
                      Navigator.of(context).pop();
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi: ${e.toString()}')),
                      );
                    }
                  }
                },
              ),
              const SizedBox(width: 10),
              Button_Info(
                text: 'Huỷ',
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                flex: 1,
                ontap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}