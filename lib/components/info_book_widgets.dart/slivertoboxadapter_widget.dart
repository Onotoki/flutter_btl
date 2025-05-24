import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/image_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_widget.dart';
import 'package:flutter/material.dart';

class SlivertoboxadapterWidget extends StatelessWidget {
  // final VoidCallback scrollDown;
  String linkImage;
  SlivertoboxadapterWidget({super.key, required this.linkImage, required void Function() scrollDown});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          // Ảnh truyện
          Image_Info(
            linkImage: linkImage,
          ),

          // Thông tin và đánh giá
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Nút bấm "Đọc ngay" và "Chương"
                Row(
                  children: [
                    Button_Info(
                      text: 'Đọc ngay',
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      flex: 3,
                      ontap: () {},
                    ),
                    const SizedBox(width: 10),
                    Button_Info(
                      text: 'Audio',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      flex: 2,
                      ontap: () {
                        // scrollDown();
                      },
                    )
                  ],
                ),

                SizedBox(
                  height: 12,
                ),

                // Tên truyện và thể loại
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      'Siêu Năng Lập Phương',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Container(
                        padding: EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text(
                          'Phiêu Lưu',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ))
                  ],
                ),

                SizedBox(
                  height: 15,
                ),

                // Tóm tắt
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 4,
                        child: Container(
                          height: 60,
                          child: Text(
                              'Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được "Siêu Năng Lập Phương"- hệ thống không gian từ văn minh vũ trụ. Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được '),
                        )),
                    Expanded(
                        child: TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Container(
                                    padding: EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 10),
                                    height: 400,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Tóm tắt',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        Divider(),
                                        Text(
                                            style: TextStyle(fontSize: 16),
                                            'Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được "Siêu Năng Lập Phương"- hệ thống không gian từ văn minh vũ trụ. Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được ')
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: Text(
                              'Chi tiết',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.green),
                            )))
                  ],
                ),

                SizedBox(
                  height: 20,
                ),

                // Đánh giá và bình luận
                RateAllWidget(),
              ],
            ),
          ),

          SizedBox(
            height: 14,
          ),
        ],
      ),
    );
  }
}
