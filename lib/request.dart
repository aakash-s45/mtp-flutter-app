import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';

Future makePostRequest(List<double> bbox, LatLng src, LatLng dest,
    {double slope = 30, double hWeight = 0.1}) async {
  String urlPrefix = (kDebugMode)
      ? 'http://127.0.0.1:5000'
      : 'https://mtp-pathfinding.azurewebsites.net';
  final url = Uri.parse('$urlPrefix/path');
  final headers = {"Content-type": "application/json"};
  Map req = {
    "left": bbox[0],
    "bottom": bbox[1],
    "right": bbox[2],
    "top": bbox[3],
    "src_lat": src.latitude,
    "src_lon": src.longitude,
    "des_lat": dest.latitude,
    "des_lon": dest.longitude,
    "slope": slope,
    "h_weight": hWeight
  };

  final json = jsonEncode(req);
  final response = await post(url, headers: headers, body: json);
  if (kDebugMode) {
    print('Status code: ${response.statusCode}');
  }
  // print('Body: ${response.body}');
  if (response.statusCode == 200) {
    var mp = jsonDecode(response.body);

    return mp['data'];
  }
  return [];
}

Future makePostRequestToRoad(LatLng src,
    {double slope = 30, double hWeight = 0.1, double radius = 30}) async {
  // String urlPrefix = 'http://127.0.0.1:5000';
  String urlPrefix = 'https://mtp-pathfinding.azurewebsites.net';
  final url = Uri.parse('$urlPrefix/to_road');
  final headers = {"Content-type": "application/json"};

  Map req = {
    "src_lat": src.latitude,
    "src_lon": src.longitude,
    "slope": slope,
    "radius": radius,
    "h_weight": hWeight
  };

  final json = jsonEncode(req);
  final response = await post(url, headers: headers, body: json);
  if (kDebugMode) {
    print('Status code: ${response.statusCode}');
  }
  // print('Body: ${response.body}');
  if (response.statusCode == 200) {
    var mp = jsonDecode(response.body);

    return mp['data'];
  }
  return [];
}
