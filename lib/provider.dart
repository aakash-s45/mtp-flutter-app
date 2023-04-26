import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mtpui/models.dart';
import 'package:mtpui/notifier.dart';

final mapPointProvider =
    StateNotifierProvider<PointNotifier, CheckPoint>((ref) {
  return PointNotifier();
});

final pathProvider = StateNotifierProvider<PathNotifier, MapPath>((ref) {
  return PathNotifier();
});

final buttonStateProvider =
    StateNotifierProvider<ButtonStateNotifier, SelectButtonState>(
        (ref) => ButtonStateNotifier());

final slopeTextProvider = Provider((ref) => TextEditingController(text: "30"));
final hWeightTextProvider =
    Provider((ref) => TextEditingController(text: "0.1"));

final mapConfigProvider = StateNotifierProvider<MapConfigNotifier, MapConfig>(
    (ref) => MapConfigNotifier());

final peaksProvider = StateNotifierProvider<PeaksNotifier, Peaks>((ref) {
  return PeaksNotifier();
});
