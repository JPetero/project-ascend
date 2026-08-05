import 'package:flutter/material.dart';

import '../../../../core/design_system/design_system.dart';

class _SampleCommunityPost {
  const _SampleCommunityPost({
    required this.author,
    required this.message,
    required this.timeAgo,
  });
  final String author;
  final String message;
  final String timeAgo;
}

/// Development-only sample fixture. Real community features (posting,
/// following, moderation) are on the roadmap — see packages/docs/roadmap.md.
const _samplePosts = [
  _SampleCommunityPost(
    author: 'Community member',
    message:
        'Completed a full-body strength session today. Feeling steady progress!',
    timeAgo: '2h ago',
  ),
  _SampleCommunityPost(
    author: 'Community member',
    message: 'Four days in a row now. Small consistent steps add up.',
    timeAgo: '5h ago',
  ),
];

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          children: [
            AscendCard(
              child: Row(
                children: [
                  Icon(
                    Icons.privacy_tip_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: AscendSpacing.sm),
                  Expanded(
                    child: Text(
                      'Community is private by default. Nothing here is shared publicly, and this '
                      'preview shows sample data only.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AscendSpacing.md),
            for (final post in _samplePosts) ...[
              AscendCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                        const SizedBox(width: AscendSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                post.author,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Text(
                                post.timeAgo,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AscendSpacing.sm),
                    Text(
                      post.message,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AscendSpacing.md),
            ],
            AscendEmptyState(
              icon: Icons.groups_outlined,
              title: 'More community features are coming',
              message:
                  'Posting, following, and challenges will arrive in a future release.',
            ),
          ],
        ),
      ),
    );
  }
}
