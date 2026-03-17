import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';

class NotesProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  StreamSubscription? _connectivitySub;

  List<Heading> _headings = [];
  bool _isLoading = false;
  bool _isOffline = false;
  String? _error;

  List<Heading> get headings => _headings;
  bool get isLoading => _isLoading;
  bool get isOffline => _isOffline;
  String? get error => _error;

  // ─── HEADINGS ─────────────────────────────────────────────────────────────

  void listenToHeadings() {
    _isLoading = true;
    notifyListeners();

    // Enable offline persistence
    _db.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );

    // Listen to real connectivity changes
    _connectivitySub = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) {
      final online = results.any((r) => r != ConnectivityResult.none);
      if (_isOffline != !online) {
        _isOffline = !online;
        notifyListeners();
      }
    });

    // Check initial connectivity
    Connectivity().checkConnectivity().then((results) {
      _isOffline = results.every((r) => r == ConnectivityResult.none);
      notifyListeners();
    });

    _db
        .collection('headings')
        .orderBy('order')
        .snapshots()
        .listen(
      (snapshot) async {
        final List<Heading> headings = [];

        for (final doc in snapshot.docs) {
          final heading = Heading.fromMap(doc.data(), doc.id);

          try {
            final colSnap = await _db
                .collection('headings')
                .doc(doc.id)
                .collection('columns')
                .orderBy('order')
                .get(GetOptions(
                  source: _isOffline ? Source.cache : Source.serverAndCache,
                ));

            heading.columns = colSnap.docs
                .map((c) => NoteColumn.fromMap(c.data(), c.id))
                .toList();
          } catch (_) {
            // No cache for this heading's columns yet — leave empty
            heading.columns = [];
          }

          headings.add(heading);
        }

        _headings = headings;
        _isLoading = false;
        _error = null;
        notifyListeners();
      },
      onError: (e) {
        if (_headings.isNotEmpty) {
          _isLoading = false;
          notifyListeners();
          return;
        }
        _error = e.toString();
        _isLoading = false;
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> addHeading({
    required String title,
    required String emoji,
  }) async {
    final now = DateTime.now();
    final nextOrder = _headings.length;

    // Optimistic local add so UI closes immediately
    final tempId = 'temp_${now.millisecondsSinceEpoch}';
    final tempHeading = Heading(
      id: tempId,
      title: title,
      emoji: emoji,
      order: nextOrder,
      createdAt: now,
      updatedAt: now,
      columns: [],
    );
    _headings.add(tempHeading);
    notifyListeners();

    try {
      await _db.collection('headings').add({
        'title': title,
        'emoji': emoji,
        'order': nextOrder,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });
      // Remove temp — real one will come from snapshot listener
      _headings.removeWhere((h) => h.id == tempId);
      notifyListeners();
    } catch (e) {
      // Offline — keep temp heading visible, will sync later
    }
  }

  Future<void> updateHeading(Heading heading) async {
    heading.updatedAt = DateTime.now();
    try {
      await _db
          .collection('headings')
          .doc(heading.id)
          .update(heading.toMap());
    } catch (e) {
      // Will sync when back online
    }
  }

  Future<void> deleteHeading(String headingId) async {
    // Optimistic remove
    _headings.removeWhere((h) => h.id == headingId);
    notifyListeners();

    try {
      final cols = await _db
          .collection('headings')
          .doc(headingId)
          .collection('columns')
          .get();
      final batch = _db.batch();
      for (final c in cols.docs) {
        batch.delete(c.reference);
      }
      batch.delete(_db.collection('headings').doc(headingId));
      await batch.commit();
    } catch (e) {
      // Will sync when back online
    }
  }

  Future<void> reorderHeadings(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;

    final list = List<Heading>.from(_headings);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _headings = list;
    notifyListeners();

    try {
      final batch = _db.batch();
      for (int i = 0; i < list.length; i++) {
        batch.update(
          _db.collection('headings').doc(list[i].id),
          {'order': i},
        );
        list[i].order = i;
      }
      await batch.commit();
    } catch (e) {
      // Will sync when back online
    }
  }

  // ─── COLUMNS ──────────────────────────────────────────────────────────────

  Future<void> addColumn({
    required String headingId,
    required String title,
    required String content,
  }) async {
    final now = DateTime.now();
    final idx = _headings.indexWhere((h) => h.id == headingId);
    final nextOrder = idx != -1 ? _headings[idx].columns.length : 0;

    // Optimistic local add so UI closes immediately
    final tempId = 'temp_${now.millisecondsSinceEpoch}';
    if (idx != -1) {
      _headings[idx].columns.add(NoteColumn(
        id: tempId,
        title: title,
        content: content,
        order: nextOrder,
        createdAt: now,
        updatedAt: now,
      ));
      notifyListeners();
    }

    try {
      await _db
          .collection('headings')
          .doc(headingId)
          .collection('columns')
          .add({
        'title': title,
        'content': content,
        'order': nextOrder,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      });

      // Remove temp — real one comes from refresh
      if (idx != -1) {
        _headings[idx].columns.removeWhere((c) => c.id == tempId);
        notifyListeners();
      }
      await _refreshHeading(headingId);
    } catch (e) {
      // Offline — keep temp column visible
    }
  }

  Future<void> updateColumn({
    required String headingId,
    required NoteColumn column,
  }) async {
    column.updatedAt = DateTime.now();

    // Optimistic local update
    final hIdx = _headings.indexWhere((h) => h.id == headingId);
    if (hIdx != -1) {
      final cIdx =
          _headings[hIdx].columns.indexWhere((c) => c.id == column.id);
      if (cIdx != -1) {
        _headings[hIdx].columns[cIdx] = column;
        notifyListeners();
      }
    }

    try {
      await _db
          .collection('headings')
          .doc(headingId)
          .collection('columns')
          .doc(column.id)
          .update(column.toMap());
      await _refreshHeading(headingId);
    } catch (e) {
      // Will sync when back online
    }
  }

  Future<void> deleteColumn({
    required String headingId,
    required String columnId,
  }) async {
    // Optimistic remove
    final idx = _headings.indexWhere((h) => h.id == headingId);
    if (idx != -1) {
      _headings[idx].columns.removeWhere((c) => c.id == columnId);
      notifyListeners();
    }

    try {
      await _db
          .collection('headings')
          .doc(headingId)
          .collection('columns')
          .doc(columnId)
          .delete();
    } catch (e) {
      // Will sync when back online
    }
  }

  Future<void> reorderColumns({
    required String headingId,
    required int oldIndex,
    required int newIndex,
  }) async {
    if (oldIndex == newIndex) return;

    final idx = _headings.indexWhere((h) => h.id == headingId);
    if (idx == -1) return;

    final list = List<NoteColumn>.from(_headings[idx].columns);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    _headings[idx].columns = list;
    notifyListeners();

    try {
      final batch = _db.batch();
      for (int i = 0; i < list.length; i++) {
        batch.update(
          _db
              .collection('headings')
              .doc(headingId)
              .collection('columns')
              .doc(list[i].id),
          {'order': i},
        );
        list[i].order = i;
      }
      await batch.commit();
    } catch (e) {
      // Will sync when back online
    }
  }

  Future<void> _refreshHeading(String headingId) async {
    try {
      final colSnap = await _db
          .collection('headings')
          .doc(headingId)
          .collection('columns')
          .orderBy('order')
          .get();

      final idx = _headings.indexWhere((h) => h.id == headingId);
      if (idx != -1) {
        _headings[idx].columns = colSnap.docs
            .map((c) => NoteColumn.fromMap(c.data(), c.id))
            .toList();
        notifyListeners();
      }
    } catch (e) {
      // Offline — keep current columns
    }
  }
}