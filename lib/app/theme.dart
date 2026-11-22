import 'package:flutter/material.dart';

// Phase 4 replaces these with Atom One Light / One Dark (decision #18).
const _seed = Colors.blue;

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(seedColor: _seed),
);

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  colorScheme:
      ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark),
);
