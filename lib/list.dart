import 'dart:async';

import 'package:ders_hatirlatici/Single.dart';
import 'package:ders_hatirlatici/main.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:sensors_plus/sensors_plus.dart';

import 'Alarm.dart';

class ListPageSend extends StatefulWidget {
  final List<Single>? currentS;
  final String? title;
  ListPageSend({@required this.currentS, @required this.title});
  @override
  State<StatefulWidget> createState() {
    return ListPage(this.currentS, this.title);
  }
}
class ListPage extends State<ListPageSend> {
  List<Single>? currentS;
  List<DataRow> rows = List.empty(growable: true);
  List<DataColumn> cols = List.empty(growable: true);
  String? title;
  List<Icon>? icons;
  ListPage(this.currentS, this.title);
  StreamSubscription? accelerometer;
  bool landscape = false;
  bool left = true;
  @override
  void initState() {
    icons = List.filled(currentS!.length, Icon(Icons.alarm_add, color: Colors.lightGreenAccent));
    accelerometer = accelerometerEvents.listen((AccelerometerEvent  event) {
      setState(() {
        if(event.y < 5)landscape=true;
        else landscape = false;
        if(event.x < 0)left = true;
        else left = false;
      });
    });
    if(title == 'Hatırlatılıcak Ders Seçme')
      cols.add(DataColumn(label: ElevatedButton.icon(onPressed: (){
        showDialog<bool>(
      context: context,
      builder: (c) =>
    AlertDialog(
      title: Center(child: Text('Onayla')),
      content: Text('Tüm derslere hatırlatılmak istediğinize emin misiniz?'),
      actions: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: Text('Hayır'),
              onPressed: () => Navigator.pop(context, false),
            ),
            SizedBox(width: 10,),
            ElevatedButton(
              child: Text('Evet'),
              onPressed: () async{
                Navigator.pop(context, false);  
                for(int i=0;i<currentS!.length;i++)
                  setAlarm(i);
                setState(() {
                });
              },
            ),
          ],
        ),
      ],
    ));
      }, icon: Icon(Icons.select_all, color: Colors.white), style: ElevatedButton.styleFrom(primary: Colors.transparent, elevation: 0), label: Text('Tümü', style: TextStyle(color: Colors.white)))));
    cols.add(DataColumn(label: Text('Tarih & Saatler')));
    if(save.course == "Tüm Sınıflar")
      cols.add(DataColumn(label: Text('Sınıf')));
    if(save.type == "Tüm Tipler")
      cols.add(DataColumn(label: Text('Tip')));
    if(save.topic == "Tüm Konular")
      cols.add(DataColumn(label: Text('Konu')));
    if(save.lecturer == "Tüm Eğiticiler")
      cols.add(DataColumn(label: Text('Eğitici')));
    for(int i=0;i<currentS!.length;i++){
      if(i == 0 || DateUtils.dateOnly(currentS![i - 1].date) != DateUtils.dateOnly(currentS![i].date)){
        rows.add(DataRow(color: MaterialStateColor.resolveWith((states) => Colors.grey), cells: List.generate(cols.length, (index){
          if(index == 0){
            return DataCell(Text(DateFormat.yMMMMd('tr_TR').format(currentS![i].date)));
          }
          return DataCell(Divider());
        })));
      }
      rows.add(getDataRow(i));
    }
    super.initState();
  }
    @override
  void dispose() {
    super.dispose();
    accelerometer!.cancel();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp,DeviceOrientation.portraitDown,]);
  }
  void setAlarm(int index){
    if(currentS![index].date.compareTo(DateTime.now()) == 1){    
      int difference = currentS![index].date.difference(DateTime.now()).inSeconds;
      int multiplier = 0;
      switch(save.timeType){
        case "Dakika":
          multiplier = 60;
          break;
        case "Saat":
          multiplier = 3600;
          break;
        case "Gün":
          multiplier = 86400;
          break;
      }
      tillCancel = difference - int.parse(save.time!)*multiplier;
      if(tillCancel < 1)
        ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Ders seçilen süreden önce başlıyacak, daha erken süre seçin.', textAlign: TextAlign.center)));
      else{
        ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Derse ' + (tillCancel/60).ceil().toString() +  ' dakika içinde hatırlatılıcaksınız.', textAlign: TextAlign.center)));
        setState(() {
          icons?[index] = Icon(Icons.alarm_on, color: Colors.lightGreenAccent);
        });
        int tillMin = (tillCancel/60).round();
        Single tmpSingle = Single(DateTime.now().add(Duration(minutes: tillMin)), currentS![index].course, currentS![index].lecturer, currentS![index].topic, currentS![index].type);
        Alarm alarm = Alarm(alarms.length, tmpSingle);
        notifications.scheduleNotify(tillCancel, alarm.id, tmpSingle, currentS![index]);
        updateAlarms(alarm);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    if(save.listRotate == true){
      if(!landscape){  
        SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp,DeviceOrientation.portraitDown,]);
      }
      else{
        SystemChrome.setPreferredOrientations([left==true?DeviceOrientation.landscapeRight:DeviceOrientation.landscapeLeft]);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(child: Text(this.title!)),
        centerTitle: true,
      ),
      body: Container(
        width: MediaQuery.of(context).size.width,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              decoration: BoxDecoration(),
              columnSpacing: 10,
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black12),
              columns: cols,
              rows: rows,
            ),
          ),
        ),
      ),
    );
  }
  DataRow getDataRow(index) {
    return DataRow(
      color: !save.listColored!?MaterialStateColor.resolveWith((states) => Colors.transparent):MaterialStateColor.resolveWith((states) => currentS![index].type == "UE"?Colors.orange[700]!:Colors.lightBlue[700]!),
      cells: <DataCell>[
        if(title == 'Hatırlatılıcak Ders Seçme')
          DataCell(ElevatedButton.icon(onPressed: (){
            if(icons?[index].icon == Icons.alarm_on){
              ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Hatırlatıcıları yan menüden Hatırlatıcılar Listesine girerek iptal edebilirsiniz.', textAlign: TextAlign.center)));
            }
            else
              setAlarm(index);
          }, style: ElevatedButton.styleFrom(primary: Colors.transparent, elevation: 0), icon: currentS![index].date.compareTo(DateTime.now()) != 1?Icon(Icons.alarm_add, color: Colors.grey,):icons![index], label: Text('')) ),
        DataCell(Text(currentS![index].date.hour.toString()+":00")),
        if(save.course == "Tüm Sınıflar")
          DataCell(Text(currentS![index].course)),
        if(save.type == "Tüm Tipler")
          DataCell(Text(currentS![index].type)),
        if(save.topic == "Tüm Konular")
          DataCell(Text(currentS![index].topic)),
        if(save.lecturer == "Tüm Eğiticiler")
          DataCell(Text(currentS![index].lecturer)),
      ],
    );
  }
}