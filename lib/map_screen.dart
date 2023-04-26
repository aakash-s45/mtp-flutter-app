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
  final _debouncer = Debouncer(milliseconds: 1000);
  @override
  Widget build(BuildContext context) {
    final mapPoint = ref.watch(mapPointProvider);
    final mapPath = ref.watch(pathProvider);
    final buttonstate = ref.watch(buttonStateProvider);
    final slopeController = ref.watch(slopeTextProvider);
    final weightController = ref.watch(hWeightTextProvider);
    final mapConfig = ref.watch(mapConfigProvider);
    final peaksData = ref.watch(peaksProvider);
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
                      await getRoadFromAPI(
                          ref, mapPoint.src, slopeController, weightController);
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
                          mapConfigNotifier.updateTitle(
                              title: "Failed! No Path Found");
                        }
                      });
                    },
                  ),
                if (checkPoint(mapPoint.src) ||
                    checkPoint(mapPoint.des) ||
                    mapPath.coordinateList.isNotEmpty)
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
            onPressed: () => showDialogBox(context, slopeController, 'Slope'),
            child: Text("Slope: ${slopeController.text}"),
          ),
          ElevatedButton(
            onPressed: () =>
                showDialogBox(context, weightController, 'H Weight'),
            child: Text("H Weight: ${weightController.text}"),
          )
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: widget.mapController,
            options: MapOptions(
              maxBounds: LatLngBounds(
                LatLng(30.230440353741923, 74.91762312044898),
                LatLng(33.53264733816528, 80.08203768885211),
              ),
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
              minZoom: 1,
              zoom: 15,
              maxZoom: 22.0,
              keepAlive: true,
              onMapEvent: (p0) {
                // print(p0.source);
                if (p0.source == MapEventSource.onMultiFinger) {
                  ref
                      .read(mapConfigProvider.notifier)
                      .updateRotation(rotation: widget.mapController.rotation);
                }
                if ((p0.source == MapEventSource.dragEnd ||
                        p0.source ==
                            MapEventSource.doubleTapZoomAnimationController ||
                        p0.source == MapEventSource.multiFingerEnd) &&
                    widget.mapController.zoom > 12.6) {
                  // left,bottom,right,top
                  double? west = widget.mapController.bounds?.west;
                  double? south = widget.mapController.bounds?.south;
                  double? east = widget.mapController.bounds?.east;
                  double? north = widget.mapController.bounds?.north;
                  List<double> bbox = [];
                  if (west != null &&
                      south != null &&
                      east != null &&
                      north != null) {
                    bbox = [west, south, east, north];
                  }
                  _debouncer.run(() async {
                    await makePostRequestToGetPeaks(bbox).then((value) {
                      List peakList = value;
                      if (value.isNotEmpty) {
                        peakList = peakList
                            .map(
                              (peakData) => Peak(
                                coord: LatLng(peakData['latitude'],
                                    peakData['longitude']),
                                height: peakData["height"],
                                prominence: peakData['prominence_m'],
                              ),
                            )
                            .toList();
                        ref
                            .read(peaksProvider.notifier)
                            .update(peaks: peakList as List<Peak>);
                      }
                    });

                    ref
                        .read(mapConfigProvider.notifier)
                        .updateVisibleBBox(visibleBBox: bbox);
                  });
                }
              },
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
                        strokeWidth:
                            pathStroke * (widget.mapController.zoom) * 0.05,
                        points: mapPath.coordinateList,
                        color: Colors.deepPurple,
                      ),
                  ],
                ),
              //
              if (peaksData.peaks.isNotEmpty &&
                  (!buttonstate.start && !buttonstate.end))
                MarkerLayer(
                  rotate: true,
                  markers: peaksData.peaks
                      .map(
                        (peak) => Marker(
                          anchorPos: AnchorPos.align(AnchorAlign.top),
                          point: peak.coord,
                          width: 25,
                          height: 25,
                          builder: (context) => GestureDetector(
                            onTap: () async {
                              // print("Peak Tapped: ${peak.coord}");
                              await peakDialogBox(context, peak)
                                  .then((value) async {
                                if (value == 'showPath') {
                                  await getRoadFromAPI(ref, peak.coord,
                                      slopeController, weightController);
                                }
                              });
                            },
                            child: Image.asset(
                              "asset/mountains.png",
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),

              if (checkPoint(mapPoint.src))
                MarkerLayer(
                  markers: [
                    Marker(
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                      rotate: true,
                      width: 40,
                      height: 40,
                      point: mapPoint.src,
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                    Marker(
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                      rotate: true,
                      width: 120,
                      height: 60,
                      point: mapPoint.src,
                      builder: (context) => Text(
                          "${mapPoint.src.latitude.toStringAsFixed(4)}, ${mapPoint.src.longitude.toStringAsFixed(4)}"),
                    ),
                  ],
                ),
              if (checkPoint(mapPoint.des))
                MarkerLayer(
                  markers: [
                    Marker(
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                      rotate: true,
                      width: 40,
                      height: 40,
                      point: mapPoint.des,
                      builder: (context) => const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                    Marker(
                      anchorPos: AnchorPos.align(AnchorAlign.top),
                      rotate: true,
                      width: 120,
                      height: 60,
                      point: mapPoint.des,
                      builder: (context) => Text(
                          "${mapPoint.des.latitude.toStringAsFixed(4)}, ${mapPoint.des.longitude.toStringAsFixed(4)}"),
                    ),
                  ],
                ),
              if (mapConfig.currLocation.isMocked == false)
                MarkerLayer(
                  markers: [
                    Marker(
                      rotate: true,
                      width: 40,
                      height: 40,
                      point: LatLng(mapConfig.currLocation.latitude,
                          mapConfig.currLocation.longitude),
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
                if (mapConfig.rotation != 0)
                  Transform.rotate(
                    // angle: -25.7 * 0.0174533,
                    angle: (mapConfig.rotation) * 0.0174533 - 0.44854981,
                    child: IconButton(
                        iconSize: 40,
                        onPressed: () {
                          ref
                              .read(mapConfigProvider.notifier)
                              .updateRotation(rotation: 0);
                          widget.mapController.rotate(0);
                        },
                        icon: Image.asset("asset/compass.png")),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
