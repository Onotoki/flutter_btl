import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:btl/pages/Intropage/intro_page.dart';
import 'package:btl/pages/search_page.dart';
import 'package:btl/components/info_book_widgets.dart/reading_books.dart';
import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';

class Person extends StatelessWidget {
  Person({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Phần header thông tin user
            _buildUserHeader(context),
            
            // Danh sách chức năng
            Expanded(
              child: _buildFunctionList(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserHeader(BuildContext context) {
    final User? user = _auth.currentUser;
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;
    final bgColor = isDarkTheme ? Colors.grey[900] : Colors.white;

    return Container(
      color: bgColor,
      padding: const EdgeInsets.all(16),
      child: user != null 
          ? _buildLoggedInUser(user, context)
          : _buildGuestUser(),
    );
  }

  Widget _buildLoggedInUser(User user, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        // Xử lý loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildUserPlaceholder();
        }

        // Xử lý lỗi
        if (snapshot.hasError) {
          debugPrint('Error loading user data: ${snapshot.error}');
          return _buildUserInfo(
            displayName: user.displayName ?? 'UserName',
            email: user.email ?? 'No email',
            photoUrl: user.photoURL,
            context: context,
          );
        }

        // Lấy dữ liệu từ Firestore
        final userData = snapshot.data?.data() as Map<String, dynamic>?;
        return _buildUserInfo(
          displayName: userData?['nickname'] ?? user.displayName ?? 'UserName',
          email: user.email ?? 'No email',
          photoUrl: userData?['profileImage'] ?? user.photoURL,
          context: context,
        );
      },
    );
  }

  Widget _buildUserInfo({
    required String displayName,
    required String email,
    required String? photoUrl,
    required BuildContext context,
  }) {
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return GestureDetector(
      onTap: () => _showEditDialog(context, displayName, email),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage: _getImageProvider(photoUrl),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ImageProvider _getImageProvider(String? url) {
    if (url == null || url.isEmpty) {
      return const AssetImage('lib/images/default_avatar.png');
    }
    return url.startsWith('http') 
        ? NetworkImage(url) 
        : AssetImage(url);
  }

  Widget _buildGuestUser() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 36,
          child: Icon(Icons.person_outline),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Khách',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            Text(
              'Đăng nhập để mở khóa tính năng',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionList(BuildContext context) {
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;
    final bgColor = isDarkTheme ? Colors.grey[900] : Colors.white;
    final borderColor = isDarkTheme ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      color: bgColor,
      child: SingleChildScrollView(
        child: Column(
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
              icon: Icons.history,
              title: 'Lịch sử đọc',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.bookmark,
              title: 'Đánh dấu',
              onTap: () {},
            ),
            _buildListTile(
              context,
              icon: Icons.settings,
              title: 'Cài đặt',
              onTap: () {},
            ),
            _buildThemeSwitchTile(context),
            _buildListTile(
              context,
              icon: Icons.help,
              title: 'Trợ giúp & Phản hồi',
              onTap: () {},
            ),
            _buildLogoutTile(context),
          ],
        ),
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    VoidCallback? onTap,
  }) {
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;
    final bgColor = isDarkTheme ? Colors.grey[900] : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;
    final borderColor = isDarkTheme ? Colors.grey[800]! : Colors.grey[300]!;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: borderColor, width: 1),
        ),
        color: bgColor,
      ),
      child: ListTile(
        leading: Icon(icon, color: textColor),
        title: Text(title, style: TextStyle(color: textColor)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSwitchTile(BuildContext context) {
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;
    final bgColor = isDarkTheme ? Colors.grey[900] : Colors.white;
    final textColor = isDarkTheme ? Colors.white : Colors.black;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
        color: bgColor,
      ),
      child: ListTile(
        leading: Icon(Icons.color_lens, color: textColor),
        title: Text('Chế độ tối', style: TextStyle(color: textColor)),
        trailing: Switch(
          value: isDarkTheme,
          onChanged: (value) {
            context.read<ThemeCubit>().toggleTheme();
          },
          activeColor: Colors.greenAccent,
        ),
      ),
    );
  }

  Widget _buildLogoutTile(BuildContext context) {
    final User? user = _auth.currentUser;
    if (user == null) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.grey[300]!, width: 1),
          bottom: BorderSide(color: Colors.grey[300]!, width: 1),
        ),
      ),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.red),
        title: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
        onTap: () => _showLogoutConfirmation(context),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const IntroPage()),
                (_) => false,
              );
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String currentName, String currentEmail) {
    final _nameController = TextEditingController(text: currentName);
    final _emailController = TextEditingController(text: currentEmail);
    final _passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Chỉnh sửa thông tin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Tên hiển thị'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Mật khẩu mới (để trống nếu không đổi)'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => _updateUserInfo(
              context,
              _nameController.text,
              _emailController.text,
              _passwordController.text,
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Lưu', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _updateUserInfo(
    BuildContext context,
    String newName,
    String newEmail,
    String newPassword,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      // Cập nhật trong Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'nickname': newName,
        if (newEmail != user.email) 'email': newEmail,
      });

      // Cập nhật trong Firebase Auth
      if (newName != user.displayName) {
        await user.updateDisplayName(newName);
      }

      if (newEmail != user.email) {
        await user.updateEmail(newEmail);
      }

      if (newPassword.isNotEmpty) {
        await user.updatePassword(newPassword);
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cập nhật thông tin thành công')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi cập nhật: ${e.toString()}')),
      );
    }
  }

  Widget _buildUserPlaceholder() {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 120,
              height: 20,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 8),
            Container(
              width: 160,
              height: 16,
              color: Colors.grey[300],
            ),
          ],
        ),
      ],
    );
  }
}