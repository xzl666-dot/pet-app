import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Platform-specific database factory setup
Future<void> setupDatabaseFactory() async {
  if (kIsWeb) {
    // Web platform uses sqflite_web implicitly
    return;
  } else {
    // For native platforms, use sqflite_common_ffi
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
}