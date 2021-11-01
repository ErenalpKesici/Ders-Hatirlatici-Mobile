import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:ders_hatirlatici/Settings.dart';
import 'package:ders_hatirlatici/backup.dart';
import 'package:ders_hatirlatici/notifications.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'Alarm.dart';
import 'Single.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;
//test
const String XL_URL = "https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobil/releases/download/Attachments/xl.zip";
const String UPDATE_URL = "https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobil/releases/download/Attachments/Update.txt";
String? selectedDirectory;
List<Single> s = new List<Single>.empty(growable: true);
List<Alarm> alarms = new List<Alarm>.empty(growable: true);
int tillCancel = 0;
bool upToDate = false;
Backup save = new Backup.initial();
MyNotifications notifications = new MyNotifications();

int whichMonth(String month){
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
Future<void> readExcel() async{
  s = new List<Single>.empty(growable: true);
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
        DateTime currentDate = new DateTime(int.parse(date[2]), whichMonth(date[1]), int.parse(date[0]), int.parse(time[0]));
        String tmpCourse = file.path.split('/').last;
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
  runApp(MyApp());
}
String displayDate(DateTime date){
  String minute = date.minute < 10?"0"+date.minute.toString():date.minute.toString();
  return date.year.toString() +"-"+date.month.toString() +"-"+date.day.toString() +" "+date.hour.toString() +":"+ minute;
}
List<String> individualize(String type){
  if(type == "lecturers"){
    List<String> lecturers = new List<String>.empty(growable: true);
    lecturers.add("Tüm Eğiticiler");
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
    return lecturers;
  }
  if(type == "courses"){
    List<String> courses = new List<String>.empty(growable: true);
    courses.add("Tüm Sınıflar");
    bool unique = true;
    for(Single single in s){
      for(String course in courses){
        if(single.course == course){
          unique = false;
          break;
        }
      }
      if(unique)
        courses.add(single.course);
      else
        unique = true;
    }
    return courses;
  }
  if(type == "topics"){
    List<String> topics = new List<String>.empty(growable: true);
    topics.add("Tüm Konular");
    bool unique = true;
    for(Single single in s){
      for(String topic in topics){
        if(single.topic == topic){
          unique = false;
          break;
        }
      }
      if(unique)
        topics.add(single.topic);
      else
        unique = true;
    }
    return topics;
  }
  if(type == "types"){
    List<String> types = new List<String>.empty(growable: true);
    types.add("Tüm Tipler");
    bool unique = true;
    for(Single single in s){
      for(String type in types){
        if(single.type == type){
          unique = false;
          break;
        }
      }
      if(unique)
        types.add(single.type);
      else
        unique = true;
    }
    return types;
  }
  return List.empty();
}
Future<bool> internetConnectivity() async {
  try {
    final result = await InternetAddress.lookup('google.com');
    if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
      return true;
    }
  } on SocketException catch (_) {
    return false;
  }
  return false;
}
ReceivePort _port = ReceivePort();
void downloadCallback(String id, DownloadTaskStatus status, int progress) async{
  final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
  send!.send([id, status, progress]);
}
void download() async{
  FlutterDownloader.registerCallback(downloadCallback);
  IsolateNameServer.registerPortWithName(_port.sendPort, 'downloader_send_port');
  _port.listen((dynamic data) async{
    String id = data[0];
    DownloadTaskStatus status = data[1];
    int progress = data[2];
    if(status.value == 3 && progress == 100){
      final externalDir = await getExternalStorageDirectory();
      if(await File(externalDir!.path+"/xl.zip").exists()){
      try {
        await ZipFile.extractToDirectory(zipFile: File(externalDir.path+"/xl.zip"), destinationDir: Directory(externalDir.path +"/xl"));
        print(status.value); 
        await readExcel();
        IsolateNameServer.removePortNameMapping('downloader_send_port');
      } catch (e) {
        print(e);
        }
      }
    }
  });   
  final externalDir = await getExternalStorageDirectory();
  await FlutterDownloader.enqueue(
    url: XL_URL,
    showNotification: false,
    savedDir: externalDir!.path,
  );
}

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  if(await Permission.storage.request().isGranted){
    final externalDir = await getExternalStorageDirectory();
    selectedDirectory = externalDir!.path +"/xl";
    if(await File(externalDir.path+"/Save.json").exists()){ //read from save.json
      Map<String, dynamic> readSave = Map<String, dynamic>.from(jsonDecode(File(externalDir.path+"/Save.json").readAsStringSync()));
      readSave.forEach((key, value) {
        save.placeValue(key, value);
      });
      print(save.toString());
      List<String> alarmsRead = save.alarms!.split('*');
      alarmsRead.removeLast();
      for(String alarm in alarmsRead){
        int id = int.parse(alarm.split('~')[0]);
        alarm = alarm.split('~')[1];
        List<String> currAlarm = alarm.split('& ');
        String date = currAlarm[4].split(' - ')[0];
        String time = currAlarm[4].split(' ')[1];
        Single tmpS = Single(DateTime(int.parse(date.split('-')[0]), int.parse(date.split('-')[1]), int.parse(date.split('-')[2].split(' ')[0]), int.parse(time.split(':')[0]), int.parse(time.split(':')[1])), currAlarm[0], currAlarm[1], currAlarm[2], currAlarm[3]);
        int till = tmpS.date.difference(DateTime.now()).inSeconds;
        print(till);
        if(till > -1){
          notifications.scheduleNotify(till, id, tmpS, tmpS);
          save.alarms = save.alarms! + id.toString()+"~"+tmpS.toSave()+"*";
        }
        alarms.add(Alarm(alarms.length, tmpS));
      }
      alarms.sort((a, b) => a.single.date.compareTo(b.single.date)); 
    }
    Timer.periodic(Duration(seconds: 2), (timer) async{ 
      if (await InternetConnectionChecker().hasConnection){  
        if(await File(externalDir.path +"/xl.zip").exists()){
          http.Response r = await http.head(Uri.parse(XL_URL));
          var size = r.headers["content-length"];
          var curSize = await File(externalDir.path+"/xl.zip").length();
          print(size.toString() + " " + curSize.toString());
          if(size.toString() != curSize.toString()){
            await File(externalDir.path+"/xl.zip").delete();
            await Directory(externalDir.path+"/xl").delete(recursive: true);
          }
          else
            upToDate = true;   
        }        
        if(!upToDate)
          download();
        else
          await readExcel();
        timer.cancel();
      }
      else if(await File(externalDir.path +"/xl.zip").exists()){ 
        timer.cancel();
        await readExcel();
      }
      else{
        runApp(MaterialApp(debugShowCheckedModeBanner: false, home: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("Internet Aranıyor...", style: TextStyle(color: Colors.orange, decoration:  TextDecoration.none, fontSize: 24),), SizedBox(height: 25), CircularProgressIndicator(color: Colors.orange,)]))));
      }
    }); 
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: SchedulerBinding.instance!.window.platformBrightness,
        primarySwatch: Colors.orange,
        toggleableActiveColor: Colors.orange,
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
          DrawerHeader(
            child: Image(
              image: AssetImage('assets/logo.png'),
              fit: BoxFit.fitHeight,
            )
          ),
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
            leading: Icon(Icons.alarm_sharp),
            title: Text("Hatırlatıcılar Listesi", textAlign: TextAlign.center,),
            onTap: (){
              print(save.toString());
              if(context.widget.toString() != "ListAlarmsSend")
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListAlarmsSend()));
              else
                Navigator.of(context).pop();
            },
          ),
          ListTile(
            leading: Icon(Icons.settings),
            title: Text("Ayarlar", textAlign: TextAlign.center,),
            onTap: (){
              print(save.toString());
              if(context.widget.toString() != "SettingsSend")
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>SettingsSend(save: save)));
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
Future<List<String>> readCourses() async{
  List<String> courses = List.empty(growable: true);
  courses.add("Tüm Sınıflar");
  await for(var file in Directory(selectedDirectory!).list()){
    String tmpCourse = file.path.split('/').last;
    String course = tmpCourse[0];
    for(int i = 1;i<tmpCourse.length;i++){
      if(int.tryParse(tmpCourse[i]) == null)
        break;
      course += tmpCourse[i];
    }
    courses.add(course);
  }
  return courses;
}

void saveSelections(Backup save)async{
  final externalDir = await getExternalStorageDirectory();
  if(!await File(externalDir!.path + "/Save.json").exists())
    await File(externalDir.path + "/Save.json").create();
  File(externalDir.path + "/Save.json").writeAsString(jsonEncode(save));
}
void updateAlarms(Alarm alarm){
  alarms.add(alarm);
  alarms.sort((a, b) => a.single.date.compareTo(b.single.date)); 
  save.alarms = save.alarms! + alarm.id.toString()+"~"+alarm.single.toSave()+"*";
  saveSelections(save);
}

class _MyHomePageState extends State<MyHomePage> with WidgetsBindingObserver {
  DateTime selectedDate1 = DateTime.now();
  DateTime selectedDate2 = DateTime.now();
  bool dt2Checked = true, remindClosest = false, remindDate = false;
  int? selectedRadio = 0;
  TextEditingController timeBefore = new TextEditingController(text: save.time);
  Icon alarmIcon = Icon(Icons.alarm_off);
  Future<List<Single>>? loadLecturers, loadCourses, loadTopics;
  GestureDetector? gdDate1, gdDate2;
  List<String> uniqueLecturers = List.empty(growable: true), uniqueCourses = List.empty(growable: true), uniqueTopics = List.empty(growable: true), uniqueTypes = List.empty(growable: true);
  bool lastDate = false;
  void download() async{
    final externalDir = await getExternalStorageDirectory();
    print(externalDir);
    await FlutterDownloader.enqueue(
      url: XL_URL,
      showNotification: false,
      savedDir: externalDir!.path,
    );
  }
  @override
  void initState(){
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    uniqueLecturers = individualize("lecturers");
    uniqueCourses = individualize("courses");
    uniqueTopics = individualize("topics");
    uniqueTypes = individualize("types");
  }
  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    super.dispose();
  }
  bool validSingle(Single single){
    return (save.lecturer == "Tüm Eğiticiler" || single.lecturer == save.lecturer) && (save.course == "Tüm Sınıflar" || save.course == single.course) && (save.topic == "Tüm Konular" || save.topic == single.topic) && (save.type == "Tüm Tipler" || save.type == single.type);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state)  async{
    if(state == AppLifecycleState.paused)
      saveSelections(save);
  }
  @override
  Widget build(BuildContext context) {
    gdDate1 = GestureDetector(
      onTap: () async{
        if(lastDate){
          final DateTime? pickedDate = await showDatePicker(
            helpText: "Başlangıç Tarihini Seçin:",
            context: context,
            initialDate: selectedDate1,
            firstDate: DateTime(2000),
            lastDate: selectedDate2,
          );
          setState((){
            if(pickedDate!=null){
              selectedDate1 = pickedDate;
              gdDate2!.onTap!();
            }
          });
        }
      },
      child: ElevatedButton.icon(onPressed: () async{
        final DateTime? pickedDate = await showDatePicker(
          helpText: "Başlangıç Tarihini Seçin:",
          context: context,
          initialDate: selectedDate1,
          firstDate: DateTime(2000),
          lastDate: selectedDate2,
        );
        setState((){
          if(pickedDate!=null){
            selectedDate1 = pickedDate;
            lastDate = false;
            gdDate2!.onTap!();
          }
        });
      }, icon: Icon(Icons.date_range_sharp), label: Text(DateFormat('dd/MM/yyyy').format(selectedDate1)), style: ElevatedButton.styleFrom(primary: Colors.orange[200])),
    );
    gdDate2 = GestureDetector(
      onTap: () async{
        if(!lastDate){
          if(dt2Checked){
            final DateTime? pickedDate = await showDatePicker(
              helpText: "Bitiş Tarihini Seçin:",
              context: context,
              initialDate: selectedDate2,
              firstDate: selectedDate1,
              lastDate: DateTime(2025),
            );
            setState(() {
              if(pickedDate!=null)
                selectedDate2 = pickedDate;
                gdDate1!.onTap!();
            });
          }
        }
      },
      child: ElevatedButton.icon(onPressed: () async{
        if(dt2Checked){
          final DateTime? pickedDate = await showDatePicker(
            helpText: "Bitiş Tarihini Seçin:",
            context: context,
            initialDate: selectedDate2,
            firstDate: selectedDate1,
            lastDate: DateTime(2025),
          );
          setState(() {
            if(pickedDate!=null){
              selectedDate2 = pickedDate;
              lastDate = true;
              gdDate1!.onTap!();
            }
          });
        }
      }, icon: Icon(Icons.date_range_sharp), label: Text(DateFormat('dd/MM/yyyy').format(selectedDate2)), style: ElevatedButton.styleFrom(primary: dt2Checked?Colors.orange[200]:Colors.grey)));
    return Scaffold(
      drawer: getSideBar(context),
      //resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Ders Hatırlatıcı"),
        centerTitle: true,
        actions: [
          ElevatedButton.icon(onPressed: (){
            setState(() {
              save = new Backup.initial();
            });
          }, icon: Icon(Icons.restore), label: Text("Geri Al"), )
        ],
      ),
      body: Scrollbar(
        interactive: true,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DropdownButton<String>(
                alignment: AlignmentDirectional.center,
                value: save.lecturer,
                onChanged: (String? newValue) {
                  setState(() {
                    save.lecturer = newValue!;
                  });
                },
                icon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.person),
                ),
                items: uniqueLecturers.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    alignment: AlignmentDirectional.center,
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
              DropdownButton<String>(
                alignment: AlignmentDirectional.center,
                value: save.course,
                onChanged: (String? newValue) {
                  setState(() {
                    save.course = newValue!;
                  });
                },
                icon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.cast_for_education_rounded),
                ),
                items: uniqueCourses.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    alignment: AlignmentDirectional.center,
                    value: value,
                    child: Text(value),
                );
                }).toList(),
              ),
              DropdownButton<String>(
                alignment: AlignmentDirectional.center,
                value: save.type,
                onChanged: (String? newValue) {
                  setState(() {
                    save.type = newValue!;
                  });
                },
                icon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.live_tv_rounded),
                ),
                items: uniqueTypes.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    alignment: AlignmentDirectional.center,
                    value: value,
                    child: Text(value),
                );
                }).toList(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                child: DropdownButton<String>(
                  alignment: AlignmentDirectional.center,
                  isExpanded: true,
                  value: save.topic,
                  onChanged: (String? newValue) {
                    setState(() {
                      save.topic = newValue!;
                    });
                  },
                  icon: Icon(Icons.topic_rounded),
                  items: uniqueTopics.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      alignment: AlignmentDirectional.center,
                      value: value,
                      child: Text(value, overflow: TextOverflow.ellipsis,) ,
                    );
                  }).toList(),
                ),
              ),
              Divider(thickness: 2,),
              DefaultTabController(
                length: 3,
                child: SizedBox(
                height: 400,
                child: Column(
                children: [
                  TabBar(
                    indicatorColor: Colors.orange,
                    tabs: [
                      Tab(icon: Icon(Icons.list_sharp), text: "Listele"),
                      Tab(icon: Icon(Icons.find_in_page_sharp), text: "Bul"),
                      Tab(icon: Icon(Icons.alarm), text: "Hatırlat"),
                    ],
                  ),
                  Expanded(
                    child: Center(
                      child: TabBarView(
                        children: [
                          SingleChildScrollView(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.fromLTRB(64, 0, 64, 0),
                                  title: Text("Aralıklı tarih seçme"),
                                  onChanged: (bool? value) {
                                    setState(() {
                                      dt2Checked = value!;
                                    });
                                  },
                                  value: dt2Checked,
                                ),
                                SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    gdDate1!,
                                    Text('     -     '),
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        gdDate2!
                                      ],
                                    )     
                                  ],
                                ),
                              Padding(
                                padding: const EdgeInsets.all(32.0),
                                child: ElevatedButton.icon(onPressed: () async{
                                  List<Single> toSendS = new List.empty(growable: true);
                                  if(dt2Checked)
                                    for(Single single in s){
                                      DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                                      DateTime selectedDt1 = new DateTime(selectedDate1.year, selectedDate1.month, selectedDate1.day);
                                      DateTime selectedDt2 = new DateTime(selectedDate2.year, selectedDate2.month, selectedDate2.day);
                                      if(validSingle(single) && (singleDt.compareTo(selectedDt1) > -1 && singleDt.compareTo(selectedDt2) < 1))
                                        toSendS.add(single);
                                    }
                                  else{
                                    for(Single single in s){
                                      DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                                      DateTime selectedDt = new DateTime(selectedDate1.year, selectedDate1.month, selectedDate1.day);
                                      if(validSingle(single) && (singleDt.compareTo(selectedDt) == 0))
                                       toSendS.add(single);
                                      }
                                  }
                                  if(toSendS.length > 0){
                                    String lecturer = "", course = "", topic = "", type = "";
                                    if(save.lecturer != "Tüm Eğiticiler") 
                                      lecturer = ", " + save.lecturer!;
                                    if(save.course != "Tüm Sınıflar") 
                                      course = ", " + save.course!;
                                    if(save.topic != "Tüm Konular") 
                                      topic = ", " + save.topic!.substring(0, 15) + (save.topic!.length > 15?"...":"");
                                    if(save.type != "Tüm Tipler")
                                      type = ", " + save.type!;
                                    String toSendTitle = DateFormat('dd/MM/yyyy').format(selectedDate1) + " - " + DateFormat('dd/MM/yyyy').format(selectedDate2) + lecturer + course + topic + type;
                                    Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: toSendTitle,)));
                                  }
                                  else
                                    ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Ders Bulunamadı', textAlign: TextAlign.center)));
                                  }, icon: Icon(Icons.list_rounded), label: Text('Dersleri Listele')),
                              ),
                            ],
                              ),
                          ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                        title: Text("En Yakındaki"),
                    ),
                    RadioListTile<int>(
                        value: 1,
                        groupValue: selectedRadio,
                        onChanged: (nValue) {
                          setState(() {
                            selectedRadio = nValue;
                          });
                        },
                        title: Text("Şuandaki"),
                    ),
                        ],
                    ),
                  ),   
                  SizedBox(height: 20,),        
                  ElevatedButton.icon(onPressed: (){
                    if(selectedRadio == null)
                        return;
                    List<Single> toSendS = new List.empty(growable: true);
                    for(Single single in s){
                        DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day, single.date.hour);
                        DateTime nowDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour);
                        if(validSingle(single) && ((selectedRadio == 1 && singleDt.compareTo(nowDate) == 0) || selectedRadio == 0 && singleDt.compareTo(nowDate)  == 1)){
                            toSendS.add(single);
                            break;}
                    }
                    if(toSendS.length > 0)
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: selectedRadio == 0?'En Yakındaki Ders':'Şuandaki Ders',)));
                    else
                        ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Ders Bulunamadı', textAlign: TextAlign.center)));
                  }, icon: Icon(Icons.find_in_page_rounded), label: Text('Dersi Bul'),),
                ],
              ),
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 50,
                        height: 40,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: "10", labelStyle: TextStyle(fontSize: 12), contentPadding: EdgeInsets.all(10)),
                          controller: timeBefore,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(width: 10,),
                      DropdownButton<String>(
                        alignment: AlignmentDirectional.center,
                        value: save.timeType,
                        onChanged: (String? newValue) {
                          setState(() {
                            save.timeType = newValue!;
                          });
                            saveSelections(save);
                        },
                        items: <String>['Dakika', 'Saat', 'Gün'].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            alignment: AlignmentDirectional.center,
                            value: value,
                            child: Text(value),
                            onTap: (){
                              saveSelections(save);
                            },
                          );
                        }).toList(),
                      ),
                      SizedBox(width: 10,),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text("Kalınca", style: TextStyle(fontSize: 18)),
                  ),
                  ElevatedButton.icon(
                    label: Text("En Yakın Dersi Hatırlat"),
                    icon: Icon(Icons.timelapse),
                    onPressed: () {
                      bool foundSingle = false;
                      for(Single single in s){
                        DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day, single.date.hour);
                        DateTime nowDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour);
                        if(validSingle(single) && singleDt.compareTo(nowDate) == 1){                    
                          int difference = single.date.difference(DateTime.now()).inSeconds;
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
                          print(difference.toString() +" " + (int.parse(timeBefore.value.text)*multiplier).toString());
                          if(difference - int.parse(timeBefore.value.text)*multiplier < 0)
                            continue;
                          tillCancel = difference - int.parse(timeBefore.value.text)*multiplier;
                          FocusScope.of(context).unfocus();
                          ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('En yakın derse ' + (tillCancel/60).ceil().toString() +  ' dakika içinde hatırlatılıcaksınız.', textAlign: TextAlign.center)));
                          int tillMin = (tillCancel/60).round();
                          Single tmpSingle = Single(DateTime.now().add(Duration(minutes: tillMin)), single.course, single.lecturer, single.topic, single.type);
                          Alarm alarm = Alarm(alarms.length, tmpSingle); 
                          notifications.scheduleNotify(tillCancel, alarm.id, tmpSingle, single);
                          updateAlarms(alarm);
                          // FlutterBackgroundService.initialize(onStart);
                          setState(() {
                            alarmIcon = Icon(Icons.alarm_on);
                          });
                          foundSingle = true;
                          break;
                        }
                      }
                      if(!foundSingle){
                        setState(() {
                          remindClosest = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Seçilenlere göre yakında bir ders bulunamadı.', textAlign: TextAlign.center)));
                      }
                    },
                  ),
                  SizedBox(height: 10,),
                  ElevatedButton.icon(onPressed: () async{
                    save.time = timeBefore.text;
                    print(save.toString());
                    saveSelections(save);
                    final DateTime? pickedDate = await showDatePicker(
                      helpText: "Tarih Seçin:",
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2050),
                    );
                    if(pickedDate != null){
                      List<Single> toSendS = List.empty(growable: true);
                      for(Single single in s){
                        DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                        DateTime selectedDt = new DateTime(pickedDate.year, pickedDate.month, pickedDate.day);
                        if(validSingle(single) && (singleDt.compareTo(selectedDt) == 0))
                          toSendS.add(single);
                      }
                      Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: 'Hatırlatılıcak Ders Seçme',)));
                    }
                  }, icon: Icon(Icons.date_range), label: Text('Tarihdeki Dersleri Hatırlat')),
                ],
              ),
              ],
                  ),
                      ),
                ),
                ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
class ListAlarmsSend extends StatefulWidget {  
  ListAlarmsSend();
  @override
  State<StatefulWidget> createState() {
    return ListAlarms();
  }
}
class ListAlarms extends State<ListAlarmsSend> {
  ListAlarms();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Hatırlatıcılar"), centerTitle: true, 
      actions: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Row(children: [Container(width: 10, height: 10, color: Colors.red), Text(' Kaçırılanlar' , style: TextStyle(fontSize: 12),)]),
              SizedBox(height: 5,),
              Row(children: [Container(width: 10, height: 10, color: Colors.green), Text(' Gelecektekiler', style: TextStyle(fontSize: 12),)]),
            ],
          ),
        )
      ]
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 10,
          sortColumnIndex: 1,
          columns: [
            DataColumn(label: Text('')),
            DataColumn(label: Text('Tarih')),
            DataColumn(label: Text('Ders')),
            DataColumn(label: Text('Konu')),
            DataColumn(label: Text('Eğitici')),
          ],
          rows: alarms.map<DataRow>((e) => DataRow(
            color: MaterialStateColor.resolveWith((states) => e.single.date.compareTo(DateTime.now())==1?Colors.green:Colors.red),
            cells: [
              DataCell(ElevatedButton.icon(onPressed: (){
                List<Alarm> nAlarms = List.empty(growable: true);
                save.alarms = "";
                for(Alarm alarm in alarms){
                  if(alarm != e)
                    nAlarms.add(alarm);
                  save.alarms = save.alarms! + alarm.id.toString()+"~"+alarm.single.toSave()+"*";
                }
                setState(() {
                  alarms = nAlarms;
                });
                alarms.sort((a, b) => a.single.date.compareTo(b.single.date)); 
                notifications.cancelNotifications(e.id);
              }, style: ElevatedButton.styleFrom(elevation: 0, primary: Colors.transparent), icon: Icon(Icons.delete), label: Text(''))),
              DataCell(Text(displayDate(e.single.date), textAlign: TextAlign.center,)),
              DataCell(Text(e.single.course, textAlign: TextAlign.center,)),
              DataCell(Container(width:100, child: Text(e.single.topic, textAlign: TextAlign.center, overflow: TextOverflow.fade)),),
              DataCell(Text(e.single.lecturer, textAlign: TextAlign.center, overflow: TextOverflow.fade),),
            ]
          )).toList(),
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
  List<Icon>? icons;
  ListPage(this.currentS, this.title);
  @override
  void initState() {
    icons = List.filled(currentS!.length, Icon(Icons.alarm_add, color: Colors.lightGreenAccent));
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(child: Text(this.title!)),
        centerTitle: true,
      ),
      body: Scrollbar(
        isAlwaysShown: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 10,
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black12),
              columns: [
                if(title == 'Hatırlatılıcak Ders Seçme')
                  DataColumn(label: Text('')),
                DataColumn(label: Text('Tarih')),
                if(save.course == "Tüm Sınıflar")
                  DataColumn(label: Text('Sınıf')),
                if(save.type == "Tüm Tipler")
                  DataColumn(label: Text('Tip')),
                if(save.topic == "Tüm Konular")
                  DataColumn(label: Text('Konu')),
                if(save.lecturer == "Tüm Eğiticiler")
                  DataColumn(label: Text('Eğitici')),
              ],
              rows: List.generate(currentS!.length, (index) => getDataRow(index))
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
              // notifications.cancelNotifications();
              setState(() {
                icons?[index] = Icon(Icons.alarm_add, color: Colors.lightGreenAccent);
              });
              return;
            }
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
          }, style: ElevatedButton.styleFrom(primary: Colors.transparent, elevation: 0), icon: currentS![index].date.compareTo(DateTime.now()) != 1?Icon(Icons.alarm_add, color: Colors.grey,):icons![index], label: Text('')) ),
        DataCell(Text(currentS![index].date.day.toString() + "/" + currentS![index].date.month.toString() + "/" + currentS![index].date.year.toString() +" - " + currentS![index].date.hour.toString()+":00")),
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