import 'package:android_dev/screens/home_screen/services/auth_repository.dart';
import 'package:android_dev/screens/home_screen/state/auth_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Login AND registration on one screen, switched by [_isRegister].
///
/// Why not two screens with Navigator.push? On success, AuthGate (main.dart)
/// swaps this screen out for MainScreen. A pushed RegisterScreen route would
/// stay on top of the app. With one screen there's nothing left behind.
class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isRegister = false;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final auth = ref.read(authControllerProvider.notifier);
    try {
      if (_isRegister) {
        await auth.register(_username.text, _password.text);
      } else {
        await auth.login(_username.text, _password.text);
      }
      // Success: no navigation here. AuthGate sees the new user and swaps
      // this screen for MainScreen by itself.
    } on AuthException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _toggleMode() => setState(() {
        _isRegister = !_isRegister;
        _error = null;
        _confirm.clear();
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Instaclone',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isRegister ? 'Create an account' : 'Log in to continue',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _username,
                    autocorrect: false,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Enter a username.' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _password,
                    obscureText: true,
                    textInputAction:
                        _isRegister ? TextInputAction.next : TextInputAction.done,
                    onFieldSubmitted: _isRegister ? null : (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'Password',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter a password.' : null,
                  ),
                  if (_isRegister) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _confirm,
                      obscureText: true,
                      onFieldSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'Repeat password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v != _password.text ? 'Passwords do not match.' : null,
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : _submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(_isLoading
                          ? 'Please wait…'
                          : (_isRegister ? 'Sign up' : 'Log in')),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    child: Text(_isRegister
                        ? 'Already have an account? Log in'
                        : "Don't have an account? Sign up"),
                  ),
                  if (!_isRegister)
                    const Text(
                      'Demo accounts: aibek.travels / aizada_k, password: password',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
