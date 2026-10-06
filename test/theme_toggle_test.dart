import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sodocu/theme/theme_controller.dart';
import 'package:sodocu/theme/theme_toggle_button.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ThemeController.mode.value = ThemeMode.dark;
  });

  test('تم انتخاب‌شده ذخیره و در اجرای بعد بازخوانی می‌شود', () async {
    SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
    ThemeController.mode.value = ThemeMode.dark;

    await ThemeController.load();
    expect(ThemeController.mode.value, ThemeMode.light);

    await ThemeController.set(ThemeMode.dark);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('theme_mode'), 'dark');
  });

  testWidgets('دکمهٔ تغییر تم، تم را بین تیره و روشن جابه‌جا می‌کند', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ThemeToggleButton())),
    );

    // حالت اولیه: تیره با آیکون ماه.
    expect(ThemeController.mode.value, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
    expect(find.byTooltip('تغیر تم'), findsOneWidget);

    // اولین فشردن → روشن (بعد از پایان انیمیشن دایره).
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.light);
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);

    // فشردن دوباره → برگشت به تیره.
    await tester.tap(find.byType(ThemeToggleButton));
    await tester.pumpAndSettle();
    expect(ThemeController.mode.value, ThemeMode.dark);
    expect(find.byIcon(Icons.dark_mode_outlined), findsOneWidget);
  });
}
