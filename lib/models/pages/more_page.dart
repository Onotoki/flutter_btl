import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:btl/models/pages/Intropage/intro_page.dart';
import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';

class Person extends StatelessWidget {
  Person({super.key});

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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

    return Container(
      padding: const EdgeInsets.all(16),
      child:
          user != null ? _buildLoggedInUser(user, context) : _buildGuestUser(),
    );
  }

  Widget _buildLoggedInUser(User user, BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.email).snapshots(),
      builder: (context, snapshot) {
        // Xử lý loading state
        if (snapshot.connectionState == ConnectionState.waiting) {
          // return _buildUserPlaceholder();
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
          displayName: userData?['nickname'] ?? 'UserName',
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
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
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
    return url.startsWith('http') ? NetworkImage(url) : AssetImage(url);
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
                // color: Colors.grey[600],
              ),
            ),
            Text(
              'Đăng nhập để mở khóa tính năng',
              style: TextStyle(
                fontSize: 14,
                // color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFunctionList(BuildContext context) {
    return Container(
      child: SingleChildScrollView(
        child: Column(
          children: [
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              width: 2, color: Theme.of(context).colorScheme.primary),
        ),
        // color: bgColor,
      ),
      child: ListTile(
        leading: Icon(
          icon,
        ),
        title: Text(
          title,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildThemeSwitchTile(BuildContext context) {
    final isDarkTheme = context.watch<ThemeCubit>().state is DarkTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
              width: 2, color: Theme.of(context).colorScheme.primary),
        ),
      ),
      child: ListTile(
        leading: Icon(
          Icons.color_lens,
        ),
        title: Text(
          'Chế độ sáng/tối',
        ),
        trailing: Switch(
          inactiveThumbColor: Colors.grey,
          // trackOutlineColor: null,
          // trackOutlineWidth: ,
          trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) {
            if (states.contains(WidgetState.selected)) {
              return Colors.transparent;
            }

            return Colors.grey; // Use the default color.
          }),

          value: isDarkTheme,
          onChanged: (value) {
            // Gọi ThemeCubit để thay đổi theme
            if (value) {
              context.read<ThemeCubit>().darkThemeEvent();
            } else {
              context.read<ThemeCubit>().lightThemeEvent();
            }
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
          top: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
          bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary, width: 2),
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
            child: const Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
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

  void _showEditDialog(
      BuildContext context, String currentName, String currentEmail) {
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
                decoration: const InputDecoration(
                    labelText: 'Mật khẩu mới (để trống nếu không đổi)'),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Hủy',
              style: TextStyle(color: Colors.grey),
            ),
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
      await _firestore.collection('users').doc(user.email).update({
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
    print('Chạy hàm load lại ');
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
