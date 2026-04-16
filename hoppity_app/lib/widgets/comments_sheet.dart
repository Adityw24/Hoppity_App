import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/community.dart';
import '../services/community_service.dart';
import '../theme/app_theme.dart';

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({super.key, required this.postId});

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  final _controller = TextEditingController();
  List<PostComment> _comments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final c = await CommunityService.fetchComments(widget.postId);
    if (mounted) setState(() { _comments = c; _loading = false; });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    await CommunityService.addComment(widget.postId, text);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Text('Comments', style: GoogleFonts.figtree(fontSize: 16, fontWeight: FontWeight.w700)),
          const Divider(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _comments.isEmpty
                    ? Center(child: Text('No comments yet. Be first!', style: GoogleFonts.figtree(color: Colors.grey)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _comments.length,
                        itemBuilder: (_, i) {
                          final c = _comments[i];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: c.authorAvatarUrl != null
                                      ? CachedNetworkImageProvider(c.authorAvatarUrl!) : null,
                                  child: c.authorAvatarUrl == null ? const Icon(Icons.person, size: 16) : null,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(c.authorName ?? 'User', style: GoogleFonts.figtree(fontWeight: FontWeight.w700, fontSize: 13)),
                                      Text(c.content, style: GoogleFonts.figtree(fontSize: 14)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
          const Divider(height: 1),
          Padding(
            padding: EdgeInsets.only(
              left: 16, right: 16, top: 8,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Add a comment...',
                      hintStyle: GoogleFonts.figtree(color: Colors.grey),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(25)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppTheme.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
