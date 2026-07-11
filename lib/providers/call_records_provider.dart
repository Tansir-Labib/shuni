import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/call_record.dart';
import '../services/database_service.dart';
import '../services/storage_service.dart';

/// # CallRecordsState
/// 
/// Holds the list of loaded recordings, search queries, and filters.
class CallRecordsState {
  final List<CallRecord> records;
  final bool isLoading;
  final String searchQuery;
  final String? directionFilter; // null = all, 'incoming', 'outgoing'
  final bool? isBookmarkedFilter; // null = all, true, false
  final String error;

  CallRecordsState({
    this.records = const [],
    this.isLoading = false,
    this.searchQuery = '',
    this.directionFilter,
    this.isBookmarkedFilter,
    this.error = '',
  });

  CallRecordsState copyWith({
    List<CallRecord>? records,
    bool? isLoading,
    String? searchQuery,
    String? directionFilter,
    bool? isBookmarkedFilter,
    String? error,
  }) {
    return CallRecordsState(
      records: records ?? this.records,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      directionFilter: directionFilter ?? this.directionFilter,
      isBookmarkedFilter: isBookmarkedFilter ?? this.isBookmarkedFilter,
      error: error ?? this.error,
    );
  }
}

/// # CallRecordsNotifier
/// 
/// State notifier managing call records list, search keywords, filters, and SQL executions.
class CallRecordsNotifier extends StateNotifier<CallRecordsState> {
  CallRecordsNotifier() : super(CallRecordsState()) {
    refreshRecords();
  }

  /// Reloads call records from database based on current search parameters and filter states.
  Future<void> refreshRecords() async {
    state = state.copyWith(isLoading: true);
    try {
      final List<CallRecord> records = await DatabaseService.instance.getAllRecords(
        searchQuery: state.searchQuery,
        directionFilter: state.directionFilter,
        isBookmarkedFilter: state.isBookmarkedFilter,
      );
      state = state.copyWith(records: records, isLoading: false, error: '');
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Updates the text search query parameter.
  void setSearchQuery(String query) {
    if (state.searchQuery == query) return;
    state = state.copyWith(searchQuery: query);
    refreshRecords();
  }

  /// Updates the direction filter (e.g. show incoming calls only).
  void setDirectionFilter(CallDirection? direction) {
    final String? dirStr = direction?.toJson();
    if (state.directionFilter == dirStr) return;
    state = state.copyWith(directionFilter: dirStr);
    refreshRecords();
  }

  /// Filters list to show bookmarks only.
  void toggleBookmarkFilter() {
    final bool? current = state.isBookmarkedFilter;
    final bool? next = current == null ? true : (current ? null : true);
    state = state.copyWith(isBookmarkedFilter: next);
    refreshRecords();
  }

  /// Clears all current list filters.
  void clearFilters() {
    state = CallRecordsState();
    refreshRecords();
  }

  /// Bookmark toggle helper on a specific call record.
  Future<void> toggleBookmark(CallRecord record) async {
    final CallRecord updated = record.copyWith(isBookmarked: !record.isBookmarked);
    
    // Update local list state instantly to feel ultra-responsive
    state = state.copyWith(
      records: state.records.map((r) => r.id == record.id ? updated : r).toList(),
    );

    // Save changes to database in background
    await DatabaseService.instance.updateRecord(updated);
  }

  /// Adds or updates text notes attached to a recording.
  Future<void> updateNotes(CallRecord record, String notes) async {
    final CallRecord updated = record.copyWith(notes: notes);
    
    state = state.copyWith(
      records: state.records.map((r) => r.id == record.id ? updated : r).toList(),
    );

    await DatabaseService.instance.updateRecord(updated);
  }

  /// Deletes a recording physically and from database.
  Future<bool> deleteRecord(CallRecord record) async {
    if (record.id == null) return false;

    // Delete database entry
    final int deletedRows = await DatabaseService.instance.deleteRecord(record.id!);
    if (deletedRows <= 0) return false;

    // Delete physical file
    await StorageService.deleteFile(record.audioFilePath);

    // Update state list
    state = state.copyWith(
      records: state.records.where((r) => r.id != record.id).toList(),
    );
    
    return true;
  }
}

// Global Provider declaration
final callRecordsProvider = StateNotifierProvider<CallRecordsNotifier, CallRecordsState>((ref) {
  return CallRecordsNotifier();
});
