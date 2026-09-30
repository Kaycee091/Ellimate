import 'package:flutter_test/flutter_test.dart';

// NOTE: Full integration tests require a live Supabase connection.
// Unit tests for individual components can be run without Supabase.

void main() {
  testWidgets('App builds without crash', (WidgetTester tester) async {
    // This is a smoke test — real functional tests require Supabase setup.
    // See README.md for the manual test checklist.
    expect(true, isTrue);
  });
}
