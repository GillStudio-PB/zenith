import 'dart:convert';
import 'dart:async';
import 'package:hive_flutter/hive_flutter.dart';
import 'models.dart';

// This service manages the local database using Hive for storing various entities like transactions, attendances, goals, loans, users, notes, documents, driver trips, and traffic fines. It provides methods to read, write, and watch changes in these entities.
class DatabaseService {
  late Box<String> _transactionsBox;
  late Box<String> _attendancesBox;
  late Box<String> _goalsBox;
  late Box<String> _loansBox;
  late Box<String> _usersBox;
  late Box<String> _notesBox;
  late Box<String> _documentsBox;
  late Box<String> _driverTripsBox;
  late Box<String> _finesBox;

  final _transactionsStream =
      StreamController<List<AppTransaction>>.broadcast();
  final _attendancesStream = StreamController<List<Attendance>>.broadcast();
  final _goalsStream = StreamController<List<Goal>>.broadcast();
  final _loansStream = StreamController<List<Loan>>.broadcast();
  final _usersStream = StreamController<List<User>>.broadcast();
  final _notesStream = StreamController<List<NoteItem>>.broadcast();
  final _documentsStream = StreamController<List<DocumentItem>>.broadcast();
  final _driverTripsStream = StreamController<List<DriverTrip>>.broadcast();
  final _finesStream = StreamController<List<TrafficFine>>.broadcast();

  Future<void> init() async {
    await Hive.initFlutter();

    _transactionsBox = await Hive.openBox<String>('transactionsBox');
    _attendancesBox = await Hive.openBox<String>('attendancesBox');
    _goalsBox = await Hive.openBox<String>('goalsBox');
    _loansBox = await Hive.openBox<String>('loansBox');
    _usersBox = await Hive.openBox<String>('usersBox');
    _notesBox = await Hive.openBox<String>('notesBox');
    _documentsBox = await Hive.openBox<String>('documentsBox');
    _driverTripsBox = await Hive.openBox<String>('driverTripsBox');
    _finesBox = await Hive.openBox<String>('finesBox');

    _emitTransactions();
    _emitAttendances();
    _emitGoals();
    _emitLoans();
    _emitUsers();
    _emitNotes();
    _emitDocuments();
    _emitDriverTrips();
    _emitFines();
  }

  Future<void> clear() async {
    await _transactionsBox.clear();
    await _attendancesBox.clear();
    await _goalsBox.clear();
    await _loansBox.clear();
    await _usersBox.clear();
    await _notesBox.clear();
    await _documentsBox.clear();
    await _driverTripsBox.clear();
    await _finesBox.clear();

    _emitTransactions();
    _emitAttendances();
    _emitGoals();
    _emitLoans();
    _emitUsers();
    _emitNotes();
    _emitDocuments();
    _emitDriverTrips();
    _emitFines();
  }

  // Common read/write logic using JSON encoding for simple mapping
  List<T> _readAll<T>(
      Box<String> box, T Function(Map<String, dynamic>) fromJson) {
    final str = box.get('data');
    if (str == null) return [];
    final List list = jsonDecode(str);
    return list.map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _writeAll<T>(Box<String> box, List<T> items,
      Map<String, dynamic> Function(T) toJson, void Function() emitFunc) async {
    await box.put('data', jsonEncode(items.map((e) => toJson(e)).toList()));
    emitFunc();
  }

  Future<void> _put<T>(
      T item,
      Box<String> box,
      T Function(Map<String, dynamic>) fromJson,
      Map<String, dynamic> Function(T) toJson,
      int? Function(T) getId,
      void Function(T, int) setId,
      void Function() emitFunc) async {
    final items = _readAll(box, fromJson);
    final id = getId(item);
    if (id == null) {
      int nextId = 1;
      for (var existing in items) {
        final eid = getId(existing);
        if (eid != null && eid >= nextId) nextId = eid + 1;
      }
      setId(item, nextId);
      items.add(item);
    } else {
      final index = items.indexWhere((e) => getId(e) == id);
      if (index >= 0)
        items[index] = item;
      else
        items.add(item);
    }
    await _writeAll(box, items, toJson, emitFunc);
  }

  Future<void> _delete<T>(
      int id,
      Box<String> box,
      T Function(Map<String, dynamic>) fromJson,
      Map<String, dynamic> Function(T) toJson,
      int? Function(T) getId,
      void Function() emitFunc) async {
    final items = _readAll(box, fromJson);
    items.removeWhere((e) => getId(e) == id);
    await _writeAll(box, items, toJson, emitFunc);
  }

  // --- Transactions ---
  void _emitTransactions() => _transactionsStream.add(getTransactions());
  Stream<List<AppTransaction>> watchTransactions() async* {
    yield getTransactions();
    yield* _transactionsStream.stream;
  }

  List<AppTransaction> getTransactions() =>
      _readAll(_transactionsBox, (m) => AppTransaction.fromJson(m));
  Future<void> putTransaction(AppTransaction transaction) => _put(
      transaction,
      _transactionsBox,
      (m) => AppTransaction.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitTransactions);

  // --- Attendances ---
  void _emitAttendances() => _attendancesStream.add(getAttendances());
  Stream<List<Attendance>> watchAttendances() async* {
    yield getAttendances();
    yield* _attendancesStream.stream;
  }

  List<Attendance> getAttendances() =>
      _readAll(_attendancesBox, (m) => Attendance.fromJson(m));
  Future<void> putAttendance(Attendance attendance) => _put(
      attendance,
      _attendancesBox,
      (m) => Attendance.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitAttendances);

  // --- Goals ---
  void _emitGoals() => _goalsStream.add(getGoals());
  Stream<List<Goal>> watchGoals() async* {
    yield getGoals();
    yield* _goalsStream.stream;
  }

  List<Goal> getGoals() => _readAll(_goalsBox, (m) => Goal.fromJson(m));
  Future<void> putGoal(Goal goal) => _put(
      goal,
      _goalsBox,
      (m) => Goal.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitGoals);
  Future<void> deleteGoal(int id) => _delete(id, _goalsBox,
      (m) => Goal.fromJson(m), (t) => t.toJson(), (t) => t.id, _emitGoals);
  Future<Goal?> getGoal(int id) async {
    final items = getGoals();
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Loans ---
  void _emitLoans() => _loansStream.add(getLoans());
  Stream<List<Loan>> watchLoans() async* {
    yield getLoans();
    yield* _loansStream.stream;
  }

  List<Loan> getLoans() => _readAll(_loansBox, (m) => Loan.fromJson(m));
  Future<void> putLoan(Loan loan) => _put(
      loan,
      _loansBox,
      (m) => Loan.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitLoans);
  Future<Loan?> getLoan(int id) async {
    final items = getLoans();
    try {
      return items.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  // --- Users ---
  void _emitUsers() => _usersStream.add(getUsers());
  Stream<List<User>> watchUsers() async* {
    yield getUsers();
    yield* _usersStream.stream;
  }

  List<User> getUsers() => _readAll(_usersBox, (m) => User.fromJson(m));
  Future<void> putUser(User user) => _put(
      user,
      _usersBox,
      (m) => User.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitUsers);

  // --- Notes ---
  void _emitNotes() => _notesStream.add(getNotes());
  Stream<List<NoteItem>> watchNotes() async* {
    yield getNotes();
    yield* _notesStream.stream;
  }

  List<NoteItem> getNotes() => _readAll(_notesBox, (m) => NoteItem.fromJson(m));
  Future<void> putNote(NoteItem note) => _put(
      note,
      _notesBox,
      (m) => NoteItem.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitNotes);

  // --- Documents ---
  void _emitDocuments() => _documentsStream.add(getDocuments());
  Stream<List<DocumentItem>> watchDocuments() async* {
    yield getDocuments();
    yield* _documentsStream.stream;
  }

  List<DocumentItem> getDocuments() =>
      _readAll(_documentsBox, (m) => DocumentItem.fromJson(m));
  Future<void> putDocument(DocumentItem doc) => _put(
      doc,
      _documentsBox,
      (m) => DocumentItem.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitDocuments);

  // --- Driver Trips ---
  void _emitDriverTrips() => _driverTripsStream.add(getDriverTrips());
  Stream<List<DriverTrip>> watchDriverTrips() async* {
    yield getDriverTrips();
    yield* _driverTripsStream.stream;
  }

  List<DriverTrip> getDriverTrips() =>
      _readAll(_driverTripsBox, (m) => DriverTrip.fromJson(m));
  Future<void> putDriverTrip(DriverTrip trip) => _put(
      trip,
      _driverTripsBox,
      (m) => DriverTrip.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitDriverTrips);
  Future<void> deleteDriverTrip(int id) => _delete(
      id,
      _driverTripsBox,
      (m) => DriverTrip.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      _emitDriverTrips);

  // --- Traffic Fines ---
  void _emitFines() => _finesStream.add(getFines());
  Stream<List<TrafficFine>> watchFines() async* {
    yield getFines();
    yield* _finesStream.stream;
  }

  List<TrafficFine> getFines() =>
      _readAll(_finesBox, (m) => TrafficFine.fromJson(m));
  Future<void> putFine(TrafficFine fine) => _put(
      fine,
      _finesBox,
      (m) => TrafficFine.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      (t, id) => t.id = id,
      _emitFines);
  Future<void> deleteFine(int id) => _delete(
      id,
      _finesBox,
      (m) => TrafficFine.fromJson(m),
      (t) => t.toJson(),
      (t) => t.id,
      _emitFines);
}
