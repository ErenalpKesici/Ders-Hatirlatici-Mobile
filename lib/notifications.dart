import 'dart:ui';

import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'Alarm.dart';
import 'Single.dart';
import 'main.dart';

class MyNotifications{
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

  void scheduleNotify(int inSeconds, int id, Single alarmified, Single original) async{
    print("IN: " + (inSeconds/60).toString() +" and " + alarmified.toSave() +" or: " + original.toSave());
    Future.delayed(Duration(seconds: inSeconds), (){
      List<Alarm> nAlarms = List.empty(growable: true);
      for(Alarm alarm in alarms)
        if(alarm.single.toSave() != alarmified.toSave())
          nAlarms.add(alarm);
      alarms = nAlarms;
    });
    tz.initializeTimeZones();  
    AwesomeNotifications().createNotification(
      schedule: NotificationInterval(interval: inSeconds, timeZone: await AwesomeNotifications().getLocalTimeZoneIdentifier(), repeats: false),
      actionButtons: [
        NotificationActionButton(key: 'btnOk', label: 'Tamam', buttonType: ActionButtonType.KeepOnTop),
        NotificationActionButton(key: 'btnDelay', label: 'Ertele', buttonType: ActionButtonType.KeepOnTop),
      ],
      content: NotificationContent(
        id: id,
        channelKey: 'basic_channel',
        title: alarmified==original?"Yakında başlıyacak ders: ":original.date.difference(DateTime.now()).inMinutes.toString() +" dakika içinde başlıyacak ders: ",
        body: original.toString(),
        notificationLayout: NotificationLayout.BigText   
      )
    );

    // var initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    // var initializationSettings = InitializationSettings(android: initializationSettingsAndroid, iOS: null);
    // await flutterLocalNotificationsPlugin.initialize(initializationSettings,onSelectNotification: (String? payload) async {}); 
    // await flutterLocalNotificationsPlugin.zonedSchedule(id, alarmified==original?"Yakında başlıyacak ders: ":original.date.difference(DateTime.now()).inMinutes.toString() +" dakika içinde başlıyacak: ", original.toString(), tz.TZDateTime.now(tz.local).add(Duration(seconds: inSeconds)), const NotificationDetails(android: AndroidNotificationDetails('your channel id', 'your channel name', 'your channel description', enableLights: true, sound: RawResourceAndroidNotificationSound('alarm'), playSound: true)), androidAllowWhileIdle: true, uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime);
  }
  void cancelNotifications(int id){
    if(id == -1)
      flutterLocalNotificationsPlugin.cancelAll();
    else
      flutterLocalNotificationsPlugin.cancel(id);
  }
} 