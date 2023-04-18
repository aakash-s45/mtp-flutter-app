import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/helper.dart';
import 'package:mtpui/models.dart';
import 'package:mtpui/provider.dart';
import 'package:mtpui/request.dart';

class MapScreen extends ConsumerStatefulWidget {
  MapScreen({super.key});
  final MapController mapController = MapController();

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  double pathStroke = 5.0;
  @override
  Widget build(BuildContext context) {
    final mapPoint = ref.watch(mapPointProvider);
    final mapPath = ref.watch(pathProvider);
    final buttonstate = ref.watch(buttonStateProvider);
    final slopeController = ref.watch(slopeTextProvider);
    final weightController = ref.watch(hWeightTextProvider);
    final mapConfig = ref.watch(mapConfigProvider);
    return Scaffold(
      floatingActionButton: (!buttonstate.start && !buttonstate.end)
          ? ButtonBar(
              children: [
                ElevatedButton(
                    onPressed: () async {
                      await getCurrentPosition(ref).whenComplete(() {
                        if (mapConfig.currLocation.isMocked == false) {
                          widget.mapController.move(
                              LatLng(mapConfig.currLocation.latitude,
                                  mapConfig.currLocation.longitude),
                              15);
                        }
                      });
                    },
                    child: const Icon(Icons.gps_fixed)),
                if (checkPoint(mapPoint.src) && mapPath.coordinateList.isEmpty)
                  ElevatedButton(
                    child: const Icon(Icons.add_road),
                    onPressed: () async {
                      final mapConfigNotifier =
                          ref.read(mapConfigProvider.notifier);

                      mapConfigNotifier.updateTitle(title: "Loading...");
                      await makePostRequestToRoad(mapPoint.src,
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
                          mapConfigNotifier.updateTitle(title: "Path Updated");
                        } else {
                          mapConfigNotifier.updateTitle(title: "No Path Found");
                        }
                      });
                    },
                  ),
                if (checkPoints(mapPoint) && mapPath.coordinateList.isEmpty)
                  ElevatedButton(
                    child: const Icon(Icons.done),
                    onPressed: () async {
                      final mapConfigNotifier =
                          ref.read(mapConfigProvider.notifier);

                      List<double> bbox =
                          getBBoxPoints(mapPoint.src, mapPoint.des);
                      mapConfigNotifier.updateTitle(title: "Loading...");

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
                          mapConfigNotifier.updateTitle(title: "Path Updated");
                        } else {
                          mapConfigNotifier.updateTitle(title: "No Path Found");
                        }
                      });
                    },
                  ),
                if (checkPoint(mapPoint.src))
                  ElevatedButton(
                    child: const Icon(Icons.delete_outline_sharp),
                    onPressed: () {
                      ref.read(pathProvider.notifier).reset();
                      ref.read(mapPointProvider.notifier).reset();
                      ref
                          .read(mapConfigProvider.notifier)
                          .updateTitle(title: "Select Points");
                    },
                  ),
              ],
            )
          : null,
      appBar: AppBar(
        title: (mapConfig.title != 'Loading...')
            ? Text(
                mapConfig.title,
                style: const TextStyle(fontSize: 14),
              )
            : const CircularProgressIndicator(
                color: Colors.white,
              ),
        actions: [
          ElevatedButton(
            onPressed: () => showDialog<String>(
              context: context,
              builder: (BuildContext context) => AlertDialog(
                title: const Text('Slope'),
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
            mapController: widget.mapController,
            options: MapOptions(
              onTap: (tapPosition, point) {
                if (buttonstate.start) {
                  ref.read(mapPointProvider.notifier).update(src: point);
                  ref.read(buttonStateProvider.notifier).update(start: false);
                  ref
                      .read(mapConfigProvider.notifier)
                      .updateTitle(title: "Select Points");
                } else if (buttonstate.end) {
                  ref.read(mapPointProvider.notifier).update(des: point);
                  ref.read(buttonStateProvider.notifier).update(end: false);
                  ref
                      .read(mapConfigProvider.notifier)
                      .updateTitle(title: "Select Points");
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
                maxNativeZoom: 17,
                subdomains: const ["a", "b", "c"],
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
              if (mapConfig.currLocation.isMocked == false)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: LatLng(mapConfig.currLocation.latitude,
                          mapConfig.currLocation.longitude),
                      width: 20,
                      height: 20,
                      builder: (context) => const Icon(
                        Icons.gps_fixed_rounded,
                        color: Colors.red,
                        size: 30,
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
                      ref
                          .read(mapConfigProvider.notifier)
                          .updateTitle(title: "Select Start Point");
                    },
                    child: const Text("Start")),
                ElevatedButton(
                    onPressed: () {
                      ref.read(buttonStateProvider.notifier).update(end: true);
                      ref
                          .read(mapConfigProvider.notifier)
                          .updateTitle(title: "Select End Point");
                    },
                    child: const Text("End")),
              ],
            )
        ],
      ),
    );
  }
}
