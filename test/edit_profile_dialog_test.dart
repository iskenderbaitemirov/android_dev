import 'package:android_dev/core/db/app_database.dart';
import 'package:android_dev/core/db/database_provider.dart';
import 'package:android_dev/screens/home_screen/state/auth_controller.dart';
import 'package:android_dev/screens/tabs/profile_tab.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Regression test for the freeze: pressing "Save" in Edit profile used to
/// dispose the text controllers while the dialog was still fading out.
/// The DB runs on real async time, so keep giving it a moment and redrawing
/// until [finder] shows up (max ~5 s). Fixed waits are flaky when tests
/// run in parallel.
Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 100 && finder.evaluate().isEmpty; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump();
  }
  expect(finder, findsWidgets);
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  testWidgets('Edit profile → Save closes cleanly and updates the bio', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(executor: NativeDatabase.memory(), seedDemoData: false);
    final container = ProviderContainer(
      overrides: [databaseProvider.overrideWithValue(db)],
    );
    addTearDown(() async {
      container.dispose();
      await tester.runAsync(db.close);
    });

    // Real DB work must run outside the test's fake clock.
    await tester.runAsync(() async {
      await container.read(authControllerProvider.future);
      await container.read(authControllerProvider.notifier).register('alice', 'secret1');
    });

    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: ProfileTab()),
    ));
    // Wait until the user row is loaded (the username shows in the AppBar).
    await pumpUntilFound(tester, find.text('alice'));

    await tester.tap(find.byTooltip('Edit profile'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextField, 'Bio'), 'Hello from the test');
    await tester.tap(find.text('Save'));
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
    // Runs the whole closing animation. With the old code this threw
    // "A TextEditingController was used after being disposed".
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsNothing);
    await pumpUntilFound(tester, find.text('Hello from the test'));
  });
}
