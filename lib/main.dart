import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:mtpui/map_screen.dart';
import 'package:mtpui/provider.dart';

void main() {
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    List<LatLng> coord_List = [
      LatLng(31.789193, 76.992053),
      LatLng(31.790524, 76.997072),
      LatLng(31.793338, 76.995862)
    ];

    return MaterialApp(
      home: MapScreen(coordlist: coord_List),
      // home: Home(),
    );
  }
}

class Home extends ConsumerWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final left = ref.watch(leftProvider);
    final bottom = ref.watch(bottomProvider);
    final right = ref.watch(rightProvider);
    final top = ref.watch(topProvider);
    final srcLat = ref.watch(srcLatProvider);
    final srcLon = ref.watch(srcLonProvider);
    final desLat = ref.watch(desLatProvider);
    final desLon = ref.watch(desLonProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await makePostRequest([
            double.parse(left.text),
            double.parse(bottom.text),
            double.parse(right.text),
            double.parse(top.text),
          ], LatLng(double.parse(srcLat.text), double.parse(srcLon.text)),
                  LatLng(double.parse(desLat.text), double.parse(desLon.text)))
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
        child: const Icon(Icons.search),
      ),
      appBar: AppBar(
        title: const Text("MTP"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            TextField(
              controller: ref.read(leftProvider),
              decoration: const InputDecoration(hintText: "Left"),
            ),
            TextField(
              controller: ref.read(bottomProvider),
              decoration: const InputDecoration(hintText: "Bottom"),
            ),
            TextField(
              controller: ref.read(rightProvider),
              decoration: const InputDecoration(hintText: "Right"),
            ),
            TextField(
              controller: ref.read(topProvider),
              decoration: const InputDecoration(hintText: "Top"),
            ),
            TextField(
              controller: ref.read(srcLatProvider),
              decoration: const InputDecoration(hintText: "Source Latitude"),
            ),
            TextField(
              controller: ref.read(srcLonProvider),
              decoration: const InputDecoration(hintText: "Source Longitude"),
            ),
            TextField(
              controller: ref.read(desLatProvider),
              decoration:
                  const InputDecoration(hintText: "Destination Latitude"),
            ),
            TextField(
              controller: ref.read(desLonProvider),
              decoration:
                  const InputDecoration(hintText: "Destination Longitude"),
            ),
          ],
        ),
      ),
      // body: MapScreen(),
    );
  }
}
