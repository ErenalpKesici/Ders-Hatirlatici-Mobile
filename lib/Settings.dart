import 'dart:io';
import 'dart:ui';
import 'package:ders_hatirlatici/backup.dart';
import 'package:ders_hatirlatici/main.dart';
import 'package:flutter/material.dart';
import 'dart:isolate';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:html/parser.dart';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SettingsSend extends StatefulWidget {
  final Backup? save;
  SettingsSend({@required this.save});
  @override
  State<StatefulWidget> createState() {
    return Settings(this.save);
  }
}

class Settings extends State<SettingsSend> {
  Backup? save;
  TextEditingController? delayController;
  Settings(this.save);
  @override
  Widget build(BuildContext context) {
    delayController = TextEditingController(text: save?.delay);
    return Scaffold(
        drawer: getSideBar(context),
        appBar: AppBar(
          title: Text("Ayarlar"),
          centerTitle: true,
        ),
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                onChanged: (String value) {
                  save?.delay = value;
                },
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Erteleme süresi (dakika)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    hintText: "5",
                    labelStyle: TextStyle(fontSize: 12),
                    contentPadding: EdgeInsets.all(10)),
                controller: delayController,
                textAlign: TextAlign.center,
              ),
            ),
            CheckboxListTile(
              title: Text("Listelerken tipe göre renklendir"),
              onChanged: (bool? value) {
                setState(() {
                  save!.listColored = value!;
                });
              },
              value: save!.listColored,
            ),
            CheckboxListTile(
              title: Text("Listelerken ekranı otomatik döndür"),
              onChanged: (bool? value) {
                setState(() {
                  save!.listRotate = value!;
                });
              },
              value: save!.listRotate,
            ),
            CheckboxListTile(
              title: Text("Alarmları iptal et"),
              onChanged: (bool? value) {
                setState(() {
                  save!.cancelAlarm = value!;
                  if (save!.cancelAlarm!) {
                    notifications.cancelNotifications(-1);
                  }
                  print(save!.cancelAlarm.toString());
                });
              },
              value: save!.cancelAlarm,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton.icon(
                  onPressed: () async {
                    tryUpdate(context);
                  },
                  icon: const Icon(Icons.update),
                  label: const Text("Güncelleme Denetle")),
            ),
          ],
        ));
  }
}

ReceivePort _port = ReceivePort();
void downloadCallback(
    String id, DownloadTaskStatus status, int progress) async {
  final SendPort? send =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  send?.send([id, status, progress]);
}

void tryUpdate(BuildContext context) async {
  if (await Permission.storage.request() == PermissionStatus.granted) {
    PackageInfo packageInfo = await PackageInfo.fromPlatform();
    String status = "Güncellemek ister misiniz?";
    int? statusVal;
    http.Response response = await http.get(Uri.parse(
        'https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobile/releases/tag/Attachments'));
    dom.Document document = parse(response.body);
    String url = "https://www.github.com" +
        document
            .getElementsByClassName('Box-row')[0]
            .children[0]
            .children[1]
            .attributes['href']
            .toString();
    String latestVersion = url.split('/').last.split('-')[1];
    if (packageInfo.version.compareTo(latestVersion) > -1) {
      if (context.widget.toString() == "SettingsSend")
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Program güncel.")));
    } else {
      await showDialog(
          barrierDismissible: false,
          context: context,
          builder: (context) {
            return StatefulBuilder(
              builder: (BuildContext context,
                  void Function(void Function()) setInnerState) {
                return AlertDialog(
                  title: Text(
                    "Mevcut Versiyon: " +
                        packageInfo.version +
                        " Son Versiyon: " +
                        latestVersion,
                    textAlign: TextAlign.center,
                  ),
                  content: statusVal == null
                      ? Text(
                          status,
                          textAlign: TextAlign.center,
                        )
                      : LinearProgressIndicator(
                          value: statusVal! / 100,
                        ),
                  actions: <Widget>[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton(
                            onPressed: status != "Güncellemek ister misiniz?"
                                ? null
                                : () {
                                    Navigator.pop(context);
                                  },
                            child: const Text("Hayır")),
                        const SizedBox(
                          width: 20,
                        ),
                        ElevatedButton(
                            onPressed: status != "Güncellemek ister misiniz?"
                                ? null
                                : () async {
                                    final externalDir =
                                        await getExternalStorageDirectory();
                                    List dirs =
                                        await Directory(externalDir!.path)
                                            .list()
                                            .toList();
                                    for (var dir in dirs) {
                                      String fileName =
                                          dir.path.split('/').last;
                                      if (fileName.contains('app')) {
                                        await dir.delete();
                                        break;
                                      }
                                    }
                                    IsolateNameServer.registerPortWithName(
                                        _port.sendPort, 'downloader_send_port');
                                    FlutterDownloader.registerCallback(
                                        downloadCallback);
                                    _port.listen((dynamic data) async {
                                      setInnerState(() {
                                        status = data[2].toString();
                                        statusVal = int.tryParse(status);
                                      });
                                      if (data[1] ==
                                          const DownloadTaskStatus(3)) {
                                        FlutterDownloader.open(taskId: data[0]);
                                      }
                                    });
                                    await FlutterDownloader.enqueue(
                                      url: url,
                                      showNotification: false,
                                      savedDir: externalDir.path,
                                    );
                                  },
                            child: const Text("Evet")),
                      ],
                    )
                  ],
                );
              },
            );
          });
    }
  }
}
