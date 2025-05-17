import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_icon.dart';
import 'package:flutter/material.dart';

class RatingSelector extends StatefulWidget {
  const RatingSelector({super.key});

  @override
  State<RatingSelector> createState() => _RatingSelectorState();
}

class _RatingSelectorState extends State<RatingSelector> {
  int? selectedIndex;

  final List<Map<String, dynamic>> items = [
    {
      'icon': 'lib/images/rate_icons/rate-5.webp',
      'text': 'Tuyệt vời',
      'color': Colors.green,
    },
    {
      'icon': 'lib/images/rate_icons/rate-4.webp',
      'text': 'Hay nha',
      'color': Colors.green,
    },
    {
      'icon': 'lib/images/rate_icons/rate-3.webp',
      'text': 'Khá ổn',
      'color': Colors.green,
    },
    {
      'icon': 'lib/images/rate_icons/rate-2.webp',
      'text': 'Chán ngắt',
      'color': Colors.green,
    },
    {
      'icon': 'lib/images/rate_icons/rate-1.webp',
      'text': 'Dở tệ',
      'color': Colors.green,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(
              items.length,
              (index) {
                final item = items[index];
                return RateWidget(
                  isSelected: selectedIndex == index,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                  imageIcon: item['icon'],
                  textIcon: item['text'],
                  activeColor: item['color'],
                );
              },
            ),
          ),
        ),
        SizedBox(
          height: 30,
        ),
        Row(
          children: [
            Button_Info(
              text: 'Gửi đánh giá',
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              flex: 1,
              ontap: () {},
            ),
            const SizedBox(
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
            )
          ],
        ),
      ],
    );
  }
}
