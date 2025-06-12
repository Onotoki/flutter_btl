import 'package:flutter/material.dart';

class ReadingBooks extends StatelessWidget {
  const ReadingBooks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Đang đọc'),
        ),
        body: SizedBox(
          child: ListView.builder(
            itemCount: 10,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10.0, left: 10),
                child: SizedBox(
                  height: 90,
                  child: Row(
                    children: [
                      SizedBox(
                        height: 90,
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.asset('lib/images/book.jpg')),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Siêu Năng Lập Phương',
                            style: TextStyle(fontSize: 16),
                          ),
                          Text('61,93%'),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ));
  }
}
