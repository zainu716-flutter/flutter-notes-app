import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/notes_provider.dart';

class ColumnDetailScreen extends StatelessWidget {
  final String headingId;
  final NoteColumn column;

  const ColumnDetailScreen({
    super.key,
    required this.headingId,
    required this.column,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D14),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
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
              _EditAction(headingId: headingId, column: column),
              const Gap(8),
              _DeleteAction(headingId: headingId, column: column),
              const Gap(16),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
                  const EdgeInsets.only(left: 20, bottom: 16, right: 20),
              title: Text(
                column.title,
                style: GoogleFonts.playfairDisplay(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1A1A2E), Color(0xFF0D0D14)],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -30,
                      child: Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFFE8A87C).withOpacity(0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20,
                      bottom: 40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF7C83E8).withOpacity(0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta info
                  Row(
                    children: [
                      _MetaChip(
                        icon: Icons.calendar_today_rounded,
                        label: _formatDate(column.createdAt),
                      ),
                      const Gap(8),
                      _MetaChip(
                        icon: Icons.edit_rounded,
                        label: 'Edited ${_formatDate(column.updatedAt)}',
                      ),
                    ],
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),

                  const Gap(28),

                  // Content
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.06),
                      ),
                    ),
                    child: Text(
                      column.content.isEmpty
                          ? 'No content yet. Tap edit to add some.'
                          : column.content,
                      style: GoogleFonts.lora(
                        color: column.content.isEmpty
                            ? Colors.white38
                            : Colors.white.withOpacity(0.85),
                        fontSize: 17,
                        height: 1.8,
                        fontStyle: column.content.isEmpty
                            ? FontStyle.italic
                            : FontStyle.normal,
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

                  const Gap(40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: const Color(0xFFE8A87C)),
          const Gap(6),
          Text(
            label,
            style: GoogleFonts.inter(
              color: Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditAction extends StatelessWidget {
  final String headingId;
  final NoteColumn column;

  const _EditAction({required this.headingId, required this.column});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showEditDialog(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFE8A87C).withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFFE8A87C).withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFFE8A87C), size: 14),
            const Gap(6),
            Text('Edit',
                style: GoogleFonts.inter(
                    color: const Color(0xFFE8A87C),
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    final titleCtrl = TextEditingController(text: column.title);
    final contentCtrl = TextEditingController(text: column.content);

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
          column.title = titleCtrl.text.trim();
          column.content = contentCtrl.text.trim();
          // ✅ Pop sheet + detail screen first
          Navigator.pop(context); // close sheet
          Navigator.pop(context); // close detail
          context.read<NotesProvider>().updateColumn(
                headingId: headingId,
                column: column,
              );
        },
      ),
    );
  }
}

class _DeleteAction extends StatelessWidget {
  final String headingId;
  final NoteColumn column;

  const _DeleteAction({required this.headingId, required this.column});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _confirmDelete(context),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.red.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.delete_rounded, color: Colors.red, size: 14),
            const Gap(6),
            Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: GoogleFonts.inter(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () {
              // ✅ Pop all screens first, Firebase runs in background
              Navigator.pop(context);  // close dialog
              Navigator.pop(context);  // close detail screen
              context.read<NotesProvider>().deleteColumn(
                    headingId: headingId,
                    columnId: column.id,
                  );
            },
            child: Text('Delete',
                style: GoogleFonts.inter(
                    color: Colors.red, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// Shared form sheet used by edit
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
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
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
                  borderRadius: BorderRadius.circular(2),
                ),
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
            _buildField(contentCtrl, 'Content', Icons.notes_rounded,
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
        prefixIcon:
            Icon(icon, color: const Color(0xFFE8A87C).withOpacity(0.7), size: 20),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE8A87C), width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}