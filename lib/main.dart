import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';
import 'package:ders_hatirlatici/Settings.dart';
import 'package:ders_hatirlatici/notifications.dart';
import 'package:flutter/material.dart';
import 'package:excel/excel.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'Single.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:flutter_archive/flutter_archive.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';
import 'package:http/http.dart' as http;

const String XL_URL = "https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobil/releases/download/Attachments/xl.zip";
const String UPDATE_URL = "https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobil/releases/download/Attachments/Update.txt";
const String APK_URL = "https://github.com/ErenalpKesici/Ders-Hatirlatici-Mobil/releases/download/Attachments/app.apk";
String? selectedDirectory;
List<Single> s = new List<Single>.empty(growable: true);
int tillCancel = 0;
bool upToDate = false;
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
Future<List<String>> readExcel() async{
  List<String> lecturers = new List<String>.empty(growable: true);
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
  print(lecturers.toString());
  return lecturers;
}
void onStart() {
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
void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await FlutterDownloader.initialize(debug: true);
  if(await Permission.storage.request().isGranted){
    final externalDir = await getExternalStorageDirectory();
    selectedDirectory = externalDir!.path +"/xl"; 
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
        timer.cancel();
        runApp(MyApp());
      }
      else if(await File(externalDir.path +"/xl.zip").exists()){
        upToDate = true;   
        timer.cancel();
        runApp(MyApp());
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
Future<List<String>> readCourses() async{
  List<String> courses = List.empty(growable: true);
  courses.add("Tüm Dersler");
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

class _MyHomePageState extends State<MyHomePage> {
  String selectedLecturer = 'Tüm Eğiticiler', selectedCourse = "Tüm Dersler";
  DateTime selectedDate1 = DateTime.now();
  DateTime selectedDate2 = DateTime.now();
  bool dt2Checked = true;
  int? selectedRadio = 0;
  TextEditingController minuteBefore = new TextEditingController(text: "10");
  Icon alarmIcon = Icon(Icons.alarm_off);
  Future<List<String>>? loadLecturers, loadCourses;
  GestureDetector? gdDate1, gdDate2;
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
	  FlutterDownloader.registerCallback(downloadCallback);
    if(upToDate){
      loadLecturers = readExcel(); 
      loadCourses = readCourses();
      return;
    }
    upToDate = true;
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
          setState(() {
            loadLecturers = readExcel();
            loadCourses = readCourses();
          });
        } catch (e) {
          print(e);
        }
    }
  }
  });   
    FlutterDownloader.registerCallback(downloadCallback);
    download();
  }
  @override
  void dispose() {
    IsolateNameServer.removePortNameMapping('downloader_send_port');
    super.dispose();
  }
  static void downloadCallback(String id, DownloadTaskStatus status, int progress) async{
    final SendPort? send = IsolateNameServer.lookupPortByName('downloader_send_port');
    send!.send([id, status, progress]);
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
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text("Ders Hatırlatıcı"),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<List<String>>(
              future: loadLecturers,
              builder: (BuildContext context, AsyncSnapshot snapshot){
                if(snapshot.hasData){
                  return DropdownButton(
                    alignment: AlignmentDirectional.center,
                    items: snapshot.data.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(
                        alignment: AlignmentDirectional.center,
                        value: value,
                        child: Text(value),
                        );
                    }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedLecturer = value!;
                    });
                  },
                  value: selectedLecturer,
                );
              }
              else
                return CircularProgressIndicator();
              }
            ),
            SizedBox(height: 25),
            FutureBuilder<List<String>>(
              future: loadCourses,
              builder: (BuildContext context, AsyncSnapshot snapshot){
                if(snapshot.hasData){
                  return DropdownButton(
                    alignment: AlignmentDirectional.center,
                    items: snapshot.data.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem(
                        alignment: AlignmentDirectional.center,
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  onChanged: (String? value) {
                    setState(() {
                      selectedCourse = value!;
                    });
                  },
                  value: selectedCourse,
                );
              }
              else
                return CircularProgressIndicator();
              }
            ),
            SizedBox(height: 25,),
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
                    if((selectedLecturer == "Tüm Eğiticiler" || single.lecturer == selectedLecturer) && singleDt.compareTo(nowDate) == 1){                    
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
                }, icon: alarmIcon, label: Text('Dakika Kalınca Hatırlat'), style: ElevatedButton.styleFrom(primary: Colors.orange[200]),),
              ],
            ),
            SizedBox(height: 25,),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                gdDate1!,
                Text('     -     '),
                gdDate2!,
                Checkbox(
                  value: dt2Checked, 
                  onChanged: (value){
                    setState(() {
                      dt2Checked = value!;                      
                    });
                  }
                )
              ],
            ),
            SizedBox(height: 25,),
            ElevatedButton.icon(onPressed: () async{
              List<Single> toSendS = new List.empty(growable: true);
              if(dt2Checked)
                for(Single single in s){
                  DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                  DateTime selectedDt1 = new DateTime(selectedDate1.year, selectedDate1.month, selectedDate1.day);
                  DateTime selectedDt2 = new DateTime(selectedDate2.year, selectedDate2.month, selectedDate2.day);
                  if((selectedLecturer == "Tüm Eğiticiler" || single.lecturer == selectedLecturer) && (singleDt.compareTo(selectedDt1) > -1 && singleDt.compareTo(selectedDt2) < 1) && (selectedCourse == "Tüm Dersler" || selectedCourse == single.course))
                    toSendS.add(single);
                }
              else{
                 for(Single single in s){
                  DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day);
                  DateTime selectedDt = new DateTime(selectedDate1.year, selectedDate1.month, selectedDate1.day);
                  if((selectedLecturer == "Tüm Eğiticiler" || single.lecturer == selectedLecturer) && (singleDt.compareTo(selectedDt) == 0) && (selectedCourse == "Tüm Dersler" || selectedCourse == single.course))
                    toSendS.add(single);
                }
              }
              if(toSendS.length > 0)
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: DateFormat('dd/MM/yyyy').format(selectedDate1)+" - " + DateFormat('dd/MM/yyyy').format(selectedDate2),)));
                else
                  ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Ders Bulunamadı', textAlign: TextAlign.center)));
            }, icon: Icon(Icons.find_in_page), label: Text('Dersleri Listele')),
            SizedBox(height: 25,),
            Divider(
              thickness: 1,
            ),
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
            ElevatedButton.icon(onPressed: (){
              if(selectedRadio == null)
                return;
              List<Single> toSendS = new List.empty(growable: true);
              for(Single single in s){
                DateTime singleDt = new DateTime(single.date.year, single.date.month, single.date.day, single.date.hour);
                DateTime nowDate = new DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, DateTime.now().hour);
                if((selectedLecturer == "Tüm Eğiticilerler" || single.lecturer == selectedLecturer) && ((selectedRadio == 1 && singleDt.compareTo(nowDate) == 0) || selectedRadio == 0 && singleDt.compareTo(nowDate)  == 1 && (selectedCourse == "Tüm Dersler" || selectedCourse == single.course))){
                    toSendS.add(single);
                    break;}
              }
              if(toSendS.length > 0)
                Navigator.of(context).push(MaterialPageRoute(builder: (context) =>ListPageSend(currentS: toSendS, title: selectedRadio == 0?'En Yakındaki Ders':'Şuandaki Ders',)));
              else
                ScaffoldMessenger.of(context).showSnackBar(new SnackBar(content: Text('Ders Bulunamadı', textAlign: TextAlign.center)));
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
      body: Scrollbar(
        isAlwaysShown: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: MaterialStateColor.resolveWith((states) => Colors.black12),
              columns: [
                DataColumn(label: Text('Tarih')),
                DataColumn(label: Text('Sınıf')),
                DataColumn(label: Text('Tip')),
                DataColumn(label: Text('Eğitici')),
                DataColumn(label: Text('Konu')),
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
      color: MaterialStateColor.resolveWith((states) => currentS![index].type == "UE"?Colors.orange[700]!:Colors.lightBlue[700]!),
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