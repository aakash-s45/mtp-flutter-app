import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/provider.dart';

class MapScreen extends ConsumerWidget {
  MapScreen({super.key});
  String title = "Select Points";

  // List<LatLng> coordlist;

  double pathStroke = 5.0;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapPoint = ref.watch(mapPointProvider);
    final mapPath = ref.watch(pathProvider);
    final buttonstate = ref.watch(buttonStateProvider);
    final slopeController = ref.watch(slopeTextProvider);
    final weightController = ref.watch(hWeightTextProvider);
    return Scaffold(
      floatingActionButton: (!buttonstate.start && !buttonstate.end)
          ? ButtonBar(
              children: [
                ElevatedButton(
                  child: const Icon(Icons.gps_fixed),
                  onPressed: () {},
                ),
                if (checkPoints(mapPoint) && mapPath.coordinateList.isEmpty)
                  ElevatedButton(
                    child: const Icon(Icons.done),
                    onPressed: () async {
                      List<double> bbox =
                          getBBoxPoints(mapPoint.src, mapPoint.des);

                      await makePostRequest(bbox, mapPoint.src, mapPoint.des,
                              slope: double.parse(slopeController.text),
                              hWeight: double.parse(weightController.text))
                          .then((value) {
                        List coordinateList = value;
                        coordinateList = coordinateList
                            .map((val) => LatLng(val[0], val[1]))
                            .toList();

                        if (coordinateList.isNotEmpty) {
                          ref.read(pathProvider.notifier).update(
                              coordinateList: coordinateList as List<LatLng>);
                          title = "Path Updated";
                          // print("Path Updated");
                        } else {
                          title = "No Path Found";
                          // print("No path found");
                        }
                      });
                    },
                  ),
                if (checkPoints(mapPoint))
                  ElevatedButton(
                    child: const Icon(Icons.delete_outline_sharp),
                    onPressed: () {
                      ref.read(pathProvider.notifier).reset();
                      ref.read(mapPointProvider.notifier).reset();
                      title = "Select Points";
                    },
                  ),
              ],
            )
          : null,
      appBar: AppBar(
        title: Text(title),
        actions: [
          ElevatedButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: Text('Slope'),
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
            ),
            child: Text("Slope: ${slopeController.text}"),
          ),
          ElevatedButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Horizontal Weight: (0 - 1)'),
                content: TextField(
                  controller: weightController,
                ),
                actions: <Widget>[
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'Cancel'),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'OK'),
                    child: const Text('OK'),
                  ),
                ],
              ),
            ),
            child: Text("H Weight: ${weightController.text}"),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              onTap: (tapPosition, point) {
                if (buttonstate.start) {
                  ref.read(mapPointProvider.notifier).update(src: point);
                  ref.read(buttonStateProvider.notifier).update(start: false);
                  title = "Select Points";
                  // print("Source Point Update");
                } else if (buttonstate.end) {
                  ref.read(mapPointProvider.notifier).update(des: point);
                  ref.read(buttonStateProvider.notifier).update(end: false);
                  title = "Select Points";
                  // print("Destination Point Update");
                }
              },
              rotation: 0,
              center: (mapPath.coordinateList.isNotEmpty)
                  ? mapPath.coordinateList[0]
                  : MapData.center,
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
              if (mapPath.coordinateList.isNotEmpty)
                PolylineLayer(
                  polylineCulling: false,
                  polylines: [
                    if (mapPath.coordinateList.isNotEmpty)
                      Polyline(
                        borderStrokeWidth: 4.0,
                        borderColor: Colors.black,
                        strokeWidth: pathStroke,
                        points: mapPath.coordinateList,
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
          if (!buttonstate.start && !buttonstate.end)
            ButtonBar(
              children: [
                ElevatedButton(
                    onPressed: () {
                      ref
                          .read(buttonStateProvider.notifier)
                          .update(start: true);
                      title = "Select Start Point";
                    },
                    child: const Text("Start")),
                ElevatedButton(
                    onPressed: () {
                      ref.read(buttonStateProvider.notifier).update(end: true);
                      title = "Select End Point";
                    },
                    child: const Text("End")),
              ],
            )
        ],
      ),
    );
  }
}
