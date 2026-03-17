import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart' as ap;
import '../providers/notes_provider.dart';
import 'heading_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<NotesProvider>().listenToHeadings();
    });
    _searchCtrl.addListener(() {
      setState(() => _searchQuery = _searchCtrl.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotesProvider>();

    final filtered = provider.headings
        .where((h) => h.title.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      // ── Offline banner ──────────────────────────────────────────────────────
      bottomNavigationBar: provider.isOffline
          ? Container(
              color: const Color(0xFF1A1A1A),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.orange, size: 14),
                  const Gap(6),
                  Text(
                    'Offline — showing cached data',
                    style: GoogleFonts.inter(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            )
          : null,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            expandedHeight: 130,
            backgroundColor: const Color(0xFF0D0D14),
            surfaceTintColor: Colors.transparent,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
              title: Text(
                'My Notes',
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              background: _AppBarBackground(),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.auto_awesome_rounded,
                        color: Color(0xFFE8A87C), size: 14),
                    const Gap(6),
                    Text(
                      '${provider.headings.length} headings',
                      style: GoogleFonts.inter(
                          color: Colors.white54, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              GestureDetector(
                onTap: () => _confirmSignOut(context),
                child: Container(
                  margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.logout_rounded,
                      color: Colors.white54, size: 18),
                ),
              ),
            ],
          ),

          // ── Search Bar ────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: _SearchBar(
                controller: _searchCtrl,
                hint: 'Search headings...',
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),

          // ── Content ───────────────────────────────────────────────────────
          if (provider.isLoading)
            const SliverFillRemaining(child: _LoadingState())
          else if (provider.headings.isEmpty)
            SliverFillRemaining(
              child: _EmptyHomeState(
                  onAdd: () => _showAddHeadingSheet(context)),
            )
          else if (filtered.isEmpty)
            SliverFillRemaining(
              child: _NoResultsState(query: _searchQuery),
            )
          // ── Reorderable list (only when not searching) ───────────────────
          else if (_searchQuery.isEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverReorderableList(
                itemCount: provider.headings.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;
                  context
                      .read<NotesProvider>()
                      .reorderHeadings(oldIndex, newIndex);
                },
                proxyDecorator: (child, index, animation) =>
                    _ProxyDecorator(child: child, animation: animation),
                itemBuilder: (ctx, i) => ReorderableDelayedDragStartListener(
                  key: ValueKey(provider.headings[i].id),
                  index: i,
                  child: _HeadingListTile(
                    heading: provider.headings[i],
                    index: i,
                    isDraggable: true,
                    onTap: () => Navigator.push(
                      context,
                      _slide(HeadingDetailScreen(
                          heading: provider.headings[i])),
                    ),
                  ),
                ),
              ),
            )
          // ── Normal list when searching ────────────────────────────────────
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _HeadingListTile(
                    heading: filtered[i],
                    index: i,
                    isDraggable: false,
                    onTap: () => Navigator.push(
                      context,
                      _slide(HeadingDetailScreen(heading: filtered[i])),
                    ),
                  ),
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _AddHeadingFAB(
        onTap: () => _showAddHeadingSheet(context),
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Sign Out',
            style: GoogleFonts.playfairDisplay(color: Colors.white)),
        content: Text('Are you sure you want to sign out?',
            style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Sign Out',
                style: GoogleFonts.inter(
                    color: const Color(0xFFE8A87C),
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      await context.read<ap.AuthProvider>().signOut();
    }
  }

  void _showAddHeadingSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final emojiCtrl = TextEditingController(text: '📝');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HeadingFormSheet(
        title: 'New Heading',
        titleCtrl: titleCtrl,
        emojiCtrl: emojiCtrl,
        onSave: () {
          if (titleCtrl.text.trim().isEmpty) return;
          // ✅ Pop FIRST — never await Firebase before closing
          Navigator.pop(context);
          context.read<NotesProvider>().addHeading(
                title: titleCtrl.text.trim(),
                emoji: emojiCtrl.text.trim().isEmpty
                    ? '📝'
                    : emojiCtrl.text.trim(),
              );
        },
      ),
    );
  }

  PageRoute _slide(Widget page) => PageRouteBuilder(
        pageBuilder: (_, a, __) => page,
        transitionsBuilder: (_, a, __, child) => SlideTransition(
          position: Tween(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: a, curve: Curves.easeOutCubic)),
          child: child,
        ),
      );
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _SearchBar({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded,
              color: Color(0xFFE8A87C), size: 20),
          suffixIcon: controller.text.isNotEmpty
              ? GestureDetector(
                  onTap: () => controller.clear(),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white38, size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
}

// ─── No Results ───────────────────────────────────────────────────────────────

class _NoResultsState extends StatelessWidget {
  final String query;
  const _NoResultsState({required this.query});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.search_off_rounded,
                          color: Colors.white24, size: 32),
                    ),
                    const Gap(14),
                    Text('No results for "$query"',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            color: Colors.white54,
                            fontSize: 15,
                            fontWeight: FontWeight.w500)),
                    const Gap(6),
                    Text('Try a different search term',
                        style: GoogleFonts.inter(
                            color: Colors.white24, fontSize: 13)),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 300.ms),
        );
      },
    );
  }
}

// ─── App Bar Background ───────────────────────────────────────────────────────

class _AppBarBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A1A2E), Color(0xFF0D0D14)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: 20,
          top: 20,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                const Color(0xFFE8A87C).withOpacity(0.12),
                Colors.transparent,
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Proxy Decorator (drag shadow) ───────────────────────────────────────────

class _ProxyDecorator extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _ProxyDecorator(
      {required this.child, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) => Material(
        color: Colors.transparent,
        elevation: 0,
        child: Transform.scale(
          scale: 1.03,
          child: Opacity(opacity: 0.9, child: child),
        ),
      ),
    );
  }
}

// ─── Heading List Tile ────────────────────────────────────────────────────────

class _HeadingListTile extends StatelessWidget {
  final Heading heading;
  final int index;
  final VoidCallback onTap;
  final bool isDraggable;

  const _HeadingListTile({
    required this.heading,
    required this.index,
    required this.onTap,
    this.isDraggable = true,
  });

  static const _accentColors = [
    Color(0xFFE8A87C),
    Color(0xFF7C83E8),
    Color(0xFF7CE8C4),
    Color(0xFFE87C9A),
    Color(0xFFE8D87C),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = _accentColors[index % _accentColors.length];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(22),
            splashColor: accent.withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Drag handle
                  if (isDraggable) ...[
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.drag_indicator_rounded,
                            color: Colors.white.withOpacity(0.2), size: 20),
                      ],
                    ),
                    const Gap(10),
                  ],

                  // Emoji bubble
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: accent.withOpacity(0.2), width: 1.5),
                    ),
                    child: Center(
                      child: Text(heading.emoji,
                          style: const TextStyle(fontSize: 26)),
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          heading.title,
                          style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 18,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Gap(4),
                        Row(
                          children: [
                            Icon(Icons.view_column_rounded,
                                size: 13, color: accent.withOpacity(0.7)),
                            const Gap(4),
                            Text(
                              '${heading.columns.length} column${heading.columns.length == 1 ? '' : 's'}',
                              style: GoogleFonts.inter(
                                  color: Colors.white38, fontSize: 12),
                            ),
                            const Gap(12),
                            const Icon(Icons.schedule_rounded,
                                size: 13, color: Colors.white24),
                            const Gap(4),
                            Text(
                              _relativeTime(heading.updatedAt),
                              style: GoogleFonts.inter(
                                  color: Colors.white24, fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.arrow_forward_ios_rounded,
                        color: accent, size: 14),
                  ),
                ],
              ),
            ),
          ),
        ),
      )
          .animate()
          .fadeIn(delay: (index * 60).ms)
          .slideX(begin: 0.08, curve: Curves.easeOutCubic),
    );
  }

  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}

// ─── Loading State ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFFE8A87C),
            ),
          ),
          const Gap(16),
          Text('Loading notes...',
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 14)),
        ],
      ),
    );
  }
}

// ─── Empty Home State ─────────────────────────────────────────────────────────

class _EmptyHomeState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyHomeState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmall = constraints.maxHeight < 300;
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isSmall) ...[
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8A87C), Color(0xFFE87C9A)],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE8A87C).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.note_add_rounded,
                            color: Colors.white, size: 36),
                      ),
                      const Gap(16),
                    ],
                    Text('Start your first note',
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w700)),
                    const Gap(6),
                    Text('Tap + to create a heading',
                        style: GoogleFonts.inter(
                            color: Colors.white38, fontSize: 13)),
                    const Gap(24),
                    GestureDetector(
                      onTap: onAdd,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE8A87C), Color(0xFFE87C9A)],
                          ),
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  const Color(0xFFE8A87C).withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Text('Create Heading',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.9, 0.9)),
        );
      },
    );
  }
}

// ─── Add Heading FAB ──────────────────────────────────────────────────────────

class _AddHeadingFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _AddHeadingFAB({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8A87C), Color(0xFFE87C9A)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE8A87C).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 22),
            const Gap(8),
            Text('New Heading',
                style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

// ─── Heading Form Sheet ───────────────────────────────────────────────────────

class _HeadingFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController titleCtrl;
  final TextEditingController emojiCtrl;
  final VoidCallback onSave;

  const _HeadingFormSheet({
    required this.title,
    required this.titleCtrl,
    required this.emojiCtrl,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF16161F),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
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
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Gap(20),
            Text(title,
                style: GoogleFonts.playfairDisplay(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700)),
            const Gap(20),
            _buildField(emojiCtrl, 'Emoji (e.g. 📝)', Icons.emoji_emotions_rounded),
            const Gap(14),
            _buildField(titleCtrl, 'Heading Title', Icons.title_rounded),
            const Gap(20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE8A87C),
                  foregroundColor: const Color(0xFF0D0D14),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text('Create',
                    style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
      TextEditingController ctrl, String hint, IconData icon) {
    return TextField(
      controller: ctrl,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38),
        prefixIcon: Icon(icon,
            color: const Color(0xFFE8A87C).withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide:
              const BorderSide(color: Color(0xFFE8A87C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}