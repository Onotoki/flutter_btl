import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final platform = MethodChannel('my_channel');
  bool loading = false;
  Dio dio = Dio();
  String filePath = "";

  @override
  void initState() {
    super.initState();
    requestStoragePermission();
    download();
  }

  /// Xin quyền đọc bộ nhớ trong (bao gồm quyền đặc biệt cho Android 11+)
  Future<void> requestStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      int sdkInt = androidInfo.version.sdkInt ?? 0;

      if (sdkInt >= 30) {
        if (!await Permission.manageExternalStorage.isGranted) {
          await Permission.manageExternalStorage.request();
        }
      } else {
        if (!await Permission.storage.isGranted) {
          await Permission.storage.request();
        }
      }
    }
  }

  Future<void> fetchAndroidVersion() async {
    final String? version = await getAndroidVersion();
    if (version != null) {
      String? firstPart;
      if (version.contains(".")) {
        int indexOfFirstDot = version.indexOf(".");
        firstPart = version.substring(0, indexOfFirstDot);
      } else {
        firstPart = version;
      }
      int intValue = int.parse(firstPart);
      if (intValue >= 13) {
        await startDownload();
      } else {
        final PermissionStatus status = await Permission.storage.request();
        if (status == PermissionStatus.granted) {
          await startDownload();
        } else {
          await Permission.storage.request();
        }
      }
      print("ANDROID VERSION: $intValue");
    }
  }

  Future<String?> getAndroidVersion() async {
    try {
      final String version = await platform.invokeMethod('getAndroidVersion');
      return version;
    } on PlatformException catch (e) {
      print("FAILED TO GET ANDROID VERSION: ${e.message}");
      return null;
    }
  }

  download() async {
    if (Platform.isIOS) {
      final status = await Permission.storage.request();
      if (status == PermissionStatus.granted) {
        await startDownload();
      }
    } else if (Platform.isAndroid) {
      await fetchAndroidVersion();
    }
  }

  startDownload() async {
    setState(() {
      loading = true;
    });

    Directory? appDocDir =
        Platform.isAndroid
            ? await getExternalStorageDirectory()
            : await getApplicationDocumentsDirectory();

    String path = '${appDocDir!.path}/sample.epub';
    File file = File(path);

    if (!file.existsSync()) {
      await file.create();
      await dio
          .download(
            "https://vocsyinfotech.in/envato/cc/flutter_ebook/uploads/22566_The-Racketeer---John-Grisham.epub",
            path,
            deleteOnError: true,
            onReceiveProgress: (receivedBytes, totalBytes) {
              print('Download --- ${(receivedBytes / totalBytes) * 100}');
            },
          )
          .whenComplete(() {
            setState(() {
              loading = false;
              filePath = path;
            });
          });
    } else {
      setState(() {
        loading = false;
        filePath = path;
      });
    }
  }

  openEpub(String path) {
    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: false,
    );

    VocsyEpub.locatorStream.listen((locator) {
      print('LOCATOR: $locator');
    });

    VocsyEpub.open(
      path,
      lastLocation: EpubLocator.fromJson({
        "bookId": "2239",
        "href": "/OEBPS/ch06.xhtml",
        "created": 1539934158390,
        "locations": {"cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)"},
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(title: const Text('Vocsy Plugin E-pub example')),
        body: Center(
          child:
              loading
                  ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('Downloading... E-pub'),
                    ],
                  )
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () async {
                          if (filePath == "") {
                            download();
                          } else {
                            openEpub(filePath);
                          }
                        },
                        child: Text('Open Online E-pub'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          VocsyEpub.setConfig(
                            themeColor: Theme.of(context).primaryColor,
                            scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
                            allowSharing: true,
                            enableTts: true,
                            nightMode: false,
                          );
                          VocsyEpub.locatorStream.listen((locator) {
                            print('LOCATOR: $locator');
                          });
                          await VocsyEpub.openAsset(
                            'assets/4.epub',
                            lastLocation: EpubLocator.fromJson({
                              "bookId": "2239",
                              "href": "/OEBPS/ch06.xhtml",
                              "created": 1539934158390,
                              "locations": {
                                "cfi": "epubcfi(/0!/4/4[simple_book]/2/2/6)",
                              },
                            }),
                          );
                        },
                        child: Text('Open Assets E-pub'),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final result = await FilePicker.platform.pickFiles(
                            type: FileType.custom,
                            allowedExtensions: ['epub'],
                            allowMultiple: false,
                            withData: false,
                            withReadStream: true,
                            allowCompression: false,
                          );

                          if (result != null &&
                              result.files.single.path != null) {
                            openEpub(result.files.single.path!);
                          }
                        },
                        child: Text('Open Local E-pub'),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }
}
