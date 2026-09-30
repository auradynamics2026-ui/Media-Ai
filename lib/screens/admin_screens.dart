import 'package:flutter/material.dart';
import '../services/backend.dart';
import 'more_screens.dart';
import 'widgets.dart';

class AdminLogin extends StatefulWidget {
  const AdminLogin({super.key});
  @override
  State<AdminLogin> createState() => _AdminLoginState();
}

class _AdminLoginState extends State<AdminLogin> {
  final _e = TextEditingController(), _p = TextEditingController();
  bool _busy = false;
  String? _err;

  Future<void> _login() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    try {
      if (!Backend.i.live && !(_e.text.trim() == 'admin@rvce.edu.in' && _p.text == 'admin123')) {
        throw 'Demo admin: admin@rvce.edu.in / admin123';
      }
      await Backend.i.signIn(_e.text.trim(), _p.text);
      if (!await Backend.i.isAdmin()) throw 'Not an admin account';
      if (mounted) {
        Navigator.pushReplacement(
            context, MaterialPageRoute(builder: (_) => const AdminDashboard()));
      }
    } catch (e) {
      if (mounted) setState(() => _err = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Media Team')),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            TextField(controller: _e, decoration: const InputDecoration(labelText: 'Email')),
            const SizedBox(height: 12),
            TextField(
                controller: _p,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password')),
            if (_err != null)
              Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(_err!, style: const TextStyle(color: Colors.redAccent))),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _busy ? null : _login, child: const Text('LOGIN')),
          ]),
        ),
      );
}

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});
  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  late Future<Map<String, int>> _stats = Backend.i.stats();

  Future<void> _createEvent() async {
    final name = TextEditingController();
    final date = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Create Event'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: name, decoration: const InputDecoration(labelText: 'Event name')),
          const SizedBox(height: 8),
          TextField(controller: date, decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    if (ok == true && name.text.trim().isNotEmpty) {
      await Backend.i.createEvent(name.text.trim(), date.text.trim());
      setState(() => _stats = Backend.i.stats());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Admin Dashboard')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(children: [
            FutureBuilder<Map<String, int>>(
              future: _stats,
              builder: (_, s) => s.hasData
                  ? Row(children: [
                      for (final e in s.data!.entries)
                        Expanded(
                            child: Padding(
                                padding: const EdgeInsets.all(4),
                                child: CardBox(
                                    child: Column(children: [
                                  Text('${e.value}',
                                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                                  Text(e.key),
                                ])))),
                    ])
                  : const CircularProgressIndicator(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
                onPressed: _createEvent,
                icon: const Icon(Icons.add),
                label: const Text('Create Event')),
            ...[
              ['Upload Photos', const UploadPhotosScreen()],
              ['AI Processing', const AiProcessingScreen()],
              ['Review Matches', const ReviewMatchesScreen()],
              ['Users', const UsersScreen()],
              ['Manage Achievements', const ManageAchievementsScreen()],
            ].map((x) => Padding(
                padding: const EdgeInsets.only(top: 10),
                child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => x[1] as Widget)),
                    child: Text(x[0] as String)))),
          ]),
        ),
      );
}
