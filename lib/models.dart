import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class CheckPoint {
  CheckPoint({required this.src, required this.des});
  LatLng src;
  LatLng des;
  CheckPoint copywith({LatLng? src, LatLng? des}) {
    return CheckPoint(src: src ?? this.src, des: des ?? this.des);
  }
}

class MapData {
  static LatLng center = LatLng(31.780098, 76.992888);
  static LatLng zero = LatLng(0, 0);
  static Position zeroPos = Position(
      longitude: 0,
      latitude: 0,
      timestamp: DateTime(2017, 9, 7, 17, 30),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      isMocked: true);
}

class MapPath {
  List<LatLng> coordinateList;
  MapPath({required this.coordinateList});
  MapPath copywith({List<LatLng>? coordinateList}) {
    return MapPath(coordinateList: coordinateList ?? this.coordinateList);
  }
}

class SelectButtonState {
  bool start;
  bool end;
  SelectButtonState({required this.start, required this.end});
  SelectButtonState copywith({bool? start, bool? end}) {
    return SelectButtonState(start: start ?? this.start, end: end ?? this.end);
  }
}

class MapConfig {
  Position currLocation;
  String title;
  MapConfig({required this.currLocation, required this.title});
  MapConfig copywith({Position? currLocation, String? title}) {
    return MapConfig(
        currLocation: currLocation ?? this.currLocation,
        title: title ?? this.title);
  }
}
