import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:extrabite_mobile/models/location_history_item.dart';
import 'package:extrabite_mobile/providers/location_history_provider.dart';
import 'package:extrabite_mobile/features/customer/widgets/location_header.dart';
import 'mocks.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LocationHistoryNotifier Unit Tests', () {
    test('Test 1 (Empty History): Initial history is empty', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier = LocationHistoryNotifier(userId: 'user_1', prefs: prefs);
      await notifier.loadHistory();

      expect(notifier.state, isEmpty);
    });

    test(
        'Test 2 (One Searched Location): Selecting a location adds it to history',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier = LocationHistoryNotifier(userId: 'user_1', prefs: prefs);

      final vitLocation = LocationHistoryItem(
        id: 'vit_ap',
        title: 'Near VIT-AP University',
        subtitle: 'Inavolu, Amaravati',
        latitude: 16.4971,
        longitude: 80.5005,
        icon: 'campus',
        timestamp: DateTime.now(),
      );

      await notifier.addLocation(vitLocation);

      expect(notifier.state.length, 1);
      expect(notifier.state.first.title, 'Near VIT-AP University');
    });

    test(
        'Test 3 (Multiple Searched Locations): Last selected item is first in history',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier = LocationHistoryNotifier(userId: 'user_1', prefs: prefs);

      final vit = LocationHistoryItem(
        id: 'vit_ap',
        title: 'Near VIT-AP University',
        subtitle: 'Inavolu, Amaravati',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      final srm = LocationHistoryItem(
        id: 'srm_ap',
        title: 'Near SRM University-AP',
        subtitle: 'Neerukonda, Amaravati',
        latitude: 16.4635,
        longitude: 80.5085,
      );

      await notifier.addLocation(vit);
      await notifier.addLocation(srm);

      expect(notifier.state.length, 2);
      expect(notifier.state[0].title, 'Near SRM University-AP');
      expect(notifier.state[1].title, 'Near VIT-AP University');
    });

    test(
        'Test 4 (Duplicate Location): Re-selecting an existing location moves it to top without duplicate',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier = LocationHistoryNotifier(userId: 'user_1', prefs: prefs);

      final vit = LocationHistoryItem(
        id: 'vit_ap',
        title: 'Near VIT-AP University',
        subtitle: 'Inavolu, Amaravati',
        latitude: 16.4971,
        longitude: 80.5005,
      );

      final srm = LocationHistoryItem(
        id: 'srm_ap',
        title: 'Near SRM University-AP',
        subtitle: 'Neerukonda, Amaravati',
        latitude: 16.4635,
        longitude: 80.5085,
      );

      await notifier.addLocation(vit);
      await notifier.addLocation(srm);
      // Re-select VIT
      await notifier.addLocation(vit);

      expect(notifier.state.length, 2);
      expect(notifier.state[0].title, 'Near VIT-AP University');
      expect(notifier.state[1].title, 'Near SRM University-AP');
    });

    test(
        'Test 5 (Persistence): Persists and reloads across instances from SharedPreferences',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier1 =
          LocationHistoryNotifier(userId: 'user_123', prefs: prefs);

      final item = LocationHistoryItem(
        id: 'thullur',
        title: 'Thullur Center',
        subtitle: 'Amaravati Capital Region',
        latitude: 16.5388,
        longitude: 80.4688,
      );

      await notifier1.addLocation(item);

      // Create new notifier with same user ID
      final notifier2 =
          LocationHistoryNotifier(userId: 'user_123', prefs: prefs);
      await notifier2.loadHistory();

      expect(notifier2.state.length, 1);
      expect(notifier2.state.first.title, 'Thullur Center');
    });

    test(
        'Test 8 (History Isolation): User A and User B have completely isolated histories',
        () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final userANotifier =
          LocationHistoryNotifier(userId: 'user_A', prefs: prefs);
      await userANotifier.addLocation(LocationHistoryItem(
        id: 'user_A_loc',
        title: 'Mangalagiri Town',
        subtitle: 'Near Old Bus Stand',
        latitude: 16.4322,
        longitude: 80.5699,
      ));

      final userBNotifier =
          LocationHistoryNotifier(userId: 'user_B', prefs: prefs);
      await userBNotifier.loadHistory();

      expect(userANotifier.state.length, 1);
      expect(userBNotifier.state, isEmpty);
    });

    test('Removal and Clear History works properly', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final notifier = LocationHistoryNotifier(userId: 'user_1', prefs: prefs);
      await notifier.addLocation(LocationHistoryItem(
        id: 'loc_1',
        title: 'Loc 1',
        subtitle: 'Sub 1',
        latitude: 10.0,
        longitude: 10.0,
      ));
      await notifier.addLocation(LocationHistoryItem(
        id: 'loc_2',
        title: 'Loc 2',
        subtitle: 'Sub 2',
        latitude: 20.0,
        longitude: 20.0,
      ));

      expect(notifier.state.length, 2);

      await notifier.removeLocation('loc_1');
      expect(notifier.state.length, 1);
      expect(notifier.state.first.id, 'loc_2');

      await notifier.clearHistory();
      expect(notifier.state, isEmpty);
    });
  });

  group('Location Picker Modal Widget Tests', () {
    testWidgets(
        'Empty history displays "Search for a location to get started." and not popular list',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...fakeLocationAndAuthOverrides(),
            locationHistoryProvider.overrideWith(
              (ref) =>
                  LocationHistoryNotifier(userId: 'test_empty', prefs: prefs),
            ),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open location picker modal by tapping the location icon/text
      final locationTarget = find.byIcon(Icons.location_on);
      await tester.tap(locationTarget);
      await tester.pumpAndSettle();

      // Verify header and empty state message
      expect(find.text('Choose Your Location'), findsOneWidget);
      expect(find.text('Recent Locations'), findsOneWidget);
      expect(
          find.text('Search for a location to get started.'), findsOneWidget);

      // Verify that the old default popular list is NOT automatically displayed in the modal
      expect(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('Near VIT-AP University'),
        ),
        findsNothing,
      );
      expect(find.text('Near SRM University-AP'), findsNothing);
      expect(find.text('Vijayawada Benz Circle'), findsNothing);
      expect(find.text('Mangalagiri Town'), findsNothing);
      expect(find.text('Thullur Center'), findsNothing);
    });

    testWidgets(
        'Typing in search field filters catalog without auto-saving to history',
        (tester) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      final testNotifier =
          LocationHistoryNotifier(userId: 'test_search', prefs: prefs);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...fakeLocationAndAuthOverrides(),
            locationHistoryProvider.overrideWith((ref) => testNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LocationHeader(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Open modal
      final locationTarget = find.byIcon(Icons.location_on);
      await tester.tap(locationTarget);
      await tester.pumpAndSettle();

      // Type in search field
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'SRM');
      await tester.pumpAndSettle();

      // Search results header should appear
      expect(find.text('Search Results'), findsOneWidget);
      expect(find.text('Near SRM University-AP'), findsOneWidget);

      // History should still be empty because item has not been selected
      expect(testNotifier.state, isEmpty);

      // Now tap the matched search result
      await tester.tap(find.text('Near SRM University-AP'));
      await tester.pumpAndSettle();

      // Now it should be saved in history
      expect(testNotifier.state.length, 1);
      expect(testNotifier.state.first.title, 'Near SRM University-AP');
    });
  });
}
