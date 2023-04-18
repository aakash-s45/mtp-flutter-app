import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/provider.dart';

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
    debugPrint(e);
  });
}
