import 'dart:convert';

import 'Single.dart';

class Temp{
  late List<Single> allS;
  Temp(this.allS);
  Temp.fromJson(Map<String, dynamic> json):
    allS = json['allS'];
  Map<String, dynamic> toJson() {
    return {
      'allS': allS.toString()
    };
  }
}