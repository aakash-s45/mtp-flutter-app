import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/models.dart';

class ButtonStateNotifier extends StateNotifier<SelectButtonState> {
  ButtonStateNotifier() : super(_initialValue);
  static final SelectButtonState _initialValue =
      SelectButtonState(start: false, end: false);

  void update({bool? start, bool? end}) {
    state = state.copywith(start: start, end: end);
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

class PointNotifier extends StateNotifier<CheckPoint> {
  PointNotifier() : super(_initialValue);
  static final CheckPoint _initialValue =
      CheckPoint(src: MapData.zero, des: MapData.zero);

  void update({LatLng? src, LatLng? des}) {
    state = state.copywith(src: src, des: des);
  }

  void reset() {
    state = state.copywith(src: MapData.zero, des: MapData.zero);
  }
}

class MapConfigNotifier extends StateNotifier<MapConfig> {
  MapConfigNotifier() : super(_initialValue);
  static final MapConfig _initialValue =
      MapConfig(currLocation: MapData.zeroPos, title: 'Select Points');

  void updateCurrLocation({Position? currLocation}) {
    state = state.copywith(currLocation: currLocation);
  }

  void updateTitle({String? title}) {
    state = state.copywith(title: title);
  }
}
