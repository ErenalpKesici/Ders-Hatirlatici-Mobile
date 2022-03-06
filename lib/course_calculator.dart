import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'Single.dart';
import 'main.dart';

class CourseCalculatorPageSend extends StatefulWidget{
  @override
  State<StatefulWidget> createState() {
    return CourseCalculatorPage();
  }
}
class CourseCalculatorPage extends State<CourseCalculatorPageSend>{
  String selectedLecturer = 'Tüm Eğiticiler', selectedType = "Tüm Eğitim Tipleri", beforeAfter = 'önce';
  DateTime selectedDate = DateTime.now();
  bool filteredDate = false;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ders Sayısı Hesaplama'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButton<String>(
              alignment: AlignmentDirectional.center,
              value: selectedLecturer,
              onChanged: (String? newValue) {
                setState(() {
                  selectedLecturer = newValue!;
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
                value: selectedType,
                onChanged: (String? newValue) {
                  setState(() {
                    selectedType = newValue!;
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
            CheckboxListTile(
              value: filteredDate, 
              onChanged: (bool? value){
                setState(() {
                  filteredDate = value!;
                });
              },
              title: Opacity(
                opacity: filteredDate==true?1:0.1,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ElevatedButton.icon(
                        onPressed: () async {      
                          final DateTime? pickedDate = await showDatePicker(
                            helpText: "Başlangıç Tarihini Seçin:",
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2050),
                          );
                          if(pickedDate != null)
                            setState(() {
                              selectedDate = pickedDate;
                            });
                        }, icon: Icon(Icons.date_range), label: Text(DateFormat('yyyy-MM-dd hh:mm').format(selectedDate).toString())),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('tarihten '),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: DropdownButton(
                            value: beforeAfter,
                            items: ['önce', 'sonra'].map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                alignment: AlignmentDirectional.center,
                                value: value,
                                child: Text(value),
                              );
                            }).toList(), 
                            onChanged: (String? value) { 
                              setState(() {
                                beforeAfter = value!;
                              });
                              print(value);
                            },
                          ),
                        ),    
                        Text(' olan '),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                List<Single> filteredS = s;
                if(selectedLecturer != "Tüm Eğiticiler"){
                  filteredS = filteredS.where((element) => element.lecturer == selectedLecturer).toList();
                }
                if(selectedType != "Tüm Eğitim Tipleri"){
                  filteredS = filteredS.where((element) => element.type == selectedType).toList();
                }
                if(filteredDate){
                  if(beforeAfter=='önce'){
                    filteredS = filteredS.where((element) => element.date.compareTo(selectedDate) < 1).toList();
                  }
                  else{
                    filteredS = filteredS.where((element) => element.date.compareTo(selectedDate) > -1).toList();
                  }
                }
                return await showDialog(context: context, builder: (context){
                  return AlertDialog(
                    title: const Text("Toplam Ders Sayısı", textAlign: TextAlign.center,),
                    content: Text(filteredS.length.toString(), textAlign: TextAlign.center,),
                    actions: <Widget>[
                      ElevatedButton(
                        onPressed: (){
                          Navigator.of(context).pop();
                        },
                        child: const Text("OK",),
                      )
                    ],
                  );
                });
              }, icon: Icon(Icons.find_in_page_outlined), label: Text("Toplam Ders Sayısını Hesapla")
            )
          ],
        ),
      ),
    );
  }
}