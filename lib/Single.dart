import 'package:intl/intl.dart';
import 'package:ders_hatirlatici/main.dart';

class Single{
  late DateTime date;
  late String course;
  late String lecturer;
  late String topic;
  late String type;
  Single(this.date, this.course, this.lecturer, this.topic, this.type);
  Single.fromJson(Map<String, dynamic> json):
    date = json['date'],
    course = json['course'],
    lecturer = json['lecturer'],
    type = json['type'],
    topic = json['topic'];
  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'course': course,
      'lecturer': lecturer,
      'type': type,
      'topic': topic
    };
  }
  @override
  String toString() {
    return '"'+this.course +",  " + this.lecturer +",  " + this.topic  +",  " + this.type +",  " + this.date.toString()+'"';
  }
  String toSave(){
    return this.course + "& " + this.lecturer + "& " + this.topic  + "& " + this.type + "& " + displayDate(this.date);
  }
}