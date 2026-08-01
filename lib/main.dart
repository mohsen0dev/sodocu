import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/home.dart';
import 'package:sodocu/home/home_bindings.dart';
// import 'package:sodocu/home/home_page.dart';
// import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // await windowManager.ensureInitialized();

  // WindowOptions windowOptions = const WindowOptions(
  // minimumSize: Size(400, 600),
  // titleBarStyle: TitleBarStyle.normal,
  // windowButtonVisibility: false,
  // center: true,
  // );

  // windowManager.waitUntilReadyToShow(windowOptions, () async {
  //   await windowManager.show();
  //   await windowManager.focus();
  // });
  runApp(SudokuApp());
}

class SudokuApp extends StatelessWidget {
  const SudokuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      textDirection: TextDirection.rtl,

      themeMode: ThemeMode.dark,
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
      ),

      // home: SudokuBoard(),
      home: SudokuBoard(),
      initialBinding: HomeBindings(),
    );
  }
}
