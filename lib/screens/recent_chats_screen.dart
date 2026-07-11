import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_screen.dart';
import '../services/auth_service.dart';
import '../widgets/screen_header.dart';
import '../widgets/custom_sidebar.dart';


class RecentChatsScreen extends StatefulWidget {
  const RecentChatsScreen({super.key});

  @override
  State<RecentChatsScreen> createState() => _RecentChatsScreenState();
}

class _RecentChatsScreenState extends State<RecentChatsScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _allChats = [];
  List<dynamic> _filteredChats = [];
  bool _isLoading = true;

  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchChats();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchChats() async {
    try {
      final profs = await _authService.getProfessors();
      if (mounted) {
        setState(() {
          _allChats = profs;
          _filteredChats = profs;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _filterChats(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredChats = _allChats;
      });
    } else {
      setState(() {
        _filteredChats = _allChats.where((chat) {
          final name = (chat['name'] ?? '').toString().toLowerCase();
          return name.contains(query.toLowerCase());
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = Theme.of(context).scaffoldBackgroundColor;
    final textColor = isDark ? Colors.white : const Color(0xFF2A322A);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF94A3B8);

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1E241E)
          : const Color(0xFFF6F7F2),
      drawer: const CustomSidebar(currentRoute: '/messagerie'),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 32, 20, 0),
            child: ScreenHeader(title: 'Messages', showBackButton: false),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A322A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                style: GoogleFonts.inter(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Rechercher un professeur...',
                  hintStyle: GoogleFonts.inter(color: subtitleColor),
                  prefixIcon: Icon(Icons.search, color: subtitleColor),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
                onChanged: _filterChats,
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
          : _filteredChats.isEmpty
              ? Center(
                  child: Text(
                    _isSearching ? "Aucun résultat trouvé" : "Aucune conversation trouvée",
                    style: GoogleFonts.plusJakartaSans(
                      color: subtitleColor,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 32),
                  itemCount: _filteredChats.length,
                  itemBuilder: (context, index) {
                    final chat = _filteredChats[index];
                    return _buildChatItem(chat, isDark, textColor, subtitleColor);
                  },
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatItem(dynamic chat, bool isDark, Color textColor, Color subtitleColor) {
    // Determine dynamic values from the API response
    final int id = chat['id'] ?? 0;
    final String name = chat['name'] ?? 'Inconnu';
    final String role = chat['role'] ?? 'Professeur';
    final bool isOnline = chat['is_online'] == true;
    final String timeStr = chat['last_seen_diff'] ?? 'Jamais';
    final String targetType = chat['role'] == 'group' ? 'group' : 'user';
    
    // We don't have unread count from this endpoint yet, but we can set it to 0
    final int unreadCount = chat['unread_count'] ?? 0;
    final bool hasUnread = unreadCount > 0;
    final String initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'P';
    final String avatarUrl = chat['avatar_url'] ?? '';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: id,
              receiverName: name,
              isOnline: isOnline,
              lastSeenDiff: timeStr,
              targetType: targetType,
            ),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar with Online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark ? const Color(0xFF2A322A) : const Color(0xFFE2E5E0),
                  backgroundImage: avatarUrl.isNotEmpty ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          initials,
                          style: GoogleFonts.plusJakartaSans(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        )
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981), // Emerald green
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          width: 2.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 16),
            // Message Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      Text(
                        timeStr,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: subtitleColor,
                          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          // Use last_message if available, otherwise show role
                          chat['last_message'] ?? role,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: hasUnread ? textColor : subtitleColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                            height: 1.4,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor, // Blue badge
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ]
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
