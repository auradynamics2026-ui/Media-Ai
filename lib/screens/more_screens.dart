import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../services/backend.dart';
import 'widgets.dart';

/// Local state for the extra screens (demo data; swap for Supabase tables).
class Store {
  static final downloads = ValueNotifier<Set<String>>({});
  static final certDownloads = ValueNotifier<Set<String>>({});
  static final users = ValueNotifier<List<Map<String, String>>>([
    {'name': 'Ajay', 'email': 'ajay@rvce.edu.in', 'dept': 'CSE', 'year': 'III Year'},
    {'name': 'Esaimathi', 'email': 'esai@rvce.edu.in', 'dept': 'ECE', 'year': 'II Year'},
    {'name': 'Karthik', 'email': 'karthik@rvce.edu.in', 'dept': 'CSE', 'year': 'IV Year'},
  ]);
  static final achievements = ValueNotifier<List<Map<String, String>>>([
    {'title': 'Project Expo 2026', 'sub': '1st Prize - Best Project', 'date': 'Mar 12, 2026'},
    {'title': 'Fusion Fest 2026', 'sub': 'Volunteer Certificate', 'date': 'Feb 27, 2026'},
    {'title': 'Engineers Day', 'sub': '3rd Prize - Debugging', 'date': 'Sep 15, 2026'},
  ]);
  static final assigned = <String, Set<String>>{};
}

Future<List<Photo>> _allPhotos() async {
  final r = <Photo>[];
  for (final e in await Backend.i.events()) {
    r.addAll(await Backend.i.photos(e.id));
  }
  return r;
}

void snack(BuildContext c, String m) =>
    ScaffoldMessenger.of(c).showSnackBar(SnackBar(content: Text(m)));

Widget _futureBody<T>(Future<T> f, Widget Function(T) build) => FutureBuilder<T>(
      future: f,
      builder: (_, s) {
        if (s.hasError) return const Center(child: Text('Something went wrong'));
        if (!s.hasData) return const Center(child: CircularProgressIndicator());
        return build(s.data as T);
      },
    );

// ---- 9. AI Enhancer ----
class EnhancerScreen extends StatefulWidget {
  final Photo? photo;
  const EnhancerScreen({super.key, this.photo});
  @override
  State<EnhancerScreen> createState() => _EnhancerState();
}

class _EnhancerState extends State<EnhancerScreen> {
  double _s = .5;
  bool _auto = true, _blur = false, _light = true, _color = false, _busy = false, _done = false;

  ColorFilter get _filter {
    final c = 1 + _s * (_light ? .4 : .1), sat = 1 + _s * (_color ? .8 : .3);
    const lr = .2126, lg = .7152, lb = .0722;
    final a = (1 - sat) * lr, b = (1 - sat) * lg, d = (1 - sat) * lb;
    return ColorFilter.matrix([
      c * (a + sat), c * b, c * d, 0, 0,
      c * a, c * (b + sat), c * d, 0, 0,
      c * a, c * b, c * (d + sat), 0, 0,
      0, 0, 0, 1, 0,
    ]);
  }

  Future<void> _run() async {
    setState(() => _busy = true);
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) setState(() { _busy = false; _done = true; });
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.photo ?? Photo('sample-enhance', '');
    return Scaffold(
      appBar: AppBar(title: const Text('AI Photo Enhancer')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        SizedBox(
          height: 240,
          child: Row(children: [
            Expanded(child: PhotoTile(photo: p, onTap: () {})),
            const SizedBox(width: 8),
            Expanded(child: ColorFiltered(colorFilter: _done ? _filter : const ColorFilter.mode(Colors.transparent, BlendMode.dst), child: PhotoTile(photo: p, onTap: () {}))),
          ]),
        ),
        const Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [Text('Before'), Text('After')]),
        const SizedBox(height: 12),
        const Text('Enhancement Strength'),
        Slider(value: _s, onChanged: (v) => setState(() => _s = v)),
        CheckboxListTile(value: _auto, onChanged: (v) => setState(() => _auto = v!), title: const Text('Auto Enhance')),
        CheckboxListTile(value: _blur, onChanged: (v) => setState(() => _blur = v!), title: const Text('Remove Blur')),
        CheckboxListTile(value: _light, onChanged: (v) => setState(() => _light = v!), title: const Text('Improve Lighting')),
        CheckboxListTile(value: _color, onChanged: (v) => setState(() => _color = v!), title: const Text('Enhance Colors')),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _busy ? null : _run, child: Text(_busy ? 'Enhancing...' : 'ENHANCE PHOTO')),
      ]),
    );
  }
}

// ---- 10. My Photos ----
class MyPhotosScreen extends StatelessWidget {
  const MyPhotosScreen({super.key});
  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 3,
        child: Scaffold(
          appBar: AppBar(
              title: const Text('My Photos'),
              bottom: const TabBar(tabs: [Tab(text: 'All'), Tab(text: 'Favorites'), Tab(text: 'Downloads')])),
          body: _futureBody<List<Photo>>(
            _allPhotos(),
            (all) => ListenableBuilder(
              listenable: Listenable.merge([Backend.i.favorites, Store.downloads]),
              builder: (_, __) => TabBarView(children: [
                PhotoGrid(all),
                PhotoGrid(all.where((p) => Backend.i.favorites.value.contains(p.id)).toList()),
                PhotoGrid(all.where((p) => Store.downloads.value.contains(p.id)).toList()),
              ]),
            ),
          ),
        ),
      );
}

// ---- 11. Achievements ----
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('My Achievements')),
        body: ValueListenableBuilder<List<Map<String, String>>>(
          valueListenable: Store.achievements,
          builder: (_, list, __) => list.isEmpty
              ? const Center(child: Text('No achievements yet'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => CardBox(
                    child: Row(children: [
                      const Icon(Icons.workspace_premium, size: 36, color: Colors.amber),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(list[i]['title']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(list[i]['sub']!, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        Text(list[i]['date']!, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                      ])),
                      IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () {
                          Store.certDownloads.value = {...Store.certDownloads.value, list[i]['title']!};
                          snack(context, 'Certificate saved to Downloads');
                        },
                      ),
                    ]),
                  ),
                ),
        ),
      );
}

// ---- 12. Downloads ----
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});
  Widget _list(ValueNotifier<Set<String>> n, IconData icon) => ValueListenableBuilder<Set<String>>(
        valueListenable: n,
        builder: (_, s, __) => s.isEmpty
            ? const Center(child: Text('Nothing downloaded yet'))
            : ListView(children: [
                for (final id in s)
                  ListTile(
                    leading: Icon(icon),
                    title: Text(id),
                    trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => n.value = {...s}..remove(id)),
                  ),
              ]),
      );

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(title: const Text('Downloads'), bottom: const TabBar(tabs: [Tab(text: 'Photos'), Tab(text: 'Certificates')])),
          body: TabBarView(children: [_list(Store.downloads, Icons.image), _list(Store.certDownloads, Icons.workspace_premium)]),
        ),
      );
}

// ---- 16. Users list ----
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});
  @override
  State<UsersScreen> createState() => _UsersState();
}

class _UsersState extends State<UsersScreen> {
  String _q = '';
  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Users'), actions: [
          TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddUserScreen())),
              icon: const Icon(Icons.add),
              label: const Text('Add User')),
        ]),
        body: Column(children: [
          Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                  decoration: const InputDecoration(hintText: 'Search users...', prefixIcon: Icon(Icons.search)),
                  onChanged: (v) => setState(() => _q = v.toLowerCase()))),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, String>>>(
              valueListenable: Store.users,
              builder: (_, all, __) {
                final l = all.where((u) => u['name']!.toLowerCase().contains(_q)).toList();
                if (l.isEmpty) return const Center(child: Text('No users found'));
                return ListView(children: [
                  for (final u in l)
                    ListTile(
                      leading: CircleAvatar(child: Text(u['name']![0])),
                      title: Text(u['name']!),
                      subtitle: Text('${u['email']} · ${Store.assigned[u['email']]?.length ?? 0} photos'),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'assign') {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ManualAssignScreen(user: u)));
                          } else {
                            Store.users.value = [...all]..remove(u);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'assign', child: Text('Assign photos')),
                          PopupMenuItem(value: 'delete', child: Text('Delete')),
                        ],
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]),
      );
}

// ---- 17. Add user ----
class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});
  @override
  State<AddUserScreen> createState() => _AddUserState();
}

class _AddUserState extends State<AddUserScreen> {
  final _f = GlobalKey<FormState>();
  final _n = TextEditingController(), _e = TextEditingController();
  String _dept = 'CSE', _year = 'I Year';

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add User Manually')),
        body: Form(
          key: _f,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            TextFormField(controller: _n, decoration: const InputDecoration(labelText: 'Name'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _e, decoration: const InputDecoration(labelText: 'Email'), validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v ?? '') ? null : 'Invalid email'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _dept, items: ['CSE', 'ECE', 'EEE', 'MECH', 'IT'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => _dept = v!, decoration: const InputDecoration(labelText: 'Department')),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(value: _year, items: ['I Year', 'II Year', 'III Year', 'IV Year'].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(), onChanged: (v) => _year = v!, decoration: const InputDecoration(labelText: 'Year')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_f.currentState!.validate()) return;
                Store.users.value = [...Store.users.value, {'name': _n.text.trim(), 'email': _e.text.trim(), 'dept': _dept, 'year': _year}];
                Navigator.pop(context);
              },
              child: const Text('SAVE USER'),
            ),
          ]),
        ),
      );
}

// ---- 18. Manual assign ----
class ManualAssignScreen extends StatefulWidget {
  final Map<String, String> user;
  const ManualAssignScreen({super.key, required this.user});
  @override
  State<ManualAssignScreen> createState() => _AssignState();
}

class _AssignState extends State<ManualAssignScreen> {
  final _sel = <String>{};
  EventItem? _ev;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: Text('Assign Photos to ${widget.user['name']}')),
        body: _futureBody<List<EventItem>>(
          Backend.i.events(),
          (evs) {
            _ev ??= evs.isEmpty ? null : evs.first;
            return Column(children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: DropdownButtonFormField<EventItem>(
                  value: _ev,
                  items: evs.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(),
                  onChanged: (v) => setState(() => _ev = v),
                ),
              ),
              Expanded(
                child: _ev == null
                    ? const Center(child: Text('No events'))
                    : _futureBody<List<Photo>>(
                        Backend.i.photos(_ev!.id),
                        (ps) => GridView.builder(
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(maxCrossAxisExtent: 110, mainAxisSpacing: 6, crossAxisSpacing: 6),
                          itemCount: ps.length,
                          itemBuilder: (_, i) => Stack(fit: StackFit.expand, children: [
                            PhotoTile(photo: ps[i], onTap: () => setState(() => _sel.contains(ps[i].id) ? _sel.remove(ps[i].id) : _sel.add(ps[i].id))),
                            if (_sel.contains(ps[i].id)) const IgnorePointer(child: Center(child: Icon(Icons.check_circle, color: Colors.greenAccent, size: 34))),
                          ]),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: ElevatedButton(
                  onPressed: _sel.isEmpty
                      ? null
                      : () {
                          (Store.assigned[widget.user['email']!] ??= {}).addAll(_sel);
                          snack(context, 'Assigned ${_sel.length} photos');
                          Navigator.pop(context);
                        },
                  child: Text('Assign to ${widget.user['name']} (${_sel.length} photos)'),
                ),
              ),
            ]);
          },
        ),
      );
}

// ---- 19. Upload photos (admin) ----
class UploadPhotosScreen extends StatefulWidget {
  const UploadPhotosScreen({super.key});
  @override
  State<UploadPhotosScreen> createState() => _UploadState();
}

class _UploadState extends State<UploadPhotosScreen> {
  List<XFile> _files = [];
  EventItem? _ev;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Upload Event Photos')),
        body: _futureBody<List<EventItem>>(
          Backend.i.events(),
          (evs) {
            _ev ??= evs.isEmpty ? null : evs.first;
            return ListView(padding: const EdgeInsets.all(16), children: [
              DropdownButtonFormField<EventItem>(value: _ev, items: evs.map((e) => DropdownMenuItem(value: e, child: Text(e.name))).toList(), onChanged: (v) => setState(() => _ev = v), decoration: const InputDecoration(labelText: 'Select Event')),
              const SizedBox(height: 16),
              CardBox(
                onTap: () async {
                  final f = await ImagePicker().pickMultiImage(imageQuality: 85);
                  if (f.isNotEmpty) setState(() => _files = f);
                },
                child: Center(child: Text(_files.isEmpty ? 'Choose Photos\nSelect multiple photos' : '${_files.length} photos selected', textAlign: TextAlign.center)),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: (_files.isEmpty || _ev == null)
                    ? null
                    : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => AiProcessingScreen(event: _ev!.name, total: _files.length))),
                child: const Text('UPLOAD PHOTOS'),
              ),
            ]);
          },
        ),
      );
}

// ---- 20. AI processing ----
class AiProcessingScreen extends StatefulWidget {
  final String event;
  final int total;
  const AiProcessingScreen({super.key, this.event = 'All events', this.total = 500});
  @override
  State<AiProcessingScreen> createState() => _ProcState();
}

class _ProcState extends State<AiProcessingScreen> {
  double _p = 0;
  @override
  void initState() {
    super.initState();
    _tick();
  }

  Future<void> _tick() async {
    while (mounted && _p < 1) {
      await Future.delayed(const Duration(milliseconds: 150));
      if (mounted) setState(() => _p = (_p + .04).clamp(0, 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    final steps = ['Uploading photos...', 'Processing images...', 'Detecting faces...', 'Matching users...'];
    final t = widget.total;
    return Scaffold(
      appBar: AppBar(title: Text('AI Processing · ${widget.event}')),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        for (var i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(steps[i]),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: (_p * 4 - i).clamp(0, 1).toDouble()),
            ]),
          ),
        CardBox(child: Text('Photos processed: ${(t * _p).round()}\nFaces detected: ${(t * 2.4 * _p).round()}\nMatched: ${(t * .86 * _p).round()}\nNeeds review: ${(t * .04 * _p).round()}')),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _p < 1 ? null : () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ReviewMatchesScreen())),
          child: const Text('VIEW RESULTS'),
        ),
      ]),
    );
  }
}

// ---- 21. Review matches ----
class ReviewMatchesScreen extends StatefulWidget {
  const ReviewMatchesScreen({super.key});
  @override
  State<ReviewMatchesScreen> createState() => _ReviewState();
}

class _ReviewState extends State<ReviewMatchesScreen> {
  final _items = [
    {'id': 'review-1', 'user': 'Ajay', 'conf': '68'},
    {'id': 'review-2', 'user': 'Karthik', 'conf': '61'},
    {'id': 'review-3', 'user': 'Esaimathi', 'conf': '72'},
  ];

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Review AI Matches')),
        body: _items.isEmpty
            ? const Center(child: Text('All matches reviewed ✓'))
            : ListView(padding: const EdgeInsets.all(16), children: [
                for (final m in List.of(_items))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: CardBox(
                      child: Row(children: [
                        SizedBox(width: 90, height: 90, child: PhotoTile(photo: Photo(m['id']!, ''), onTap: () {})),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Detected: ${m['user']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text('Confidence: ${m['conf']}%', style: const TextStyle(color: Colors.white70)),
                          Row(children: [
                            TextButton(onPressed: () { setState(() => _items.remove(m)); snack(context, 'Approved'); }, child: const Text('Approve')),
                            TextButton(onPressed: () { setState(() => _items.remove(m)); snack(context, 'Rejected'); }, child: const Text('Reject', style: TextStyle(color: Colors.redAccent))),
                          ]),
                        ])),
                      ]),
                    ),
                  ),
              ]),
      );
}

// ---- 23. Manage achievements ----
class ManageAchievementsScreen extends StatefulWidget {
  const ManageAchievementsScreen({super.key});
  @override
  State<ManageAchievementsScreen> createState() => _ManageAchState();
}

class _ManageAchState extends State<ManageAchievementsScreen> {
  final _f = GlobalKey<FormState>();
  final _t = TextEditingController(), _ev = TextEditingController(), _d = TextEditingController();
  String? _student;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Add Achievement')),
        body: Form(
          key: _f,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            DropdownButtonFormField<String>(
              value: _student,
              hint: const Text('Select Student'),
              items: Store.users.value.map((u) => DropdownMenuItem(value: u['name'], child: Text(u['name']!))).toList(),
              onChanged: (v) => _student = v,
              validator: (v) => v == null ? 'Select a student' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(controller: _t, decoration: const InputDecoration(labelText: 'Achievement Title'), validator: (v) => (v ?? '').trim().isEmpty ? 'Required' : null),
            const SizedBox(height: 12),
            TextFormField(controller: _ev, decoration: const InputDecoration(labelText: 'Event')),
            const SizedBox(height: 12),
            TextFormField(controller: _d, decoration: const InputDecoration(labelText: 'Date (e.g. Mar 12, 2026)')),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (!_f.currentState!.validate()) return;
                Store.achievements.value = [
                  {'title': _ev.text.isEmpty ? _t.text : _ev.text, 'sub': '${_t.text} · $_student', 'date': _d.text},
                  ...Store.achievements.value,
                ];
                snack(context, 'Achievement saved');
                Navigator.pop(context);
              },
              child: const Text('SAVE ACHIEVEMENT'),
            ),
          ]),
        ),
      );
}

Future<void> shareLink(BuildContext c, Photo p) async {
  await Clipboard.setData(ClipboardData(text: p.url.isEmpty ? 'mediaai://photo/${p.id}' : p.url));
  if (c.mounted) snack(c, 'Link copied to clipboard');
}
