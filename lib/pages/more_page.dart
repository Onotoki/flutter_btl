import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/reading_books.dart';
import 'package:btl/cubit/theme_cubit.dart';
import 'package:btl/cubit/theme_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Person extends StatelessWidget {
  Person({super.key});
  List<String> listMode = ['lightTheme', 'darkTheme'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
          body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35, // tuỳ chỉnh kích thước
                  backgroundImage: AssetImage('lib/images/book.jpg'),
                ),
                const SizedBox(
                  width: 10,
                ),
                GestureDetector(
                  onTap: () {
                    _showEditDialog(context);
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UserName',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text('tinvu@gmail.com'),
                    ],
                  ),
                )
              ],
            ),
          ),
          const SizedBox(
            height: 35,
          ),
          Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10),
                  leading: const Icon(Icons.menu_book),
                  title: const Text('Đang đọc'),
                  trailing: const Icon(Icons.navigate_next_rounded),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ReadingBooks()),
                    );
                  },
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10),
                  leading: const Icon(Icons.contact_emergency),
                  title: const Text('Liên hệ'),
                  trailing: const Icon(Icons.navigate_next_rounded),
                  onTap: () {},
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10),
                  leading: const Icon(Icons.security),
                  title: const Text('Chính sách bảo mật'),
                  trailing: const Icon(Icons.navigate_next_rounded),
                  onTap: () {},
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1),
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
                    items:
                        listMode.map<DropdownMenuItem<String>>((String value) {
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
              ),
              Container(
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                        width: 1, color: Theme.of(context).colorScheme.primary),
                    bottom: BorderSide(
                        width: 1, color: Theme.of(context).colorScheme.primary),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.only(left: 10),
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text(
                    'Đăng xuất',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReadingBooks(),
                      ),
                    );
                  },
                ),
              ),
            ],
          )
        ],
      )),
    );
  }

  void _showEditDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    // Dùng hàm builder để tạo InputDecoration chung
    InputDecoration _inputDecoration(String label) => InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.5),
          ),
          focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey, width: 0.5),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
                  decoration: _inputDecoration('Tên hiển thị'),
                  validator: (v) =>
                      (v?.isEmpty ?? true) ? 'Không được để trống' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
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
                  decoration: _inputDecoration('Mật khẩu'),
                  obscureText: true,
                  validator: (v) =>
                      (v?.length ?? 0) < 6 ? 'Ít nhất 6 ký tự' : null,
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
                ontap: () {
                  Navigator.of(context).pop();
                },
              ),
              SizedBox(
                width: 10,
              ),
              Button_Info(
                text: 'Huỷ',
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                flex: 1,
                ontap: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
