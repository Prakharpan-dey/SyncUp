import 'dart:convert';
import 'dart:io';

/// Loads a captured API response from `test/fixtures/api/`.
///
/// These files are copied verbatim from `syncup-backend/tests/fixtures/api/`,
/// where the backend asserts it still *produces* them. Parsing the same bytes
/// here means a field renamed on either side fails a test on that side.
///
/// This is the seam that would have caught the bugs that shipped: five screens
/// rendered empty because the client unwrapped a `{friends: […]}` envelope the
/// API never sent, and groups failed because `GroupDto` read `created_by` where
/// the API sends `owner_id`.
dynamic loadFixture(String name) {
  final file = File('test/fixtures/api/$name.json');
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture test/fixtures/api/$name.json — copy it from '
      'syncup-backend/tests/fixtures/api/',
    );
  }
  return jsonDecode(file.readAsStringSync());
}

/// A fixture that is a JSON object.
Map<String, dynamic> fixtureObject(String name) =>
    Map<String, dynamic>.from(loadFixture(name) as Map);

/// A fixture that is a bare JSON array — the shape every list endpoint returns.
List<Map<String, dynamic>> fixtureList(String name) =>
    (loadFixture(name) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
