import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_post.dart';
import '../providers/post_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/achievement_card.dart';

class PostsFeedScreen extends ConsumerStatefulWidget {
  const PostsFeedScreen({super.key});

  @override
  ConsumerState<PostsFeedScreen> createState() => _PostsFeedScreenState();
}

class _PostsFeedScreenState extends ConsumerState<PostsFeedScreen> {
  StreamSubscription<QuerySnapshot>? _postSubscription;
  StreamSubscription<User?>? _authSubscription;

  List<AchievementPost>? _posts;
  String? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      _initStream();
    });
  }

  void _initStream() {

    _postSubscription?.cancel();

    setState(() {
      _isLoading = true;
      _error = null;
    });

    _postSubscription = FirebaseFirestore.instance
        .collection('posts')
        .snapshots()
        .listen(
      (snapshot) {
        try {
          final List<AchievementPost> posts = [];
          for (final doc in snapshot.docs) {
            try {
              final data = doc.data();
              if (doc.metadata.hasPendingWrites && data['timestamp'] == null) {
                continue;
              }
              posts.add(AchievementPost.fromMap(doc.id, data));
            } catch (e) {

              print('bad doc error: $e');
            }
          }

          posts.sort((a, b) {
            final timeA = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            final timeB = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
            return timeB.compareTo(timeA);
          });

          if (mounted) {
            setState(() {
              _posts = posts;
              _isLoading = false;
              _error = null;
            });
          }
        } catch (e) {

          print('sort crash: $e');
        }
      },
      onError: (err, stack) {

        print('feed broke: $err');
        if (mounted) {
          setState(() {
            _error = err.toString();
            _isLoading = false;
          });
        }
      },
    );
  }

  @override
  void dispose() {

    _postSubscription?.cancel();
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.navy, AppTheme.navyLight, AppTheme.navyMedium],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,

        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _showCreatePostSheet(context, ref),
          backgroundColor: AppTheme.accent,
          foregroundColor: Colors.white,
          elevation: 4,
          icon: const Icon(Icons.add_rounded, size: 22),
          label: const Text(
            'Post',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceLg,
                  AppTheme.spaceSm,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.accent.withValues(alpha: 0.15),
                      ),
                      child: const Icon(
                        Icons.emoji_events_rounded,
                        color: AppTheme.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spaceMd),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Achievements',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Celebrate wins & earn credibility upvotes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spaceSm),

              Expanded(
                child: _buildFeedContent(theme),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent(ThemeData theme) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppTheme.accent,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spaceLg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTheme.error,
                size: 40,
              ),
              const SizedBox(height: AppTheme.spaceMd),
              Text(
                'Could not load posts',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _error!,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white30,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentPosts = _posts ?? [];

    if (currentPosts.isEmpty) {
      return _EmptyFeedState(theme: theme);
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spaceMd,
      ).copyWith(bottom: 100),
      itemCount: currentPosts.length,
      itemBuilder: (context, index) {
        return AchievementCard(post: currentPosts[index]);
      },
    );
  }
}

class _EmptyFeedState extends StatelessWidget {
  const _EmptyFeedState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.accent.withValues(alpha: 0.12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: AppTheme.accent,
              size: 44,
            ),
          ),
          const SizedBox(height: AppTheme.spaceLg),
          Text(
            'No achievements yet',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share a win!',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white38,
            ),
          ),
        ],
      ),
    );
  }
}

void _showCreatePostSheet(BuildContext context, WidgetRef ref) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const _CreatePostSheet(),
  );
}

class _CreatePostSheet extends ConsumerStatefulWidget {
  const _CreatePostSheet();

  @override
  ConsumerState<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends ConsumerState<_CreatePostSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  PostCategory _selectedCategory = PostCategory.hackathon;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();

    if (title.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {

      await ref.read(postServiceProvider).createPost(
            title: title,
            description: description,
            category: _selectedCategory.label,
          );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
                SizedBox(width: 10),
                Text('Achievement shared successfully!'),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        color: AppTheme.navy.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusXl),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppTheme.spaceLg,
              AppTheme.spaceMd,
              AppTheme.spaceLg,
              AppTheme.spaceLg + bottomInset,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.accent.withValues(alpha: 0.15),
                          ),
                          child: const Icon(
                            Icons.emoji_events_rounded,
                            color: AppTheme.accent,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: AppTheme.spaceMd),
                        Text(
                          'Share Achievement',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Post your wins and earn credibility upvotes',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  Text(
                    'Category',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PostCategory.values.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat.label),
                        selected: isSelected,
                        onSelected: (_) {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedCategory = cat);
                        },
                        backgroundColor: Colors.grey[200],
                        selectedColor: AppTheme.accent,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                          fontSize: 13,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusSm,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? AppTheme.accent
                                : Colors.transparent,
                          ),
                        ),
                        showCheckmark: false,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  Text(
                    'Title',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextField(
                    controller: _titleController,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    maxLength: 80,
                    decoration: _inputDecoration(
                      hint: 'e.g. Won Smart India Hackathon 2026',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),

                  Text(
                    'Description (optional)',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                  TextField(
                    controller: _descController,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                    maxLines: 4,
                    maxLength: 500,
                    decoration: _inputDecoration(
                      hint: 'Tell us more about your achievement...',
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceLg),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _titleController.text.trim().isEmpty ||
                              _isSubmitting
                          ? null
                          : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.accent,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.08),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppTheme.radiusMd,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              'Post Achievement',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppTheme.spaceSm),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint}) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.3),
      hintText: hint,
      hintStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 14,
      ),
      counterStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.3),
        fontSize: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        borderSide: BorderSide(
          color: AppTheme.accent.withValues(alpha: 0.5),
        ),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 14,
      ),
    );
  }
}
