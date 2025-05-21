import 'dart:io';
import 'package:btl/components/text_to_speech/epub_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';

class Audio extends StatefulWidget {
  int chapter;
  String title;
  Audio({required this.chapter, required this.title, super.key});

  @override
  State<Audio> createState() => _AudioState();
}

enum ReadState { botton, audio }

class _AudioState extends State<Audio> {
  bool showBottom = true;
  bool showAudio = false;
  bool showSettings = false;
  double speed = 0;
  String content = '';
  int currentP = -1;
  bool isPlaying = true;
  String? language = 'vi-VN';
  double volume = 0.5;
  double pitch = 1.0;
  double rate = 0.5;
  late int currentChapter;
  bool get isAndroid => !kIsWeb && Platform.isAndroid;

  bool isCurrentLanguageInstalled = false;

  late GlobalObjectKey keyScoll;
  late List<String> paragraphs;
  FlutterTts tts = FlutterTts();
  ReadState state = ReadState.botton;
  ScrollController controller = ScrollController();
  late Map<String, List<String>> listchappters;

  void speak(int index) async {
    await tts.stop();
    await tts.setSpeechRate(rate);
    await tts.setPitch(pitch);
    setState(() {
      currentP = index;
    });
    await tts.speak(paragraphs[currentP]);
    setState(() {
      keyScoll = GlobalObjectKey(currentP);
    });
    scollFunction();
  }

  void loadData(int index) async {
    print('Chương hien tai ${index}');
    listchappters = await EpubUtils.getParagraphsByChapterFromAsset(
        'assets/epubs/bogia.epub');
    if (listchappters.isNotEmpty) {
      print('object');
      final entry = listchappters.entries.elementAt(index);
      setState(() {
        paragraphs = entry.value;
        currentP = -1;
        isPlaying = true;
      });
      print(entry.key);
    } else {
      print('Không có dữ liệu');
    }
  }

  void pause() async {
    await tts.pause();
  }

  void stopAudio() async {
    await tts.stop();
  }

  void _initTts() async {
    await tts.setLanguage('vi-VN');
    await tts.setSpeechRate(rate);
    await tts.setPitch(pitch);

    tts.setCompletionHandler(() {
      final next = currentP + 1;
      if (next < paragraphs.length) {
        speak(next);
      } else {
        setState(() {
          currentP = -1;
          isPlaying = true;
        });
      }
    });
  }

  void scollFunction() {
    final ctx = keyScoll.currentState?.context;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          alignment: 0.3, duration: Duration(microseconds: 200));
    }
  }

  @override
  void initState() {
    super.initState();
    currentChapter = widget.chapter;
    loadData(currentChapter);
    paragraphs = content
        .trim()
        .split(RegExp(r'\r?\n\s*\r?\n'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();
    _initTts();
  }

  @override
  void dispose() {
    controller.dispose();
    tts.stop();
    super.dispose();
  }

// Trả về danh sách dropdownmenu với chuỗi ngôn ngữ đầu vào
  List<DropdownMenuItem<String>> getLanguageDropDownMenuItems(
      List<dynamic> languages) {
    var items = <DropdownMenuItem<String>>[];
    for (dynamic type in languages) {
      items.add(DropdownMenuItem(
          value: type as String?, child: Text((type as String))));
    }
    return items;
  }

// lưu ngôn ngữ được chọn
  void changedLanguageDropDownItem(String? selectedType) {
    setState(() {
      language = selectedType;
      tts.setLanguage(language!);
      if (isAndroid) {
        tts
            .isLanguageInstalled(language!)
            .then((value) => isCurrentLanguageInstalled = (value as bool));
      }
    });
  }

  Future<dynamic> _getLanguages() async => await tts.getLanguages;
  Widget _futureBuilder() => FutureBuilder<dynamic>(
      future: _getLanguages(),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        if (snapshot.hasData) {
          return _languageDropDownSection(snapshot.data as List<dynamic>);
        } else if (snapshot.hasError) {
          return Text('Error loading languages...');
        } else
          return Text('Loading Languages...');
      });

  Widget _languageDropDownSection(List<dynamic> languages) => Container(
      padding: EdgeInsets.only(top: 10.0),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        DropdownButton(
          borderRadius: BorderRadius.circular(10),
          menuMaxHeight: 300,
          menuWidth: 100,
          value: language,
          items: getLanguageDropDownMenuItems(languages),
          onChanged: changedLanguageDropDownItem,
        ),
      ]));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bố già'),
        actions: [
          IconButton(
              onPressed: () {
                setState(() {
                  tts.pause();
                  showSettings = !showSettings;
                  isPlaying = true;
                });
              },
              icon: Icon(Icons.more_vert))
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
                padding:
                    const EdgeInsets.only(bottom: 8.0, left: 18, right: 18),
                child: SingleChildScrollView(
                  controller: controller,
                  child: Column(
                      children: List.generate(
                    paragraphs.length,
                    (index) {
                      return StatefulBuilder(
                        key: GlobalObjectKey(index),
                        builder: (context, setState) => Text(
                          paragraphs[index],
                          textAlign: TextAlign.justify,
                          style: TextStyle(
                            backgroundColor:
                                currentP == index ? Colors.grey[300] : null,
                            // fontSize: currentP == index ? 20 : 18,
                            fontSize: 18,
                            fontWeight:
                                currentP == index ? FontWeight.bold : null,
                          ),
                        ),
                      );
                    },
                  )),
                )),
          ),

          Positioned(child: GestureDetector(
            onTap: () {
              if (showSettings) {
                setState(() {
                  // tts.pause();
                  showSettings = false;
                });
              }
            },
          )),

          // audio
          Positioned(
            bottom: 35,
            left: 45,
            right: 45,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.grey,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Row(
                  spacing: 10,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                        onTap: () {
                          if (!isPlaying) {
                            tts.stop();
                          }
                          setState(() {
                            --currentChapter;
                          });
                          scollFunction();
                          loadData(currentChapter);
                        },
                        child: buildIconButton(Icons.skip_previous)),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            currentP = --currentP;
                            if (isPlaying) {
                              isPlaying = !isPlaying;
                            }
                          });
                          speak(currentP);
                        },
                        child: buildIconButton(Icons.fast_rewind)),
                    isPlaying
                        ? GestureDetector(
                            onTap: () {
                              if (currentP <= -1) {
                                speak(0);
                              } else {
                                speak(currentP);
                              }
                              setState(() {
                                isPlaying = false;
                              });
                            },
                            child: buildIconButton(
                              Icons.play_arrow,
                              iconSize: 40,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              pause();
                              setState(() {
                                isPlaying = true;
                              });
                            },
                            child: buildIconButton(
                              Icons.pause,
                              iconSize: 40,
                            ),
                          ),
                    GestureDetector(
                        onTap: () {
                          setState(() {
                            currentP = ++currentP;
                            if (isPlaying) {
                              isPlaying = !isPlaying;
                            }
                          });
                          speak(currentP);
                        },
                        child: buildIconButton(Icons.fast_forward)),
                    GestureDetector(
                        onTap: () {
                          if (!isPlaying) {
                            tts.stop();
                          }
                          setState(() {
                            ++currentChapter;
                          });
                          loadData(currentChapter);
                          scollFunction();
                        },
                        child: buildIconButton(Icons.skip_next)),
                  ],
                ),
              ),
            ),
          ),

          // speed settings
          AnimatedPositioned(
            duration: Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            bottom: showSettings ? 35 : -350,
            left: 20,
            right: 20,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 20),
              // height: 150,
              decoration: BoxDecoration(
                  color: Colors.grey[500],
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                spacing: 5,
                children: [
                  Text(
                    'Text to speech',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Ngôn ngữ',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(child: _futureBuilder())
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tốc độ',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(rate.toString()),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                    ),
                    child: Slider(
                      value: rate,
                      onChanged: (newRate) {
                        setState(() => rate = newRate);
                      },
                      min: 0.0,
                      max: 1.0,
                      divisions: 10,
                      label: "Rate: ${rate.toStringAsFixed(1)}",
                      activeColor: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Độ cao',
                        style: TextStyle(fontSize: 18),
                      ),
                      Text(pitch.toString()),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 2,
                      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                      overlayShape: RoundSliderOverlayShape(overlayRadius: 0),
                    ),
                    child: Slider(
                      value: pitch,
                      onChanged: (newPitch) {
                        setState(() => pitch = newPitch);
                      },
                      min: 0.5,
                      max: 2.0,
                      divisions: 15,
                      label: "Pitch: ${pitch.toStringAsFixed(1)}",
                      activeColor: Colors.black,
                    ),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                minimumSize: Size.fromHeight(50),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14))),
                            onPressed: () async {
                              await tts.setSpeechRate(rate);
                              await tts.setPitch(pitch);
                              await tts.speak(paragraphs[currentP]);
                              setState(() {
                                isPlaying = false;
                              });
                            },
                            child: Text(
                              'Nghe thử',
                              style:
                                  TextStyle(color: Colors.black, fontSize: 18),
                            )),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget buildIconButton(IconData icon,
    {VoidCallback? ontap, double iconSize = 25}) {
  return Container(
    padding: const EdgeInsets.all(7),
    decoration: const BoxDecoration(
      shape: BoxShape.circle,
      color: Color.fromARGB(255, 67, 67, 67),
    ),
    child: Center(
      child: Icon(
        icon,
        size: iconSize,
        color: Colors.white,
      ),
    ),
  );
}
