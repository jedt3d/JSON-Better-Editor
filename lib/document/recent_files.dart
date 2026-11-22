/// File › Open Recent keeps at most this many files (#92).
const maxRecentFiles = 10;

/// [list] with [path] added as the newest entry: moved to the front if it
/// was already there, and the oldest dropped past [maxRecentFiles].
List<String> addRecentFile(List<String> list, String path) =>
    [path, ...list.where((p) => p != path)].take(maxRecentFiles).toList();
