class Backup{
  String lecturer = "", course = "", topic = "", type = "", time = "", timeType = "";
  Backup.initial(){
    lecturer = "Tüm Eğiticiler";
    course = "Tüm Sınıflar";
    topic = "Tüm Konular";
    type = "Tüm Tipler";
    time = "10";
    timeType = "Dakika";
  }
  Backup(this.lecturer, this.course, this.topic, this.type, this.time, this.timeType);
  Backup.fromJson(Map<String, dynamic> json)
    : lecturer = json['lecturer'],
      course = json['course'],
      time = json['time'],
      type = json['type'],
      topic = json['topic'],
      timeType = json['timeType'];
  Map<String, dynamic> toJson() {
    return {
      'lecturer': lecturer,
      'course': course,
      'time': time,
      'type': type,
      'topic': topic,
      'timeType': timeType,
    };
  }
  @override
  String toString() {
    return this.lecturer + " " + this.topic + " " +  this.course + " "  + this.type + " " + this.time + " " + this.timeType;
  }
}