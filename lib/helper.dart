import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/models.dart';
import 'package:mtpui/provider.dart';
import 'package:mtpui/request.dart';

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

Future<bool> _handleLocationPermission() async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (kDebugMode) {
      print("Location services are disabled");
    }
    return false;
  }
  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (kDebugMode) {
        print("Permission denied");
      }
      return false;
    }
  }
  if (permission == LocationPermission.deniedForever) {
    if (kDebugMode) {
      print("Permission denied forever");
    }
    return false;
  }
  return true;
}

Future<void> getCurrentPosition(WidgetRef ref) async {
  final hasPermission = await _handleLocationPermission();
  if (!hasPermission) return;

  await Geolocator.getCurrentPosition().then((Position position) {
    if (kDebugMode) {
      print(position);
      print(
          "Latitude: ${position.latitude}, Longitude: ${position.longitude} isMocked: ${position.isMocked}, heading: ${position.heading}");
    }
    ref
        .read(mapConfigProvider.notifier)
        .updateCurrLocation(currLocation: position);
  }).catchError((e) {
    debugPrint("Error");
    // debugPrint(e);
  });
}

Future<String?> showDialogBox(
    BuildContext context, TextEditingController slopeController, String title) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: slopeController,
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'Cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(context, 'OK');
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

Future<String?> peakDialogBox(BuildContext context, Peak peak) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: const Text('Info'),
      content: SizedBox(
        height: MediaQuery.of(context).size.height * 0.15,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Coordinates: ${peak.coord.latitude}, ${peak.coord.longitude}'),
            // Text('Height: ${peak.height} ft'),
            Text('Height: ${((peak.height) * 0.3048).round()} m'),
            Text('Prominence: ${peak.prominence} m'),
            // height in metres
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.pop(context, 'cancel'),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            Navigator.pop(context, 'showPath');
          },
          child: const Text('Show Path'),
        ),
      ],
    ),
  );
}

Future<dynamic> getRoadFromAPI(
    WidgetRef ref,
    LatLng srcPoint,
    TextEditingController slopeController,
    TextEditingController weightController) async {
  final mapConfigNotifier = ref.read(mapConfigProvider.notifier);

  mapConfigNotifier.updateTitle(title: "Loading...");
  await makePostRequestToRoad(srcPoint,
          slope: double.parse(slopeController.text),
          hWeight: double.parse(weightController.text))
      .then((value) {
    List coordinateList = value;
    coordinateList =
        coordinateList.map((val) => LatLng(val[0], val[1])).toList();
    if (coordinateList.isNotEmpty) {
      if (coordinateList.first == coordinateList.last) {
        mapConfigNotifier.updateTitle(title: "Same Source and Destination");
      } else {
        ref
            .read(pathProvider.notifier)
            .update(coordinateList: coordinateList as List<LatLng>);
        ref.read(mapPointProvider.notifier).update(des: coordinateList.first);
        mapConfigNotifier.updateTitle(title: "Path Updated");
      }
    } else {
      mapConfigNotifier.updateTitle(title: "No Path Found");
    }
  });
}
