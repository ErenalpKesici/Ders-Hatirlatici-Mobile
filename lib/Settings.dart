import 'package:ders_hatirlatici/main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class SettingsSend extends StatefulWidget {
  SettingsSend();
  @override
  State<StatefulWidget> createState() {
    return Settings();
  }
}
class Settings extends State<SettingsSend> {
  Settings();
  bool cbCancelAlarm = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: getSideBar(context),
      appBar: AppBar(title: Text("Ayarlar"), centerTitle: true,),
      body: Column(
        children: [
          CheckboxListTile(
            title: Text("Alarmı iptal et"),
            onChanged: (bool? value) {
              setState(() {
                cbCancelAlarm = value!;
                if(cbCancelAlarm){
                  notifications.cancelNotifications();
                }
                print(cbCancelAlarm.toString());
              });
            },
            value: cbCancelAlarm,
          ),
        ],
      )
    );
  }
}