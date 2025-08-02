import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

Future<Map<String, dynamic>> loadJsonData(String dataPath) async {
  String jsonString = await rootBundle.loadString(dataPath);

  Map<String, dynamic> jsonData = jsonDecode(jsonString);
  return jsonData;
}
