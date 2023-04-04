import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/provider.dart';
import 'package:mtpui/select_screen.dart';

class MapScreen extends ConsumerWidget {
  MapScreen({super.key, required this.coordlist});
  List<LatLng> coordlist;
  LatLng srcPoint = LatLng(0, 0);
  LatLng desPoint = LatLng(0, 0);

  String pointType = "src";

  double pathStroke = 5.0;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapPoint = ref.watch(pointProvider);
    return Scaffold(
      floatingActionButton: ButtonBar(
        // alignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton(
            child: const Icon(Icons.gps_fixed),
            onPressed: () {},
          ),
          if (checkPoints(mapPoint))
            ElevatedButton(
              child: const Icon(Icons.done),
              onPressed: () async {
                List<double> bbox = getBBoxPoints(mapPoint.src, mapPoint.des);

                await makePostRequest(bbox, mapPoint.src, mapPoint.des)
                    .then((value) {
                  List coordinateList = value;
                  coordinateList.map((val) => LatLng(val[0], val[1])).toList();
                  if (coordinateList.isNotEmpty) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MapScreen(
                          coordlist: coordinateList
                              .map((val) => LatLng(val[0], val[1]))
                              .toList(),
                        ),
                      ),
                    );
                  } else {
                    print("No path found");
                  }
                  print(value.runtimeType);
                });
              },
            ),
        ],
      ),
      appBar: AppBar(),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              rotation: 0,
              center: coordlist[0],
              minZoom: 12,
              zoom: 15,
              maxZoom: 22.0,
              keepAlive: true,
            ),
            children: [
              TileLayer(
                maxZoom: 22,
                maxNativeZoom: 18,
                subdomains: ["a", "b", "c"],
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
              ),
              if (coordlist.isNotEmpty)
                PolylineLayer(
                  polylineCulling: false,
                  polylines: [
                    if (coordlist.isNotEmpty)
                      Polyline(
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.black,
                        strokeWidth: pathStroke,
                        points: coordlist,
                        color: Colors.deepPurple,
                      ),
                  ],
                ),
              if (checkPoint(mapPoint.src))
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapPoint.src,
                      width: 80,
                      height: 80,
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
              if (checkPoint(mapPoint.des))
                MarkerLayer(
                  markers: [
                    Marker(
                      point: mapPoint.des,
                      width: 80,
                      height: 80,
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          ButtonBar(
            children: [
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectMapScreen(
                          pointType: "src",
                        ),
                      ),
                    );
                  },
                  child: const Text("Start")),
              ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SelectMapScreen(
                          pointType: "des",
                        ),
                      ),
                    );
                  },
                  child: const Text("End")),
            ],
          )
        ],
      ),
    );
  }
}
