import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'Single.dart';

class MyNotifications{
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();
  void scheduleNotify(int inSeconds, Single description) async{
    print(inSeconds/60);
    tz.initializeTimeZones();
    var initializationSettingsAndroid =AndroidInitializationSettings('logo');
    var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: null);
    await flutterLocalNotificationsPlugin.initialize(initializationSettings,onSelectNotification: (String? payload) async {}); 
    await flutterLocalNotificationsPlugin.zonedSchedule(0, description.date.difference(DateTime.now()).inMinutes.toString() +" dakika icinde: ", description.toString(), tz.TZDateTime.now(tz.local).add(Duration(seconds: inSeconds)), const NotificationDetails(android: AndroidNotificationDetails('your channel id',        'your channel name', 'your channel description')), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation:    UILocalNotificationDateInterpretation.absoluteTime);
    print("?");
  }
  MyNotifications(){
   
  }
} 