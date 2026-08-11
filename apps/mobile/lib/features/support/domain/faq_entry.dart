/// Static self-serve Help Center content (S13 Part 33-49) — the answers
/// a user should be able to find before filing a support ticket. Unlike
/// [SupportTicket], this is not backend-driven: there is no admin CMS
/// for FAQ content in this sprint, so entries are hardcoded here and a
/// content change means shipping an app update, same tradeoff as any
/// other static in-app copy (onboarding disclaimers, Terms checkbox
/// text). If this ever needs to be edited without a release, it should
/// move to a backend-driven model like NutrientArticle, not grow ad hoc
/// remote-config plumbing bolted onto this file.
class FaqEntry {
  const FaqEntry({required this.question, required this.answer});

  final String question;
  final String answer;
}

class FaqCategory {
  const FaqCategory({required this.title, required this.entries});

  final String title;
  final List<FaqEntry> entries;
}

const List<FaqCategory> faqCategories = [
  FaqCategory(
    title: 'Account & sign-in',
    entries: [
      FaqEntry(
        question: 'How do I reset my password?',
        answer:
            'On the sign-in screen, tap "Forgot password?" and follow the '
            'link we email you. The link expires after a short time for '
            'security, so request a new one if it stops working.',
      ),
      FaqEntry(
        question: 'Can I sign in with Google or Apple instead of a password?',
        answer:
            'Yes. Use the Google or Apple button on the sign-in screen. '
            'You can link an existing password account to Google/Apple '
            'from Account & Security once signed in.',
      ),
      FaqEntry(
        question: 'How do I delete my account?',
        answer:
            'Open your profile, then Account & Security, then Delete '
            'Account. This permanently removes your data and cannot be '
            'undone — export your data first if you want to keep a copy.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Premium & billing',
    entries: [
      FaqEntry(
        question: "I upgraded but Premium isn't showing on this device.",
        answer:
            'Open the Subscription screen and tap "Restore Purchases." '
            'This replays your purchase from the App Store or Play Store '
            'account you bought it with, which must be signed in on this '
            'device.',
      ),
      FaqEntry(
        question: 'How do I cancel my subscription?',
        answer:
            'Subscriptions are billed and managed by the App Store or '
            'Google Play, not inside Ascend — cancel from your phone\'s '
            'subscription settings for the store you subscribed through.',
      ),
      FaqEntry(
        question: 'What do I lose if I cancel Premium?',
        answer:
            'You keep every workout, meal, and progress entry you logged. '
            'Premium-only features (Vision camera tools, Ascend Promote, '
            'the AI companion\'s deeper research mode) become unavailable '
            'until you resubscribe.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Privacy & your data',
    entries: [
      FaqEntry(
        question: 'Who can see my profile and workouts?',
        answer:
            'Your profile is private by default. Nothing about your '
            'weight, body measurements, or workouts is shared unless you '
            'explicitly post it or generate a shareable card, and even '
            'then you choose what to hide first.',
      ),
      FaqEntry(
        question: 'Can I export or delete my data?',
        answer:
            'Yes — Account & Security has both a "Export my data" option '
            '(a full download of what we store about you) and account '
            'deletion.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Vision camera features',
    entries: [
      FaqEntry(
        question: 'Is Vision\'s form feedback medically accurate?',
        answer:
            'No. Vision gives general form and posture guidance from your '
            'camera — it is not a clinical or diagnostic tool, and it '
            'does not replace advice from a doctor, physical therapist, '
            'or certified trainer, especially if you\'re working around '
            'an injury.',
      ),
      FaqEntry(
        question: 'Does Vision record or upload video of me?',
        answer:
            'Pose analysis runs on-device. See the Privacy Center for '
            'exactly what, if anything, is stored for a given Vision '
            'feature.',
      ),
    ],
  ),
  FaqCategory(
    title: 'Reporting a problem',
    entries: [
      FaqEntry(
        question:
            'I found a bug, a safety concern, or something that feels off.',
        answer:
            'Please file a ticket below and choose the matching category '
            '(Bug report, Safety report, or Moderation appeal). Every '
            'ticket is reviewed — this is the fastest way to reach us.',
      ),
    ],
  ),
];
