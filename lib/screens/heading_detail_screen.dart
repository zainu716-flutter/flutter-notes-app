import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/notes_provider.dart';
import 'column_detail_screen.dart';

class HeadingDetailScreen extends StatefulWidget {
  final Heading heading;

  const HeadingDetailScreen({super.key, required this.heading});

  @override
  State<HeadingDetailScreen> createState() => _HeadingDetailScreenState();
}

class _HeadingDetailScreenState extends State<HeadingDetailScreen> {
  late Heading _heading;
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _heading = widget.heading;
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
    // Keep heading synced from provider
    final headings = context.watch<NotesProvider>().headings;
    final updated = headings.where((h) => h.id == _heading.id).firstOrNull;
    if (updated != null) _heading = updated;

    final filtered = _heading.columns
        .where((c) =>
            c.title.toLowerCase().contains(_searchQuery) ||
            c.content.toLowerCase().contains(_searchQuery))
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: CustomScrollView(
        slivers: [
          // ── App Bar ────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0D0D14),
            leading: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    color: Colors.white, size: 18),
              ),
            ),
            actions: [
              _HeadingMenuButton(heading: _heading),
              const Gap(12),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16, right: 80),
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_heading.emoji, style: const TextStyle(fontSize: 22)),
                  const Gap(10),
                  Flexible(
                    child: Text(
                      _heading.title,
                      style: GoogleFonts.playfairDisplay(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 20,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              background: _HeaderBackground(),
            ),
          ),

          // ── Search Bar ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ColumnSearchBar(controller: _searchCtrl),
                  const Gap(10),
                  Text(
                    '${filtered.length} column${filtered.length == 1 ? '' : 's'}${_searchQuery.isNotEmpty ? ' found' : ''}',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1),
          ),

          // ── Columns list ───────────────────────────────────────────────────
          _heading.columns.isEmpty
              ? SliverFillRemaining(
                  child: _EmptyState(
                    onAdd: () => _showAddColumnSheet(context),
                  ),
                )
              : filtered.isEmpty
                  ? SliverFillRemaining(
                      child: _NoResultsState(query: _searchQuery),
                    )
                  : _searchQuery.isEmpty
                      // ── Reorderable (no search active) ──────────────────
                      ? SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          sliver: SliverReorderableList(
                            itemCount: _heading.columns.length,
                            onReorder: (oldIndex, newIndex) {
                              if (newIndex > oldIndex) newIndex--;
                              context
                                  .read<NotesProvider>()
                                  .reorderColumns(
                                    headingId: _heading.id,
                                    oldIndex: oldIndex,
                                    newIndex: newIndex,
                                  );
                            },
                            proxyDecorator:
                                (child, index, animation) =>
                                    _ColProxyDecorator(
                                      child: child,
                                      animation: animation,
                                    ),
                            itemBuilder: (ctx, i) =>
                                ReorderableDelayedDragStartListener(
                              key: ValueKey(
                                  _heading.columns[i].id),
                              index: i,
                              child: _ColumnCard(
                                column: _heading.columns[i],
                                index: i,
                                headingId: _heading.id,
                                isDraggable: true,
                                onTap: () => Navigator.push(
                                  context,
                                  _slide(ColumnDetailScreen(
                                    headingId: _heading.id,
                                    column: _heading.columns[i],
                                  )),
                                ),
                              ),
                            ),
                          ),
                        )
                      // ── Normal list (search active) ──────────────────────
                      : SliverPadding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (ctx, i) => _ColumnCard(
                                column: filtered[i],
                                index: i,
                                headingId: _heading.id,
                                isDraggable: false,
                                onTap: () => Navigator.push(
                                  context,
                                  _slide(ColumnDetailScreen(
                                    headingId: _heading.id,
                                    column: filtered[i],
                                  )),
                                ),
                              ),
                              childCount: filtered.length,
                            ),
                          ),
                        ),
        ],
      ),
      floatingActionButton: _AddColumnFAB(
        onTap: () => _showAddColumnSheet(context),
      ),
    );
  }

  void _showAddColumnSheet(BuildContext context) {
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColumnFormSheet(
        title: 'New Column',
        titleCtrl: titleCtrl,
        contentCtrl: contentCtrl,
        onSave: () {
          if (titleCtrl.text.trim().isEmpty) return;
          // ✅ Pop FIRST — never await Firebase before closing
          Navigator.pop(context);
          context.read<NotesProvider>().addColumn(
                headingId: _heading.id,
                title: titleCtrl.text.trim(),
                content: contentCtrl.text.trim(),
              );
        },
      ),
    );
  }

  void _showEditColumnSheet(BuildContext context, NoteColumn col) {
    final titleCtrl = TextEditingController(text: col.title);
    final contentCtrl = TextEditingController(text: col.content);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ColumnFormSheet(
        title: 'Edit Column',
        titleCtrl: titleCtrl,
        contentCtrl: contentCtrl,
        onSave: () {
          if (titleCtrl.text.trim().isEmpty) return;
          col.title = titleCtrl.text.trim();
          col.content = contentCtrl.text.trim();
          // ✅ Pop FIRST — never await Firebase before closing
          Navigator.pop(context);
          context.read<NotesProvider>().updateColumn(
                headingId: _heading.id,
                column: col,
              );
        },
      ),
    );
  }

  Future<void> _deleteColumn(BuildContext context, String columnId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Column',
            style: GoogleFonts.playfairDisplay(color: Colors.white)),
        content: Text('This action cannot be undone.',
            style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child:
                Text('Cancel', style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // ✅ Firebase runs in background — no await
      context.read<NotesProvider>().deleteColumn(
            headingId: _heading.id,
            columnId: columnId,
          );
    }
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

// ─── Sub-widgets ──────────────────────────────────────────────────────────────

// ─── Column Search Bar ────────────────────────────────────────────────────────

class _ColumnSearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _ColumnSearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: TextField(
        controller: controller,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search columns...',
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
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
                    Text(
                      'No columns match "$query"',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 15,
                          fontWeight: FontWeight.w500),
                    ),
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

class _HeaderBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E1E32), Color(0xFF0D0D14)],
        ),
      ),
      child: Stack(children: [
        Positioned(
          right: -40,
          top: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF7C83E8).withOpacity(0.07),
            ),
          ),
        ),
        Positioned(
          left: -20,
          bottom: 30,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFE8A87C).withOpacity(0.06),
            ),
          ),
        ),
      ]),
    );
  }
}

// ─── Column Proxy Decorator ───────────────────────────────────────────────────

class _ColProxyDecorator extends StatelessWidget {
  final Widget child;
  final Animation<double> animation;

  const _ColProxyDecorator(
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
          child: Opacity(opacity: 0.88, child: child),
        ),
      ),
    );
  }
}

// ─── Column Card ──────────────────────────────────────────────────────────────

class _ColumnCard extends StatelessWidget {
  final NoteColumn column;
  final int index;
  final String headingId;
  final VoidCallback onTap;
  final bool isDraggable;

  const _ColumnCard({
    required this.column,
    required this.index,
    required this.headingId,
    required this.onTap,
    this.isDraggable = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF16161F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _cardColor(index).withOpacity(0.15),
                    Colors.transparent,
                  ],
                ),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  // Drag handle
                  if (isDraggable) ...[
                    Icon(Icons.drag_indicator_rounded,
                        color: Colors.white.withOpacity(0.2), size: 18),
                    const Gap(8),
                  ],

                  // Number badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: _cardColor(index).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: GoogleFonts.inter(
                          color: _cardColor(index),
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Text(
                      column.title,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: _cardColor(index).withOpacity(0.5),
                    size: 14,
                  ),
                ],
              ),
            ),

            // Content preview
            if (column.content.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Text(
                  column.content,
                  style: GoogleFonts.lora(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 14,
                    height: 1.6,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 4, 18, 16),
                child: Text(
                  'Tap to view full content →',
                  style: GoogleFonts.inter(
                      color: Colors.white24,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: (index * 60).ms)
          .slideX(begin: 0.1, curve: Curves.easeOutCubic),
    );
  }

  Color _cardColor(int i) {
    const colors = [
      Color(0xFFE8A87C),
      Color(0xFF7C83E8),
      Color(0xFF7CE8C4),
      Color(0xFFE87C9A),
      Color(0xFFE8D87C),
    ];
    return colors[i % colors.length];
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

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
                          color: const Color(0xFFE8A87C).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.view_column_rounded,
                            color: Color(0xFFE8A87C), size: 36),
                      ),
                      const Gap(16),
                    ],
                    Text('No columns yet',
                        style: GoogleFonts.playfairDisplay(
                            color: Colors.white70,
                            fontSize: 20,
                            fontWeight: FontWeight.w600)),
                    const Gap(6),
                    Text('Tap + to add your first column',
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
                        ),
                        child: Text('Add Column',
                            style: GoogleFonts.inter(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.9, 0.9)),
        );
      },
    );
  }
}

class _AddColumnFAB extends StatelessWidget {
  final VoidCallback onTap;
  const _AddColumnFAB({required this.onTap});

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
              color: const Color(0xFFE8A87C).withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, color: Colors.white, size: 20),
            const Gap(8),
            Text('Add Column',
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

class _HeadingMenuButton extends StatelessWidget {
  final Heading heading;
  const _HeadingMenuButton({required this.heading});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      // ✅ This stops PopupMenu from overriding child text colors
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.all(Colors.white),
      ),
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.more_vert_rounded,
            color: Colors.white, size: 18),
      ),
      onSelected: (val) {
        if (val == 'edit') _showEditHeadingSheet(context);
        if (val == 'delete') _deleteHeading(context);
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'edit',
          child: Row(children: [
            const Icon(Icons.edit_rounded, color: Color(0xFFE8A87C), size: 18),
            const Gap(10),
            Text('Edit Heading',
                style: GoogleFonts.inter(color: Colors.white)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            const Icon(Icons.delete_rounded,
                color: Colors.red, size: 18),
            const Gap(10),
            Text('Delete Heading',
                style: GoogleFonts.inter(color: Colors.red)),
          ]),
        ),
      ],
    );
  }

  void _showEditHeadingSheet(BuildContext context) {
    final titleCtrl = TextEditingController(text: heading.title);
    final emojiCtrl = TextEditingController(text: heading.emoji);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _HeadingFormSheet(
        title: 'Edit Heading',
        titleCtrl: titleCtrl,
        emojiCtrl: emojiCtrl,
        onSave: () {
          if (titleCtrl.text.trim().isEmpty) return;
          heading.title = titleCtrl.text.trim();
          heading.emoji = emojiCtrl.text.trim().isEmpty
              ? '📝'
              : emojiCtrl.text.trim();
          // ✅ Pop FIRST — never await Firebase before closing
          Navigator.pop(context);
          context.read<NotesProvider>().updateHeading(heading);
        },
      ),
    );
  }

  void _deleteHeading(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Delete Heading',
            style: GoogleFonts.playfairDisplay(color: Colors.white)),
        content: Text(
            'This will delete the heading and all its columns.',
            style: GoogleFonts.inter(color: Colors.white54)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirm == true && context.mounted) {
      // ✅ Pop screen first, Firebase runs in background
      Navigator.pop(context);
      context.read<NotesProvider>().deleteHeading(heading.id);
    }
  }
}

// ─── Shared form sheet ────────────────────────────────────────────────────────

class _ColumnFormSheet extends StatelessWidget {
  final String title;
  final TextEditingController titleCtrl;
  final TextEditingController contentCtrl;
  final VoidCallback onSave;

  const _ColumnFormSheet({
    required this.title,
    required this.titleCtrl,
    required this.contentCtrl,
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
            _buildField(titleCtrl, 'Column Title', Icons.title_rounded),
            const Gap(14),
            _buildField(contentCtrl, 'Content (optional)',
                Icons.notes_rounded,
                maxLines: 6),
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
                child: Text('Save',
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
    TextEditingController ctrl,
    String hint,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.white38),
        prefixIcon: maxLines == 1
            ? Icon(icon,
                color: const Color(0xFFE8A87C).withOpacity(0.7), size: 20)
            : null,
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
                child: Text('Save',
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