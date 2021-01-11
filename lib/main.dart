import 'dart:async';
import 'package:flutter/material.dart';
import 'control.dart';
import 'package:volume/volume.dart';
import 'package:system_shortcuts/system_shortcuts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {

  void initial() async {
    await SystemShortcuts.orientLandscape();
    await Volume.controlVolume(AudioManager.STREAM_MUSIC);
    await Volume.setVol(15, showVolumeUI: ShowVolumeUI.HIDE);
    await Volume.controlVolume(AudioManager.STREAM_RING);
    await Volume.setVol(15, showVolumeUI: ShowVolumeUI.HIDE);
    await Volume.controlVolume(AudioManager.STREAM_NOTIFICATION);
    await Volume.setVol(0, showVolumeUI: ShowVolumeUI.HIDE);
  }

  @override
  Widget build(BuildContext context) {

    Timer.periodic(Duration(seconds: 1), (timer) {
      initial();
    });

    return MaterialApp(
      home: Control(),
    );
  }
}