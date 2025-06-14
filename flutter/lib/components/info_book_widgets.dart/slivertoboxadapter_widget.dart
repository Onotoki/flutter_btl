import 'package:btl/components/info_book_widgets.dart/button_info.dart';
import 'package:btl/components/info_book_widgets.dart/image_info.dart';
import 'package:btl/components/info_book_widgets.dart/rate_widget.dart';
import 'package:flutter/material.dart';

class SlivertoboxadapterWidget extends StatelessWidget {
  final VoidCallback scrollDown;
  String linkImage;
  SlivertoboxadapterWidget(
      {super.key, required this.scrollDown, required this.linkImage});

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
                    const SizedBox(
                      width: 10,
                    ),
                    Button_Info(
                      text: 'Chương',
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.green,
                      flex: 2,
                      ontap: () {
                        scrollDown();
                      },
                    )
                  ],
                ),

                const SizedBox(
                  height: 12,
                ),

                // Tên truyện và thể loại
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    const Text(
                      'Siêu Năng Lập Phương',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
                    ),
                    Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(4)),
                        child: const Text(
                          'Phiêu Lưu',
                          style: TextStyle(
                            fontSize: 11,
                          ),
                        ))
                  ],
                ),

                const SizedBox(
                  height: 15,
                ),

                // Tóm tắt
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                        flex: 4,
                        child: SizedBox(
                          height: 60,
                          child: const Text(
                              'Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được "Siêu Năng Lập Phương"- hệ thống không gian từ văn minh vũ trụ. Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được '),
                        )),
                    Expanded(
                        child: TextButton(
                            onPressed: () {
                              showModalBottomSheet(
                                context: context,
                                builder: (context) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16, horizontal: 10),
                                    height: 400,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Tóm tắt',
                                          style: TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w700),
                                        ),
                                        const Divider(),
                                        const Text(
                                            style: TextStyle(fontSize: 16),
                                            'Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được "Siêu Năng Lập Phương"- hệ thống không gian từ văn minh vũ trụ. Cậu thiếu niên bình thường Vương Tiểu Tu trong 1 sự cố bất ngờ đã nhậ được ')
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            child: const Text(
                              'Chi tiết',
                              style:
                                  TextStyle(fontSize: 14, color: Colors.green),
                            )))
                  ],
                ),

                const SizedBox(
                  height: 20,
                ),

                // Đánh giá và bình luận
                // TODO: Cập nhật RateAllWidget với các tham số cần thiết
                // RateAllWidget(
                //   idBook: 'book_id_here',
                //   slug: 'book_slug_here',
                //   title: 'Siêu Năng Lập Phương',
                //   totalChapter: 100,
                // ),
                Container(
                  height: 60,
                  child: const Center(
                    child: Text('Đánh giá và Yêu thích sẽ được cập nhật sau'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 14,
          ),
        ],
      ),
    );
  }
}
