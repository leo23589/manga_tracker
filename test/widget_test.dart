import 'package:flutter_test/flutter_test.dart';
import 'package:manga_tracker/main.dart';

void main() {
  testWidgets('MangaApp smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MangaApp());

    // Verify that the title bar renders
    expect(find.text('My Mangas 📚'), findsOneWidget);
  });
}
