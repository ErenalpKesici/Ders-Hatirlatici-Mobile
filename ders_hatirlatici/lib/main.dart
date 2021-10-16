import 'dart:async';
import 'dart:io';

import 'package:ders_hatirlatici/Settings.dart';
import 'package:ders_hatirlatici/notifications.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'Single.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

String? selectedDirectory;
List<Single> s = new List<Single>.empty(growable: true);
List<String> lecturers = new List<String>.empty(growable: true);
int tillCancel = 0;
Color appColor = Colors.white;
bool darkMode = false;

int WhichMonth(String month){
  switch(month){
    case "Ocak":
      return 1;
    case "Şubat":
      return 2;
    case "Mart":
      return 3;
    case "Nisan":
      return 4;
    case "Mayıs":
      return 5;
    case "Haziran":
      return 6;
    case "Temmuz":
      return 7;
    case "Ağustos":
      return 8;
    case "Eylül":
      return 9;
    case "Ekim":
      return 10;
    case "Kasım":
      return 11;
    case "Aralık":
      return 12;
    default: 
      return 0;
  }
}

Future<void> ReadExcel() async{
  s = new List<Single>.empty(growable: true);
  lecturers = new List<String>.empty(growable: true);
  await for(var file in Directory(selectedDirectory!).list()){
    var bytes = File(file.path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    for (var table in excel.tables.keys) {
      String leadingDate = "";
      for (var row in excel.tables[table]!.rows) {
        if(row[1]?.value == null)continue;  
        var readDate = row[1]?.value;
        if(readDate.toString().length > 10){
          leadingDate = readDate;
          continue;
        }
        if(row[6]?.value == '-' || row[6]?.value == null)continue;
        List<String> date = leadingDate.split(' ');
        List<String> time = readDate.split(':');
        DateTime currentDate = new DateTime(int.parse(date[2]), WhichMonth(date[1]), int.parse(date[0]), int.parse(time[0]));
        String tmpCourse = file.path.split('/').last;//.split(' ')[0];
        String course = tmpCourse[0];
        for(int i = 1;i<tmpCourse.length;i++){
          if(int.tryParse(tmpCourse[i]) == null)
            break;
          course += tmpCourse[i];
        }
        s.add(new Single(currentDate, course, row[6]?.value.split(' - ').last, row[3]?.value, row[4]?.value));
      }
    }
  }
  s.sort((a, b) => a.date.compareTo(b.date));
  lecturers.add("HERKES");
  bool unique = true;
  for(Single single in s){
    for(String person in lecturers){
      if(single.lecturer == person){
        unique = false;
        break;
      }
    }
    if(unique)
      lecturers.add(single.lecturer);
    else
      unique = true;
  }
}
void onStart() {
  
                        print("THIS" + (tillCancel/60).toString());
  WidgetsFlutterBinding.ensureInitialized();
  final service = FlutterBackgroundService();
  service.setForegroundMode(true);
  Timer.periodic(Duration(seconds: 1), (timer) async {
    if (!(await service.isServiceRunning())) timer.cancel();
    service.setNotificationInfo(
      title: "My App Service",
      content: "Updated at ${DateTime.now()} " + tillCancel.toString(),
    );
    service.sendData(
      {"current_date": DateTime.now().toIso8601String()},
    );
  });
}
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  Directory dir = await getApplicationDocumentsDirectory();
  if(await File(dir.path+"/Default.txt").exists() && (selectedDirectory = await File(dir.path+"/Default.txt").readAsString()) != "");
  else{
    selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if(selectedDirectory == null)return;
    Directory dir = await getApplicationDocumentsDirectory();
    await File(dir.path+"/Default.txt").writeAsString(selectedDirectory!);
  }
  await ReadExcel();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(brightness: SchedulerBinding.instance!.window.platformBrightness, primarySwatch: Colors.orange,
        appBarTheme: AppBarTheme(
          foregroundColor: Colors.white,
          backgroundColor: Colors.orange)),
      home: MyHomePage(),
    );
  }
}
Widget getSideBar(BuildContext context){
  return Drawer(
        child: Container(
          child: ListView(
            children: [
              ListTile(
                leading: Icon(Icons.home),
                title: Text("Ana Sayfa", textAlign: TextAlign.center,),
                onTap: (){
                  if(context.widget.toString() != "MyHomePage")
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>MyHomePage()));
                  else
                    Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: Icon(Icons.settings),
                title: Text("Ayarlar", textAlign: TextAlign.center,),
                onTap: (){
                  if(context.widget.toString() != "SettingsSend")
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>SettingsSend()));
                  else
                    Navigator.of(context).pop();
                },
              ),
            ],
          ),
        ),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String selectedLecturer = lecturers[0];
  DateTime selectedDate1 = DateTime.now();
  DateTime selectedDate2 = DateTime.now();
  int? selectedRadio;
  TextEditingController minuteBefore = new TextEditingController(text: "10");
  Icon alarmIcon = Icon(Icons.alarm_off);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: getSideBar(context),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Ders Hatirlatici"),
        centerTitle: true,
        actions: [
          ElevatedButton.icon(onPressed: () async{
            selectedDirectory = await FilePicker.platform.getDirectoryPath();
            if(selectedDirectory == null)return;
            Directory dir = await getApplicationDocumentsDirectory();
            await File(dir.path+"/Default.txt").writeAsString(selectedDirectory!);
            ReadExcel();
          }, icon: Icon(Icons.folder), label: Text(''))
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            DropdownButton(
              items: lecturers.map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(
                    value,
                  ),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  selectedLecturer = value!;
                });
              },
              value: selectedLecturer,
            ),
            SizedBox(height: 50,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 50,
                  child: TextField(
                    controller: minuteBefore,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                    hintText: "10"),
                  ),
                ),
                SizedBox(width: 10,),
                ElevatedButton.icon(onPressed: (){
                  for(Single single in s){
                    DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day, single.date.hour);
                    DateTime nowDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour);
                    if((selectedLecturer == "HERKES" || single.lecturer == selectedLecturer) && singleDt.compareTo(nowDate) == 1){                    
                        int difference = single.date.difference(DateTime.now()).inSeconds;
                        if(difference - int.parse(minuteBefore.value.text)*60 < 0)continue;
                        MyNotifications notify = new MyNotifications();
                        tillCancel = difference - int.parse(minuteBefore.value.text)*60;
                        notify.scheduleNotify(tillCancel, single);
                        FlutterBackgroundService.initialize(onStart);
                        setState(() {
                          alarmIcon = Icon(Icons.alarm_on);
                        });
                        break;
                      }
                  }
                }, icon: alarmIcon, label: Text('Dakika Kalinca Hatirlat')),
              ],
            ),
            SizedBox(height: 25,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(onPressed: () async{
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate1,
                    firstDate: DateTime(2000),
                    lastDate: selectedDate2,
                  );
                  setState(() {
                    if(pickedDate!=null)
                      selectedDate1 = pickedDate;
                  });
                }, icon: Icon(Icons.date_range_sharp), label: Text(DateFormat('dd/MM/yyyy').format(selectedDate1)), style: ElevatedButton.styleFrom(primary: Colors.orange[200])),
                Text('     -     '),
                ElevatedButton.icon(onPressed: () async{
                  final DateTime? pickedDate = await showDatePicker(
                    context: context,
                    initialDate: selectedDate2,
                    firstDate: selectedDate1,
                    lastDate: DateTime(2025),
                  );
                  setState(() {
                    if(pickedDate!=null)
                      selectedDate2 = pickedDate;
                  });
                }, icon: Icon(Icons.date_range_sharp), label: Text(DateFormat('dd/MM/yyyy').format(selectedDate2)), style: ElevatedButton.styleFrom(primary: Colors.orange[200])),
              ],
            ),
            SizedBox(height: 5,),
            ElevatedButton.icon(onPressed: () async{
              List<Single> toSendS = new List.empty(growable: true);
              for(Single single in s){
                DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                DateTime selectedDt1 = new DateTime(selectedDate1.year, selectedDate1.month, selectedDate1.day);
                DateTime selectedDt2 = new DateTime(selectedDate2.year, selectedDate2.month, selectedDate2.day);
                if((selectedLecturer == "HERKES" || single.lecturer == selectedLecturer) && (singleDt.compareTo(selectedDt1) > -1 && singleDt.compareTo(selectedDt2) < 1))
                  toSendS.add(single);
              }
              Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: DateFormat('dd/MM/yyyy').format(selectedDate1)+" - " + DateFormat('dd/MM/yyyy').format(selectedDate2),)));
            }, icon: Icon(Icons.find_in_page), label: Text('Dersleri Listele')),
            SizedBox(height: 100,),
            Container(
              width: MediaQuery. of(context). size. width/2,
              child: Column(
                children: [
                  RadioListTile<int>(
                value: 0,
                groupValue: selectedRadio,
                onChanged: (nValue) {
                  setState(() {
                    selectedRadio = nValue;
                  });
                },
                title: Text("En Yakin"),
              ),
              RadioListTile<int>(
                value: 1,
                groupValue: selectedRadio,
                onChanged: (nValue) {
                  setState(() {
                    selectedRadio = nValue;
                  });
                },
                title: Text("Suandaki"),
              ),
                ],
              ),
            ),         
            ElevatedButton.icon(onPressed: (){
              if(selectedRadio == null)
                return;
              List<Single> toSendS = new List.empty(growable: true);
              for(Single single in s){
                DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day, single.date.hour);
                DateTime nowDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour);
                if((selectedLecturer == "HERKES" || single.lecturer == selectedLecturer) && ((selectedRadio == 1 && singleDt.compareTo(nowDate) == 0) || selectedRadio == 0 && singleDt.compareTo(nowDate)  == 1)){
                    toSendS.add(single);
                    break;}
              }
              Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: selectedRadio == 0?'En Yakin Ders':'Suandaki Ders',)));
            }, icon: Icon(Icons.find_replace_outlined), label: Text('Dersi Bul'),)
          ],
        ),
      ),
    );
  }
}
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
  String? title;
  ListPage(this.currentS, this.title);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(this.title!),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black12),
            columns: [
              DataColumn(label: Text('Tarih',)),
              DataColumn(label: Text('Sinif')),
              DataColumn(label: Text('Tip')),
              DataColumn(label: Text('Kisi')),
              DataColumn(label: Text('Konu')),
            ],
            rows: List.generate(currentS!.length, (index) => getDataRow(index))
          ),
        ),
      ),
    );
  }
  DataRow getDataRow(index) {
    return DataRow(
      color: MaterialStateColor.resolveWith((states) => currentS![index].type == "UE"?Colors.white:Colors.cyan),
      cells: <DataCell>[
        DataCell(Text(currentS![index].date.day.toString() + "/" + currentS![index].date.month.toString() + "/" + currentS![index].date.year.toString() +" " + currentS![index].date.hour.toString()+":00")),
        DataCell(Text(currentS![index].course)),
        DataCell(Text(currentS![index].type)),
        DataCell(Text(currentS![index].lecturer)),
        DataCell(Text(currentS![index].topic)),
      ],
    );
  }
}