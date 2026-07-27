import 'package:flutter/material.dart';

/// Global NavigatorKey untuk navigasi dari notifikasi (background/terminated).
/// Dipisah ke file ini agar tidak ada circular import antara main.dart dan splash_screen.dart.
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
