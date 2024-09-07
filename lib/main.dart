import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:pi_farm/src/page/app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}
