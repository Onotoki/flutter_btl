import 'package:btl/components/text_to_speech/audio.dart';
import 'package:btl/components/text_to_speech/epub_utils.dart';
import 'package:flutter/material.dart';

class ListAudio extends StatefulWidget {
  const ListAudio({super.key});

  @override
  State<ListAudio> createState() => _ListAudioState();
}

class _ListAudioState extends State<ListAudio> {
  late Map<String, List<String>> listchappters;
  List<String> chappters = [];
  @override
  void initState() {
    super.initState();
    loadData();
  }

  void loadData() async {
    listchappters = await EpubUtils.getParagraphsByChapterFromAsset(
        'assets/epubs/bogia.epub');
    if (listchappters.isNotEmpty) {
      listchappters.forEach(
        (key, value) {
          print(key);
          setState(() {
            chappters.add(key);
          });
        },
      );
    } else {
      print('Không có dữ liệu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.green,
        title: Text(
          'Bố già Audio',
          style: TextStyle(fontSize: 30),
        ),
      ),
      body: SafeArea(
          child: ListView.builder(
        itemExtent: 80,
        itemCount: chappters.length,
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              print(index);
              Navigator.push(context, MaterialPageRoute(
                builder: (context) {
                  return Audio(
                    chapter: index,
                    title: chappters[index],
                  );
                },
              ));
            },
            child: Card(
              color: Colors.grey[300],
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      chappters[index],
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                    ),
                    Icon(
                      Icons.play_circle_outline,
                      color: Colors.grey,
                      size: 30,
                    )
                  ],
                ),
              ),
            ),
          );
        },
      )),
    );
  }
}
