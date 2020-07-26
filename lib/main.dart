import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:whatspapo/Home.dart';
import 'package:whatspapo/Login.dart';
import 'package:whatspapo/RouteGenerator.dart';
import 'dart:io';

final ThemeData temaIos = ThemeData(
  primaryColor: Colors.grey[200],
  accentColor: Color(0xff25D366)
);

final ThemeData temaPadrao = ThemeData(
    primaryColor: Color(0xff7A258E),
    accentColor: Colors.green[200]
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(MaterialApp(
    home: Login(),
    theme: Platform.isIOS ? temaIos : temaPadrao,
    initialRoute: '/',
    onGenerateRoute: RouteGenerator.generatorRoute,
    /*routes: {
      '/login' : (context) => Login(),
      '/home' : (context) => Home(),
    },*/
    debugShowCheckedModeBanner: false,
  ));
}
