import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sodocu/home/home.dart';
import 'package:sodocu/home/home_bindings.dart';
import 'package:sodocu/theme/app_theme.dart';
import 'package:sodocu/theme/theme_controller.dart';
// import 'package:sodocu/home/home_page.dart';
// import 'package:window_manager/window_manager.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  // خواندن تم ذخیره‌شدهٔ کاربر (در صورت خطا، تم پیش‌فرض حفظ می‌شود).
  await ThemeController.load();

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
    // themeMode از کنترلر تم می‌آید تا با فشردن دکمهٔ تغییر تم،
    // کل اپ با انیمیشن به‌روز شود.
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.mode,
      builder: (context, themeMode, _) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          textDirection: TextDirection.rtl,

          themeMode: themeMode,
          theme: SudokuAppTheme.light,
          darkTheme: SudokuAppTheme.dark,

          home: SudokuBoard(),
          initialBinding: HomeBindings(),
        );
      },
    );
  }
}
