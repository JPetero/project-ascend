import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/design_system.dart';
import '../../../../core/routing/route_paths.dart';
import '../../../auth/presentation/providers/auth_controller.dart';
import '../../../community/domain/community_post.dart';
import '../../../community/presentation/providers/community_feed_controller.dart';
import '../providers/promote_controller.dart';

class CreateCampaignScreen extends ConsumerStatefulWidget {
  const CreateCampaignScreen({super.key});

  @override
  ConsumerState<CreateCampaignScreen> createState() =>
      _CreateCampaignScreenState();
}

class _CreateCampaignScreenState extends ConsumerState<CreateCampaignScreen> {
  final _budgetController = TextEditingController(text: '50');
  final _formKey = GlobalKey<FormState>();
  String _currency = 'USD';
  CommunityPost? _selectedPost;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final post = _selectedPost;
    if (post == null) {
      setState(() => _error = 'Choose a post to promote.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      final campaign = await ref
          .read(promoteRepositoryProvider)
          .createCampaign(
            postId: post.id,
            budgetAmount: num.parse(_budgetController.text.trim()),
            budgetCurrency: _currency,
          );
      ref.invalidate(promoteControllerProvider);
      if (!mounted) return;
      context.pushReplacement(
        RoutePaths.promoteCampaignDetailPath(campaign.id),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider.select((s) => s.user?.id));

    return Scaffold(
      appBar: AppBar(title: const Text('New campaign')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AscendSpacing.md),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose a post to promote',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AscendSpacing.sm),
                if (userId == null)
                  const Text('Sign in to select a post.')
                else
                  FutureBuilder<List<CommunityPost>>(
                    future: ref
                        .read(communityRepositoryProvider)
                        .listFeed(authorId: userId),
                    builder: (context, snapshot) {
                      final posts = snapshot.data ?? const [];
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const AscendLoadingIndicator();
                      }
                      if (posts.isEmpty) {
                        return const Text(
                          'Create a Community post first to promote it.',
                        );
                      }
                      return Column(
                        children: [
                          for (final post in posts)
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                _selectedPost?.id == post.id
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                              ),
                              title: Text(
                                post.caption?.isNotEmpty == true
                                    ? post.caption!
                                    : '(no caption)',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () => setState(() => _selectedPost = post),
                            ),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: AscendSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: AscendTextField(
                        controller: _budgetController,
                        label: 'Budget',
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          final parsed = num.tryParse(value?.trim() ?? '');
                          return parsed == null || parsed <= 0
                              ? 'Enter a positive amount'
                              : null;
                        },
                      ),
                    ),
                    const SizedBox(width: AscendSpacing.sm),
                    DropdownButton<String>(
                      value: _currency,
                      items: const [
                        DropdownMenuItem(value: 'USD', child: Text('USD')),
                        DropdownMenuItem(value: 'PHP', child: Text('PHP')),
                      ],
                      onChanged: (value) {
                        if (value != null) setState(() => _currency = value);
                      },
                    ),
                  ],
                ),
                const Text(
                  'Non-final hypothesis — no billing is charged this build.',
                  style: TextStyle(fontSize: 12),
                ),
                if (_error != null) ...[
                  const SizedBox(height: AscendSpacing.sm),
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
                const SizedBox(height: AscendSpacing.lg),
                AscendPrimaryButton(
                  label: 'Submit for review',
                  isLoading: _isSubmitting,
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
