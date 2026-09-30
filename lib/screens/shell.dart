import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../services/backend.dart';
import 'face_profile_screen.dart';
import 'login_screen.dart';
import 'more_screens.dart';
import 'widgets.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    final tabs = <Widget>[
      _Home(onGo: (i) => setState(() => _tab = i)),
      const _Events(),
      const _Favorites(),
      const _Profile(),
    ];
    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: KeyedSubtree(key: ValueKey(_tab), child: tabs[_tab]),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppColors.card,
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.calendar_month_outlined), label: 'Events'),
          NavigationDestination(icon: Icon(Icons.favorite_border), label: 'Favorites'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

void _push(BuildContext c, Widget w) => Navigator.push(c, MaterialPageRoute(builder: (_) => w));
void _openFace(BuildContext c) =>
    Navigator.push(c, MaterialPageRoute(builder: (_) => const FaceProfileScreen()));

class _Home extends StatelessWidget {
  final void Function(int) onGo;
  const _Home({required this.onGo});
  @override
  Widget build(BuildContext context) {
    final name = (Backend.i.email ?? '').split('@').first;
    Widget tool(IconData i, String t, VoidCallback f) => CardBox(
        onTap: f,
        child: Row(children: [Icon(i, color: AppColors.accent), const SizedBox(width: 10), Text(t)]));
    return ListView(padding: const EdgeInsets.all(20), children: [
      Text('Hello, $name 👋', style: const TextStyle(color: Colors.white70)),
      const Text('Your Media Space', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
      const SizedBox(height: 16),
      CardBox(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('AI Photo Match', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text("Upload one reference photo and we'll find your event photos automatically.",
              style: TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 12),
          ElevatedButton(onPressed: () => _openFace(context), child: const Text('SET FACE PROFILE')),
        ]),
      ),
      const SizedBox(height: 20),
      const Text('Quick Tools', style: TextStyle(fontWeight: FontWeight.bold)),
      const SizedBox(height: 10),
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.6,
        children: [
          tool(Icons.event, 'My Events', () => onGo(1)),
          tool(Icons.favorite, 'Favorites', () => onGo(2)),
          tool(Icons.face, 'Face Profile', () => _openFace(context)),
          tool(Icons.person, 'Profile', () => onGo(3)),
          tool(Icons.auto_fix_high, 'AI Enhancer', () => _push(context, const EnhancerScreen())),
          tool(Icons.photo_library, 'My Photos', () => _push(context, const MyPhotosScreen())),
          tool(Icons.emoji_events, 'Achievements', () => _push(context, const AchievementsScreen())),
          tool(Icons.download, 'Downloads', () => _push(context, const DownloadsScreen())),
        ],
      ),
    ]);
  }
}

class _Events extends StatefulWidget {
  const _Events();
  @override
  State<_Events> createState() => _EventsState();
}

class _EventsState extends State<_Events> {
  late Future<List<EventItem>> _f = Backend.i.events();
  String _q = '';

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          TextField(
            decoration: const InputDecoration(
                hintText: 'Search events...', prefixIcon: Icon(Icons.search)),
            onChanged: (v) => setState(() => _q = v.toLowerCase()),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: FutureBuilder<List<EventItem>>(
              future: _f,
              builder: (_, s) {
                if (s.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (s.hasError) {
                  return Center(
                      child: TextButton(
                          onPressed: () => setState(() => _f = Backend.i.events()),
                          child: const Text('Error - tap to retry')));
                }
                final list = s.data!.where((e) => e.name.toLowerCase().contains(_q)).toList();
                if (list.isEmpty) return const Center(child: Text('No events found'));
                return ListView.separated(
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => CardBox(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EventPhotosScreen(event: list[i]))),
                    child: Row(children: [
                      Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(list[i].name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('${list[i].date} · ${list[i].count} photos',
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ])),
                      const Icon(Icons.chevron_right),
                    ]),
                  ),
                );
              },
            ),
          ),
        ]),
      );
}

class EventPhotosScreen extends StatelessWidget {
  final EventItem event;
  const EventPhotosScreen({super.key, required this.event});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text(event.name)),
        body: FutureBuilder<List<Photo>>(
          future: Backend.i.photos(event.id),
          builder: (_, s) {
            if (s.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (s.hasError) return const Center(child: Text('Could not load photos'));
            return PhotoGrid(s.data!);
          },
        ),
      );
}

class _Favorites extends StatelessWidget {
  const _Favorites();
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
        valueListenable: Backend.i.favorites,
        builder: (_, favs, __) {
          final photos = favs.map((id) => Backend.i.photoCache[id]).whereType<Photo>().toList();
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Favorites ❤️', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
            Expanded(
                child: photos.isEmpty
                    ? const Center(child: Text('Tap ♥ on a photo to save it here'))
                    : PhotoGrid(photos)),
          ]);
        },
      );
}

class _Profile extends StatelessWidget {
  const _Profile();
  @override
  Widget build(BuildContext context) => ListView(padding: const EdgeInsets.all(20), children: [
        const Center(child: CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40))),
        const SizedBox(height: 10),
        Center(child: Text(Backend.i.email ?? '')),
        const SizedBox(height: 20),
        ListTile(
            leading: const Icon(Icons.face),
            title: const Text('My Face Profile'),
            onTap: () => _openFace(context)),
        ListTile(leading: const Icon(Icons.photo_library), title: const Text('My Photos'), onTap: () => _push(context, const MyPhotosScreen())),
        ListTile(leading: const Icon(Icons.emoji_events), title: const Text('My Achievements'), onTap: () => _push(context, const AchievementsScreen())),
        ListTile(leading: const Icon(Icons.download), title: const Text('Downloads'), onTap: () => _push(context, const DownloadsScreen())),
        ListTile(leading: const Icon(Icons.auto_fix_high), title: const Text('AI Enhancer'), onTap: () => _push(context, const EnhancerScreen())),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.redAccent),
          title: const Text('Logout', style: TextStyle(color: Colors.redAccent)),
          onTap: () async {
            await Backend.i.signOut();
            if (context.mounted) {
              Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
            }
          },
        ),
      ]);
}
