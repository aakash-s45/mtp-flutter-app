import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/provider.dart';

class SelectMapScreen extends ConsumerWidget {
  String pointType;
  SelectMapScreen({super.key, required this.pointType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapPoint = ref.watch(pointProvider);
    return Scaffold(
      appBar: AppBar(
          title: Text(
              (pointType == "src") ? "Select Source" : "Select Destination")),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              onTap: (tapPosition, point) {
                if (pointType == "src") {
                  ref.read(pointProvider.notifier).update(src: point);
                  print("Source Point Update");
                } else {
                  ref.read(pointProvider.notifier).update(des: point);
                  print("Destination Point Update");
                }
              },
              center: LatLng(23.5120, 80.3290),
              rotation: 0,
              minZoom: 5,
              zoom: 5,
              maxZoom: 22.0,
              keepAlive: true,
            ),
            children: [
              TileLayer(
                maxZoom: 22,
                maxNativeZoom: 18,
                subdomains: const ["a", "b", "c"],
                urlTemplate: 'https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.app',
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
                        color: Colors.red,
                        size: 40,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    print("Done");
                  },
                  child: const Icon(Icons.done)),
            ),
          )
        ],
      ),
    );
  }
}
