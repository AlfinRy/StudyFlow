import '../domain/schedule.dart';

/// Parser iCalendar (.ics) sederhana → daftar [Schedule] mingguan
/// (FEATURE_ROADMAP #5). Murni Dart (tanpa Flutter/IO) agar mudah diuji
/// (lihat `test/ical_parser_test.dart`).
///
/// Karena jadwal StudyFlow bersifat mingguan (`dayOfWeek` + jam), tiap VEVENT
/// dipetakan menjadi satu/lebih slot mingguan:
/// - `SUMMARY` → judul; `LOCATION` → lokasi.
/// - `DTSTART`/`DTEND` → jam mulai/selesai (HH:mm). Zona waktu diabaikan.
/// - Event seharian (tanpa jam / `VALUE=DATE`) dilewati.
/// - `RRULE:FREQ=WEEKLY;BYDAY=MO,WE,FR` diekspansi ke beberapa hari; bila tak
///   ada RRULE, dipakai weekday dari tanggal `DTSTART`.
///
/// Keterbatasan disengaja (lingkup akademik): COUNT/UNTIL/EXDATE diabaikan,
/// FREQ selain WEEKLY memakai weekday DTSTART, dedup internal per
/// (judul, hari, jam mulai).
List<Schedule> parseIcsToSchedules(String content) {
  final events = _extractEvents(_unfold(content));
  final seen = <String>{};
  final out = <Schedule>[];

  for (final ev in events) {
    final summary = _unescape(ev['SUMMARY']?.value.trim() ?? '');
    if (summary.isEmpty) continue;
    final dtStart = ev['DTSTART'];
    if (dtStart == null) continue;

    // Lewati event seharian (tanpa komponen waktu).
    final isDateOnly = dtStart.params['VALUE']?.toUpperCase() == 'DATE' ||
        !dtStart.value.contains('T');
    if (isDateOnly) continue;

    final start = _hhmm(dtStart.value);
    if (start == null) continue;
    final end = _hhmm(ev['DTEND']?.value ?? '') ?? _plusOneHour(start);

    // Hari: ekspansi RRULE BYDAY, atau weekday dari tanggal DTSTART.
    var days = const <int>[];
    final rrule = ev['RRULE']?.value;
    if (rrule != null && rrule.isNotEmpty) days = _byDays(rrule);
    if (days.isEmpty) {
      final wd = _weekday(dtStart.value);
      if (wd != null) days = [wd];
    }

    final loc = _unescape(ev['LOCATION']?.value.trim() ?? '');
    for (final d in days) {
      final key = '$summary|$d|$start';
      if (!seen.add(key)) continue; // dedup internal
      out.add(Schedule(
        id: '',
        title: summary,
        dayOfWeek: d,
        startTime: start,
        endTime: end,
        location: loc.isEmpty ? null : loc,
      ));
    }
  }
  return out;
}

/// Properti .ics terurai: nama, parameter (cth. TZID/VALUE), nilai.
class _Prop {
  const _Prop(this.name, this.params, this.value);
  final String name;
  final Map<String, String> params;
  final String value;
}

const _dayCodes = <String, int>{
  'MO': 1,
  'TU': 2,
  'WE': 3,
  'TH': 4,
  'FR': 5,
  'SA': 6,
  'SU': 7,
};

/// Gabung baris yang dilipat (RFC 5545): baris diawali spasi/tab adalah
/// kelanjutan baris sebelumnya.
List<String> _unfold(String content) {
  final raw = content
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n')
      .split('\n');
  final out = <String>[];
  for (final line in raw) {
    if (line.isEmpty) continue;
    if (line.startsWith(' ') || line.startsWith('\t')) {
      if (out.isNotEmpty) out[out.length - 1] += line.substring(1);
    } else {
      out.add(line);
    }
  }
  return out;
}

/// Ekstrak tiap VEVENT menjadi map nama-properti → [_Prop] (ambil kemunculan
/// pertama per nama).
List<Map<String, _Prop>> _extractEvents(List<String> lines) {
  final events = <Map<String, _Prop>>[];
  Map<String, _Prop>? cur;
  for (final line in lines) {
    if (line == 'BEGIN:VEVENT') {
      cur = {};
    } else if (line == 'END:VEVENT') {
      if (cur != null && cur.isNotEmpty) events.add(cur);
      cur = null;
    } else if (cur != null) {
      final p = _parseLine(line);
      if (p != null && !cur.containsKey(p.name)) cur[p.name] = p;
    }
  }
  return events;
}

/// Urai satu baris properti "NAME;PARAM=val:value".
_Prop? _parseLine(String line) {
  final colon = line.indexOf(':');
  if (colon <= 0) return null;
  final head = line.substring(0, colon);
  final value = line.substring(colon + 1);
  final parts = head.split(';');
  final name = parts.first.toUpperCase();
  final params = <String, String>{};
  for (var i = 1; i < parts.length; i++) {
    final eq = parts[i].indexOf('=');
    if (eq > 0) {
      params[parts[i].substring(0, eq).toUpperCase()] =
          parts[i].substring(eq + 1);
    }
  }
  return _Prop(name, params, value);
}

/// Ambil "HH:mm" dari nilai tanggal-waktu (abaikan zona waktu / sufiks 'Z').
String? _hhmm(String value) {
  final t = value.indexOf('T');
  if (t < 0 || value.length < t + 5) return null;
  final hh = value.substring(t + 1, t + 3);
  final mm = value.substring(t + 3, t + 5);
  if (int.tryParse(hh) == null || int.tryParse(mm) == null) return null;
  return '$hh:$mm';
}

/// Weekday (1=Senin..7=Minggu) dari tanggal pada nilai DTSTART.
int? _weekday(String value) {
  final t = value.indexOf('T');
  final date = t < 0 ? value : value.substring(0, t);
  if (date.length < 8) return null;
  final y = int.tryParse(date.substring(0, 4));
  final m = int.tryParse(date.substring(4, 6));
  final d = int.tryParse(date.substring(6, 8));
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d).weekday;
}

/// Ekspansi `FREQ=WEEKLY;BYDAY=MO,WE,...` → daftar weekday. Bila bukan WEEKLY
/// atau tanpa BYDAY → kosong (pemanggil mundur ke weekday DTSTART).
List<int> _byDays(String rrule) {
  String? freq;
  String? byday;
  for (final part in rrule.split(';')) {
    final eq = part.indexOf('=');
    if (eq <= 0) continue;
    final k = part.substring(0, eq).toUpperCase();
    final v = part.substring(eq + 1).toUpperCase();
    if (k == 'FREQ') freq = v;
    if (k == 'BYDAY') byday = v;
  }
  if (freq != 'WEEKLY' || byday == null) return const [];
  final days = <int>[];
  for (final token in byday.split(',')) {
    // BYDAY boleh diawali angka (cth. "2MO") — buang digit.
    final code = token.replaceAll(RegExp(r'\d'), '');
    final d = _dayCodes[code];
    if (d != null) days.add(d);
  }
  return days;
}

String _plusOneHour(String hhmm) {
  final parts = hhmm.split(':');
  final h = int.tryParse(parts.first) ?? 0;
  final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
  final dt = DateTime(2026, 1, 1, h, m).add(const Duration(hours: 1));
  final hh = dt.hour.toString().padLeft(2, '0');
  final mm = dt.minute.toString().padLeft(2, '0');
  return '$hh:$mm';
}

/// Lepaskan escape teks iCalendar (\, \; \\ \n).
String _unescape(String s) => s
    .replaceAll(r'\n', ' ')
    .replaceAll(r'\,', ',')
    .replaceAll(r'\;', ';')
    .replaceAll(r'\\', r'\')
    .trim();
