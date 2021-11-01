class Backup{
  String? lecturer, course, topic, type, time, timeType, alarms;
  bool? cancelAlarm, listColored;
  Backup.initial(){
    lecturer = "Tüm Eğiticiler";
    course = "Tüm Sınıflar";
    topic = "Tüm Konular";
    type = "Tüm Tipler";
    time = "10";
    timeType = "Dakika";
    cancelAlarm = false;
    listColored = false;
    alarms = '';
  }
  Backup(this.lecturer, this.course, this.topic, this.type, this.time, this.timeType, this.cancelAlarm, this.listColored, this.alarms);
  Backup.fromJson(Map<String, dynamic> json):
    lecturer = json['lecturer'],
    course = json['course'],
    time = json['time'],
    type = json['type'],
    topic = json['topic'],
    timeType = json['timeType'],
    cancelAlarm = json['cancelAlarm'],
    listColored = json['listColored'],
    alarms = json['alarms'];    
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
      'alarms': alarms
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
      case "alarms":
        this.alarms = value;
        break;
    }
  }
  @override
  String toString() {
    return this.lecturer! + " " + this.topic! + " " +  this.course! + " "  + this.type! + " " + this.time! + " " + this.timeType! + " " + this.cancelAlarm.toString() + " " + this.listColored.toString();
  }
}