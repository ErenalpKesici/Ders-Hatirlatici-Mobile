import 'package:ders_hatirlatici/backup.dart';
import 'package:ders_hatirlatici/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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
  Settings(this.save);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: getSideBar(context),
      appBar: AppBar(title: Text("Ayarlar"), centerTitle: true,),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
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
            title: Text("Alarmları iptal et"),
            onChanged: (bool? value) {
              setState(() {
                save!.cancelAlarm = value!;
                if(save!.cancelAlarm!){
                  notifications.cancelNotifications(-1);
                }
                print(save!.cancelAlarm.toString());
              });
            },
            value: save!.cancelAlarm,
          ),
        ],
      )
    );
  }
}