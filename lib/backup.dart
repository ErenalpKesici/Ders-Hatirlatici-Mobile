class Backup{
  String? lecturer, course, topic, type, time, timeType, alarms, delay;
  bool? cancelAlarm, listColored, listRotate;
  Backup.initial(){
    lecturer = "Tüm Eğiticiler";
    course = "Tüm Sınıflar";
    topic = "Tüm Ders Konuları";
    type = "Tüm Eğitim Tipleri";
    time = "10";
    timeType = "Dakika";
    cancelAlarm = false;
    listColored = false;
    listRotate = false;
    alarms = '';
    delay = '5';
  }
  Backup(this.lecturer, this.course, this.topic, this.type, this.time, this.timeType, this.cancelAlarm, this.listColored, this.listRotate, this.alarms, this.delay);
  Backup.fromJson(Map<String, dynamic> json):
    lecturer = json['lecturer'],
    course = json['course'],
    time = json['time'],
    type = json['type'],
    topic = json['topic'],
    timeType = json['timeType'],
    cancelAlarm = json['cancelAlarm'],
    listColored = json['listColored'],
    listRotate = json['listRotate'],
    alarms = json['alarms'],    
    delay = json['delay'];
  Map<String, dynamic> toJson() {
    return {
      'lecturer': lecturer,
      'course': course,
      'time': time,
      'type': type,
      'topic': topic,
      'timeType': timeType,
      'cancelAlarm': cancelAlarm,
      'listColored': listColored,
      'listRotate': listRotate,
      'alarms': alarms,
      'delay': delay,
    };
  }
  void placeValue(String key, var value){
    print(key+": " + value.toString());
    switch(key){
      case "lecturer":
        this.lecturer = value;
        break;
      case "course":
        this.course = value;
        break;
      case "topic":
        this.topic = value;
        break;
      case "type":
        this.type = value;
        break;
      case "time":
        this.time = value;
        break;
      case "timeType":
        this.timeType = value;
        break;
      case "cancelAlarm":
        this.cancelAlarm = value;
        break;
      case "listColored":
        this.listColored = value;
        break;
      case "listRotate":
        this.listRotate = value;
        break;
      case "alarms":
        this.alarms = value;
        break;
      case "delay":
        this.delay = value;
        break;
    }
  }
  @override
  String toString() {
    return this.lecturer! + " " + this.topic! + " " +  this.course! + " "  + this.type! + " " + this.time! + " " + this.timeType! + " " + this.cancelAlarm.toString() + " " + this.listColored.toString()+" " + this.delay!;
  }
}