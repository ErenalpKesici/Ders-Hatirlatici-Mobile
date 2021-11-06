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
  TextEditingController? delayController;
  Settings(this.save);
  @override
  Widget build(BuildContext context) {
    delayController = TextEditingController(text: save?.delay);
    return Scaffold(
      drawer: getSideBar(context),
      appBar: AppBar(title: Text("Ayarlar"), centerTitle: true,),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (String value){
                save?.delay = value;
              },
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Erteleme süresi (dakika)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)), hintText: "5", labelStyle: TextStyle(fontSize: 12), contentPadding: EdgeInsets.all(10)),
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