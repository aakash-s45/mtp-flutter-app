import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future makePostRequest(List<double> bbox, LatLng src, LatLng dest) async {
  String urlPrefix = 'http://127.0.0.1:5000';
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
  };

  final json = jsonEncode(req);
  final response = await post(url, headers: headers, body: json);
  print('Status code: ${response.statusCode}');
  // print('Body: ${response.body}');
  if (response.statusCode == 200) {
    var mp = jsonDecode(response.body);

    return mp['data'];
  }
  return [];
}

class Point {
  Point({required this.src, required this.des});
  LatLng src;
  LatLng des;
  Point copywith({LatLng? src, LatLng? des}) {
    return Point(src: src ?? this.src, des: des ?? this.des);
  }
}

class PointNotifier extends StateNotifier<Point> {
  PointNotifier() : super(_initialValue);
  static final Point _initialValue =
      Point(src: MapData.zero, des: MapData.zero);

  void update({LatLng? src, LatLng? des}) {
    state = state.copywith(src: src, des: des);
  }

  void reset() {
    state = state.copywith(src: MapData.zero, des: MapData.zero);
  }
}

final mapPointProvider = StateNotifierProvider<PointNotifier, Point>((ref) {
  return PointNotifier();
});

bool checkPoints(var mapPoint) {
  return ((mapPoint.src.latitude != 0 && mapPoint.src.longitude != 0) &&
      (mapPoint.des.latitude != 0 && mapPoint.des.longitude != 0));
}

bool checkPoint(var point) {
  return (point.latitude != 0 && point.longitude != 0);
}

double distanceBetweenPoints(
    double lat1, double lon1, double lat2, double lon2) {
  lat1 = degToRadian(lat1);
  lon1 = degToRadian(lon1);
  lat2 = degToRadian(lat2);
  lon2 = degToRadian(lon2);

  // Haversine formula
  double dlon = lon2 - lon1;
  double dlat = lat2 - lat1;

  double a =
      pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
  double c = 2 * asin(sqrt(a));
  // Radius of earth in kilometers. Use 3956 for miles
  double r = 6371;
  // calculate the result
  return c * r;
}

// List getBBoxPoints(LatLng latLng1, LatLng latLng2, double r) {
List<double> getBBoxPoints(LatLng latLng1, LatLng latLng2) {
  // Calculate the center point between the two LatLng points
  double centerLat = (latLng1.latitude + latLng2.latitude) / 2;
  double centerLng = (latLng1.longitude + latLng2.longitude) / 2;

  // Calculate the distance between the two LatLng points
  double distance = const Distance().distance(latLng1, latLng2);
  double r = max(1000, distance);

  // Calculate the radius of the circle that encompasses both points
  double circleRadius = distance / 2 + r;

  // Calculate the bounding box around the circle
  double latDelta = circleRadius / 111000;
  double lngDelta = circleRadius / (111000 * cos(pi * centerLat / 180));
  double left = centerLng - lngDelta;
  double right = centerLng + lngDelta;
  double bottom = centerLat - latDelta;
  double top = centerLat + latDelta;

  // Create a buffer around the bounding box
  double bufferLatDelta = r / 111000;
  double bufferLngDelta = r / (111000 * cos(pi * centerLat / 180));
  double bufferLeft = left - bufferLngDelta;
  double bufferRight = right + bufferLngDelta;
  double bufferBottom = bottom - bufferLatDelta;
  double bufferTop = top + bufferLatDelta;

  // Return the coordinates of the bounding box with buffer
  return [bufferLeft, bufferBottom, bufferRight, bufferTop];
}

List<double> getBoundingBox(LatLng latLng1, LatLng latLng2) {
  double left = latLng1.longitude <= latLng2.longitude
      ? latLng1.longitude
      : latLng2.longitude;
  double right = latLng1.longitude > latLng2.longitude
      ? latLng1.longitude
      : latLng2.longitude;
  double bottom = latLng1.latitude <= latLng2.latitude
      ? latLng1.latitude
      : latLng2.latitude;
  double top =
      latLng1.latitude > latLng2.latitude ? latLng1.latitude : latLng2.latitude;

  return [left, bottom, right, top];
}

class MapPath {
  List<LatLng> coordinateList;
  MapPath({required this.coordinateList});
  MapPath copywith({List<LatLng>? coordinateList}) {
    return MapPath(coordinateList: coordinateList ?? this.coordinateList);
  }
}

class PathNotifier extends StateNotifier<MapPath> {
  PathNotifier() : super(_initialValue);
  static final MapPath _initialValue = MapPath(coordinateList: []);
  void update({List<LatLng>? coordinateList}) {
    state = state.copywith(coordinateList: coordinateList);
  }

  void reset() {
    state = state.copywith(coordinateList: []);
  }
}

final pathProvider = StateNotifierProvider<PathNotifier, MapPath>((ref) {
  return PathNotifier();
});

class MapData {
  static LatLng center = LatLng(31.780098, 76.992888);
  static LatLng zero = LatLng(0, 0);
}


class SelectButtonState{
  bool start;
  bool end;
  SelectButtonState({required this.start,required this.end});
  SelectButtonState copywith({bool? start,bool? end}){
    return SelectButtonState(start: start??this.start, end: end??this.end);
  }
}

class ButtonStateNotifier extends StateNotifier<SelectButtonState>{
  ButtonStateNotifier():super(_initialValue);
  static final SelectButtonState _initialValue = SelectButtonState(start: false, end: false);

  void update({bool? start,bool? end}){
    state = state.copywith(start: start, end: end);
  }
}

final buttonStateProvider = StateNotifierProvider<ButtonStateNotifier,SelectButtonState>((ref) => ButtonStateNotifier());