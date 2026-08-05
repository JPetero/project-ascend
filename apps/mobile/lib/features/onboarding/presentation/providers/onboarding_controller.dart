import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/core_providers.dart';
import '../../../../core/storage/app_database.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../profile/domain/preferences_model.dart';
import '../../../profile/presentation/providers/preferences_controller.dart';
import '../../../profile/presentation/providers/profile_controller.dart';
import '../../domain/onboarding_draft.dart';

class OnboardingState {
  const OnboardingState({
    this.page = OnboardingPage.companion,
    this.draft = const OnboardingFormDraft(),
    this.isSubmitting = false,
  });

  final OnboardingPage page;
  final OnboardingFormDraft draft;
  final bool isSubmitting;

  int get pageIndex => page.index;

  OnboardingState copyWith({
    OnboardingPage? page,
    OnboardingFormDraft? draft,
    bool? isSubmitting,
  }) {
    return OnboardingState(
      page: page ?? this.page,
      draft: draft ?? this.draft,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }
}

class OnboardingController extends StateNotifier<OnboardingState> {
  OnboardingController({required Ref ref, required AppDatabase database})
    : _ref = ref,
      _database = database,
      super(const OnboardingState()) {
    _restore();
  }

  final Ref _ref;
  final AppDatabase _database;

  /// Guards against [_restore] clobbering a selection the user already
  /// made. `profileControllerProvider`/`preferencesControllerProvider` may
  /// still be loading the moment this controller is first read (they're
  /// lazily created too), and the Drift lookup below is a genuine async
  /// gap — if the user interacts before either resolves, their edit must
  /// win, not the stale pre-await snapshot.
  bool _hasUserInteracted = false;

  Future<void> _restore() async {
    final profile = _ref.read(profileControllerProvider).asData?.value;
    final companion = _ref
        .read(preferencesControllerProvider)
        .asData
        ?.value
        ?.companion;
    var draft = OnboardingFormDraft.fromProfile(profile, companion);
    var pageIndex = profile?.onboardingStep ?? 0;

    final localDraft = await _database.readOnboardingDraft();
    if (localDraft != null) {
      final (localStep, localJson) = localDraft;
      draft = OnboardingFormDraft.fromJson({...draft.toJson(), ...localJson});
      if (localStep > pageIndex) pageIndex = localStep;
    }

    final clampedIndex = pageIndex.clamp(0, OnboardingPage.values.length - 1);
    if (mounted && !_hasUserInteracted) {
      state = state.copyWith(
        draft: draft,
        page: OnboardingPage.values[clampedIndex],
      );
    }
  }

  Future<void> setCompanion(Companion companion) async {
    _hasUserInteracted = true;
    state = state.copyWith(draft: state.draft.copyWith(companion: companion));
    await _persistLocally();
    await _ref.read(preferencesControllerProvider.notifier).update({
      'companion': companion.name.toUpperCase(),
    });
  }

  Future<void> updateDraft(
    OnboardingFormDraft Function(OnboardingFormDraft current) updater,
  ) async {
    _hasUserInteracted = true;
    state = state.copyWith(draft: updater(state.draft));
    await _persistLocally();
  }

  Future<void> _persistLocally() async {
    await _database.saveOnboardingDraft(state.pageIndex, state.draft.toJson());
  }

  Future<void> goNext() async {
    _hasUserInteracted = true;
    final isLastPage = state.page == OnboardingPage.values.last;
    final nextIndex = (state.pageIndex + 1).clamp(
      0,
      OnboardingPage.values.length - 1,
    );

    state = state.copyWith(isSubmitting: true);
    try {
      await _ref
          .read(profileControllerProvider.notifier)
          .updateOnboarding(
            state.draft.toOnboardingPatch(
              onboardingStep: isLastPage ? state.pageIndex : nextIndex,
              onboardingCompleted: isLastPage,
            ),
          );

      if (isLastPage) {
        await _database.clearOnboardingDraft();
      } else {
        state = state.copyWith(page: OnboardingPage.values[nextIndex]);
      }
    } finally {
      state = state.copyWith(isSubmitting: false);
    }
  }

  void goBack() {
    final previousIndex = (state.pageIndex - 1).clamp(
      0,
      OnboardingPage.values.length - 1,
    );
    state = state.copyWith(page: OnboardingPage.values[previousIndex]);
  }
}

// Deliberately not .autoDispose: this controller does multi-step async work
// (persist-then-await-repository-call) on every field edit, and
// auto-dispose can tear it down mid-flight the instant a rebuild
// momentarily drops its last listener, which throws on the next `state =`.
// It still gets a fresh instance per signed-in user because the
// `ref.watch(authControllerProvider...)` dependency below changes.
final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, OnboardingState>((ref) {
      ref.watch(authControllerProvider.select((s) => s.user?.id));
      return OnboardingController(
        ref: ref,
        database: ref.watch(appDatabaseProvider),
      );
    });
