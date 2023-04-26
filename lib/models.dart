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

class Peak {
  Peak({required this.coord, required this.height, required this.prominence});
  LatLng coord;
  int height;
  double prominence;
}

class Peaks {
  List<Peak> peaks;
  Peaks({required this.peaks});
  Peaks copywith({List<Peak>? peaks}) {
    return Peaks(peaks: peaks ?? this.peaks);
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
  double rotation;
  Position currLocation;
  String title;
  List<double> visibleBBox;
  MapConfig(
      {required this.currLocation,
      required this.title,
      required this.visibleBBox,
      required this.rotation});
  MapConfig copywith(
      {Position? currLocation,
      String? title,
      List<double>? visibleBBox,
      double? rotation}) {
    return MapConfig(
      currLocation: currLocation ?? this.currLocation,
      title: title ?? this.title,
      visibleBBox: visibleBBox ?? this.visibleBBox,
      rotation: rotation ?? this.rotation,
    );
  }
}
