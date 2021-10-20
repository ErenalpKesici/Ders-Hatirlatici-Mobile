class Backup{
  String lecturer = "", course = "", topic = "", time = "", timeType = "";
  Backup(this.lecturer, this.course, this.topic, this.time, this.timeType);
  Backup.fromJson(Map<String, dynamic> json)
    : lecturer = json['lecturer'],
      course = json['course'],
      time = json['time'],
      topic = json['topic'],
      timeType = json['timeType'];
  Map<String, dynamic> toJson() {
    return {
      'lecturer': lecturer,
      'course': course,
      'time': time,
      'topic': topic,
      'timeType': timeType,
    };
  }
  @override
  String toString() {
    return this.lecturer + " " + this.topic + " " +  this.course + " " + this.time + " " + this.timeType;
  }
}