import 'dart:ffi';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';

class CSVObject {
  String Name;
  String Latitude;
  String Longitude;
  String District;

  CSVObject({
    required this.Name,
    required this.Latitude,
    required this.Longitude,
    required this.District,
  });
}

Future<List<CSVObject>> readCSV() async {
  final String rawContent = await rootBundle.loadString('assets/data.csv');

  List<String> lines =
      rawContent.split('\n').where((line) => line.trim().isNotEmpty).toList();

  if (lines.isNotEmpty) {
    lines.removeAt(0);
  }

  final List<CSVObject> objects = [];

  for (var line in lines) {
    try {
      List<List<dynamic>> row = const CsvToListConverter(
        shouldParseNumbers: false,
        fieldDelimiter: ',',
        eol: '\n',
      ).convert(line);

      if (row.isNotEmpty && row[0].length >= 4) {
        objects.add(CSVObject(
          Name: row[0][0].toString(),
          Latitude: row[0][1].toString(),
          Longitude: row[0][2].toString(),
          District: row[0][3].toString(),
        ));
      }
    } catch (e) {
      print('Error parsing line: $line');
      print('Error: $e');
    }
  }

  return objects;
}
