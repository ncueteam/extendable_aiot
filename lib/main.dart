import 'package:flutter/material.dart';
import 'package:extendable_aiot/root_page.dart';
import 'config/app_theme.dart';

void main() async{
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: themeData,
      //title: 'NCUE AIOT',
      debugShowCheckedModeBanner: false, //去掉右上角的紅色橫條
      home: const RootPage(),
    );
  }
}