import 'dart:io';
import 'package:file_manager/file_manager.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vocsy_epub_viewer/epub_viewer.dart';

class FileExplorerPage extends StatefulWidget {
  @override
  _FileExplorerPageState createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  final FileManagerController controller = FileManagerController();

  @override
  void initState() {
    super.initState();
    requestPermission();
  }

  Future<void> requestPermission() async {
    if (Platform.isAndroid) {
      var status = await Permission.manageExternalStorage.status;
      if (!status.isGranted) {
        await Permission.manageExternalStorage.request();
      }
    } else {
      await Permission.storage.request();
    }
  }

  void openEpub(String path) {
    VocsyEpub.setConfig(
      themeColor: Theme.of(context).primaryColor,
      scrollDirection: EpubScrollDirection.ALLDIRECTIONS,
      allowSharing: true,
      enableTts: true,
      nightMode: false,
    );
    VocsyEpub.open(path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chọn file EPUB'),
        actions: [
          IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              controller.setCurrentPath(
                Directory(controller.getCurrentPath).parent.path,
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.home),
            onPressed: () {
              controller.setCurrentPath("/storage/emulated/0");
            },
          ),
        ],
      ),
      body: FileManager(
        controller: controller,
        builder: (context, snapshot) {
          final List<FileSystemEntity> entities = snapshot;
          return ListView.builder(
            itemCount: entities.length,
            itemBuilder: (context, index) {
              FileSystemEntity entity = entities[index];
              String name = entity.path.split('/').last;
              return ListTile(
                leading:
                    FileManager.isFile(entity)
                        ? Icon(Icons.insert_drive_file)
                        : Icon(Icons.folder),
                title: Text(name),
                onTap: () {
                  if (FileManager.isDirectory(entity)) {
                    controller.openDirectory(entity);
                  } else if (name.toLowerCase().endsWith('.epub')) {
                    openEpub(entity.path);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Không phải file EPUB!')),
                    );
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
