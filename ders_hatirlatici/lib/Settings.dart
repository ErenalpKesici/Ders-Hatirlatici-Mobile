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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: getSideBar(context),
      appBar: AppBar(title: Text("Ayarlar"), centerTitle: true,),
      body: Column(
        children: [
          // CheckboxListTile(
          //   title: Text("Gece Modu"),
          //   onChanged: (bool? value) {
          //     setState(() {
          //       darkMode = value!;
          //       print(darkMode.toString());
          //     });
          //   },
          //   value: darkMode,
          // ),
        ],
      )
    );
  }
}