import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/home_screen/state/auth_controller.dart';
import 'screens/main_screen.dart';

void main() => runApp(const ProviderScope(child: MainApp()));

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: AuthGate(),
      );
}

/// Decides which screen to show based on the auth state.
/// This is the ONLY place that switches between "logged out" and "logged in",
/// so login/logout code never has to navigate anywhere.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    return auth.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(body: Center(child: Text('Error: $error'))),
      data: (user) => user == null
          ? const AuthScreen()
          // The key: a different user → a brand-new MainScreen, so tabs kept
          // alive by AnimatedIndexedStack don't show the previous user's state.
          : MainScreen(key: ValueKey(user.id)),
    );
  }
}
