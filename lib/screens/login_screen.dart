import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/backend.dart';
import 'admin_screens.dart';
import 'shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _loading = false, _signUp = false;
  String? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Backend.i.signIn(_email.text.trim(), _pass.text, signUp: _signUp);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Shell()));
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Form(
                  key: _form,
                  child: Column(children: [
                    const Text.rich(
                        TextSpan(children: [
                          TextSpan(text: 'MEDIA '),
                          TextSpan(text: 'AI', style: TextStyle(color: AppColors.accent)),
                        ]),
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    const Text('Your photos. Automatically.',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    const Text('AI-powered event photo community',
                        style: TextStyle(color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(labelText: 'College Gmail'),
                      validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '')
                          ? null
                          : 'Enter a valid email',
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _pass,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password'),
                      validator: (v) => (v ?? '').length >= 6 ? null : 'Min 6 characters',
                    ),
                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(_error!, style: const TextStyle(color: Colors.redAccent)),
                      ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      child: _loading
                          ? const SizedBox(
                              width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Text(_signUp ? 'CREATE ACCOUNT' : 'CONTINUE WITH EMAIL'),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _signUp = !_signUp),
                      child: Text(_signUp ? 'Have an account? Sign in' : 'New here? Create account'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(
                          context, MaterialPageRoute(builder: (_) => const AdminLogin())),
                      child: const Text('Admin / Media Team'),
                    ),
                  ]),
                ),
              ),
            ),
          ),
        ),
      );
}
