import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EventItem {
  final String id, name, date;
  final int count;
  EventItem(this.id, this.name, this.date, this.count);
}

class Photo {
  final String id, url;
  Photo(this.id, this.url);
}

/// Uses Supabase when SUPABASE_URL / SUPABASE_ANON_KEY are passed via
/// --dart-define; otherwise runs in offline demo mode.
class Backend {
  static final Backend i = Backend._();
  Backend._();

  bool live = false;
  String? _demoEmail;
  final favorites = ValueNotifier<Set<String>>({});
  final photoCache = <String, Photo>{};
  final _demoEvents = <EventItem>[
    EventItem('e1', 'Fusion Fest 2026', '2026-02-27', 84),
    EventItem('e2', 'Project Expo 2026', '2026-03-12', 37),
    EventItem('e3', 'Sports Day', '2026-03-22', 16),
    EventItem('e4', 'Engineers Day', '2026-09-15', 52),
  ];

  SupabaseClient get _c => Supabase.instance.client;

  Future<void> init() async {
    const url = String.fromEnvironment('SUPABASE_URL');
    const key = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isNotEmpty && key.isNotEmpty) {
      await Supabase.initialize(url: url, anonKey: key);
      live = true;
    }
  }

  String? get email => live ? _c.auth.currentUser?.email : _demoEmail;

  Future<void> signIn(String e, String p, {bool signUp = false}) async {
    if (!live) {
      _demoEmail = e;
      return;
    }
    if (signUp) {
      await _c.auth.signUp(email: e, password: p);
    } else {
      await _c.auth.signInWithPassword(email: e, password: p);
    }
  }

  Future<void> signOut() async {
    _demoEmail = null;
    if (live) await _c.auth.signOut();
  }

  Future<bool> isAdmin() async {
    if (!live) return _demoEmail == 'admin@rvce.edu.in';
    final uid = _c.auth.currentUser?.id;
    if (uid == null) return false;
    final r = await _c.from('profiles').select('role').eq('id', uid).maybeSingle();
    return r?['role'] == 'admin';
  }

  Future<List<EventItem>> events() async {
    if (!live) return List.of(_demoEvents);
    final r = await _c.from('events').select().order('event_date', ascending: false);
    return (r as List)
        .map((e) => EventItem(e['id'].toString(), e['name'] as String,
            e['event_date'].toString(), (e['photo_count'] ?? 0) as int))
        .toList();
  }

  Future<List<Photo>> photos(String eventId) async {
    List<Photo> list;
    if (!live) {
      await Future.delayed(const Duration(milliseconds: 400));
      list = List.generate(12, (i) => Photo('$eventId-$i', ''));
    } else {
      final r = await _c.from('photos').select().eq('event_id', eventId);
      list = (r as List).map((p) => Photo(p['id'].toString(), p['url'] as String)).toList();
    }
    for (final p in list) {
      photoCache[p.id] = p;
    }
    return list;
  }

  Future<void> toggleFavorite(String photoId) async {
    final s = Set<String>.from(favorites.value);
    final adding = s.add(photoId);
    if (!adding) s.remove(photoId);
    favorites.value = s;
    if (!live) return;
    try {
      final uid = _c.auth.currentUser!.id;
      if (adding) {
        await _c.from('favorites').insert({'user_id': uid, 'photo_id': photoId});
      } else {
        await _c.from('favorites').delete().eq('user_id', uid).eq('photo_id', photoId);
      }
    } catch (_) {}
  }

  Future<void> createEvent(String name, String date) async {
    if (live) {
      await _c.from('events').insert({'name': name, 'event_date': date});
    } else {
      _demoEvents.insert(0, EventItem('e${_demoEvents.length + 1}', name, date, 0));
    }
  }

  Future<Map<String, int>> stats() async {
    final ev = await events();
    return {'Events': ev.length, 'Photos': ev.fold(0, (a, e) => a + e.count)};
  }
}
