/// What a device row looks like to a pull.
typedef LocalRow = ({String id, bool isSynced, DateTime updatedAt});

/// What a server row looks like to a pull.
typedef RemoteRow = ({String id, DateTime updatedAt});

/// Decides what a pull from the server changes on the device.
///
/// The app is local-first and never read the server back, so a reinstall — or
/// signing in on a second phone — started from nothing: no tasks, no repeating
/// rules, no completion history, and with it no streak or weekly recap.
///
/// - Takes every server row, except where the device holds a newer change the
///   server has not seen yet: one still [queued] for upload, or an unsynced row
///   edited after the server's copy.
/// - Removes device rows the server no longer has, but only ones known to have
///   been uploaded. A row that never made it up is the only copy there is.
({Set<String> take, Set<String> remove}) planPull({
  required Iterable<LocalRow> local,
  required Iterable<RemoteRow> remote,
  required Set<String> queued,
}) {
  final localById = {for (final l in local) l.id: l};
  final remoteIds = <String>{};
  final take = <String>{};

  for (final r in remote) {
    remoteIds.add(r.id);
    if (queued.contains(r.id)) continue;
    final mine = localById[r.id];
    if (mine != null && !mine.isSynced && mine.updatedAt.isAfter(r.updatedAt)) {
      continue;
    }
    take.add(r.id);
  }

  final remove = {
    for (final l in local)
      if (l.isSynced && !remoteIds.contains(l.id) && !queued.contains(l.id)) l.id,
  };

  return (take: take, remove: remove);
}
