import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clubsphere/features/public/club_profile/club_public_profile_screen.dart';

void main() {
  testWidgets('Test ClubPublicProfileScreen rendering', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: ClubPublicProfileScreen(id: 'c878954f-cf48-438d-ad0d-c0528e1d51ab')));
    await tester.pumpAndSettle();
  });
}
