import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/community/domain/community_post.dart';
import 'package:mobile/features/gallery/domain/gallery_album.dart';
import 'package:mobile/features/privacy/presentation/screens/privacy_center_screen.dart';
import 'package:mobile/features/profile/domain/preferences_model.dart';
import 'package:mobile/features/profile/presentation/providers/preferences_controller.dart';

import '../../helpers/pump_helpers.dart';
import '../../helpers/test_provider_scope.dart';

void main() {
  Future<void> scrollUntilFound(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'shows the AI memory and conversation history toggles at their current values',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialPreferences: const PreferencesModel(
          companion: Companion.atlas,
          companionMode: CompanionMode.standard,
          themeMode: AppThemeMode.system,
          reducedMotion: false,
          notificationsEnabled: true,
          aiMemoryEnabled: true,
          conversationHistoryEnabled: false,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PrivacyCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      final switches = tester
          .widgetList<SwitchListTile>(find.byType(SwitchListTile))
          .toList();
      expect(switches[0].value, isTrue);
      expect(switches[1].value, isFalse);
    },
  );

  testWidgets('toggling AI memory updates the preference', (tester) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: false,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await tester.tap(find.byType(SwitchListTile).first);
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.aiMemoryEnabled, isTrue);
  });

  testWidgets(
    'shows the sensitive memory notice and the new privacy sections at their current values',
    (tester) async {
      final container = await createTestContainer(
        signedIn: true,
        initialPreferences: const PreferencesModel(
          companion: Companion.atlas,
          companionMode: CompanionMode.standard,
          themeMode: AppThemeMode.system,
          reducedMotion: false,
          notificationsEnabled: true,
          aiMemoryEnabled: true,
          defaultPostVisibility: CommunityVisibility.followers,
          defaultGalleryVisibility: GalleryVisibility.shared,
          progressPhotoDefaultVisibility: GalleryVisibility.private_,
          defaultHideCardioRoute: false,
        ),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: PrivacyCenterScreen()),
        ),
      );
      await pumpForAsyncSettle(tester);

      await scrollUntilFound(tester, find.text('Sensitive memory protection'));
      expect(find.text('Sensitive memory protection'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Profile visibility'));
      expect(find.text('Profile visibility'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Default post audience'));
      expect(find.text('Followers only'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Default gallery privacy'));
      expect(find.text('Shared to Community'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Progress photo privacy'));
      expect(find.text('Private'), findsOneWidget);

      await scrollUntilFound(tester, find.text('View my gallery'));
      expect(find.text('View my gallery'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Hide my route by default'));
      final routeSwitch = tester.widget<SwitchListTile>(
        find.widgetWithText(SwitchListTile, 'Hide my route by default'),
      );
      expect(routeSwitch.value, isFalse);

      await scrollUntilFound(
        tester,
        find.text('Rankings location participation'),
      );
      expect(find.text('Rankings location participation'), findsOneWidget);

      await scrollUntilFound(tester, find.text('Connected health providers'));
      expect(find.text('Connected health providers'), findsOneWidget);
    },
  );

  testWidgets('picking a default post audience updates the preference', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: true,
        defaultPostVisibility: CommunityVisibility.public,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await scrollUntilFound(tester, find.text('Default post audience'));
    await tester.tap(find.text('Default post audience'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Only me'));
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.defaultPostVisibility, CommunityVisibility.private);
    expect(find.text('Only me'), findsOneWidget);
  });

  testWidgets('picking a default gallery privacy updates the preference', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: true,
        defaultGalleryVisibility: GalleryVisibility.private_,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await scrollUntilFound(tester, find.text('Default gallery privacy'));
    await tester.tap(find.text('Default gallery privacy'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Shared to Community'));
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.defaultGalleryVisibility, GalleryVisibility.shared);
  });

  testWidgets('picking a progress photo privacy updates the preference', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: true,
        progressPhotoDefaultVisibility: GalleryVisibility.private_,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await scrollUntilFound(tester, find.text('Progress photo privacy'));
    await tester.tap(find.text('Progress photo privacy'));
    await pumpForAsyncSettle(tester);

    await tester.tap(find.text('Shared to Community'));
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(
      preferences?.progressPhotoDefaultVisibility,
      GalleryVisibility.shared,
    );
  });

  testWidgets('toggling hide-route-by-default updates the preference', (
    tester,
  ) async {
    final container = await createTestContainer(
      signedIn: true,
      initialPreferences: const PreferencesModel(
        companion: Companion.atlas,
        companionMode: CompanionMode.standard,
        themeMode: AppThemeMode.system,
        reducedMotion: false,
        notificationsEnabled: true,
        aiMemoryEnabled: true,
        defaultHideCardioRoute: true,
      ),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: PrivacyCenterScreen()),
      ),
    );
    await pumpForAsyncSettle(tester);

    await scrollUntilFound(tester, find.text('Hide my route by default'));
    final routeSwitchFinder = find.widgetWithText(
      SwitchListTile,
      'Hide my route by default',
    );
    final routeSwitch = tester.widget<SwitchListTile>(routeSwitchFinder);
    expect(routeSwitch.value, isTrue);

    await tester.tap(routeSwitchFinder);
    await pumpForAsyncSettle(tester);

    final preferences = container
        .read(preferencesControllerProvider)
        .asData
        ?.value;
    expect(preferences?.defaultHideCardioRoute, isFalse);
  });
}
