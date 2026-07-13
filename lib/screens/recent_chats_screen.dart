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

  String _selectedCategory = 'Tous';

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
    _applyFilters();
  }

  void _selectCategory(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _applyFilters();
  }

  void _applyFilters() {
    var temp = _allChats;

    if (_searchController.text.isNotEmpty) {
      setState(() => _isSearching = true);
      temp = temp.where((chat) {
        final name = (chat['name'] ?? '').toString().toLowerCase();
        return name.contains(_searchController.text.toLowerCase());
      }).toList();
    } else {
      setState(() => _isSearching = false);
    }

    if (_selectedCategory == 'Professeurs') {
      temp = temp.where((chat) {
        final role = (chat['role'] ?? '').toString().toLowerCase();
        return role.contains('prof');
      }).toList();
    } else if (_selectedCategory == 'Groupes') {
      temp = temp.where((chat) {
        final role = (chat['role'] ?? '').toString().toLowerCase();
        return role.contains('group') || role.contains('groupe');
      }).toList();
    }

    setState(() {
      _filteredChats = temp;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> categories = [
      {'name': 'Tous', 'icon': Icons.chat_bubble_outline},
      {'name': 'Professeurs', 'icon': Icons.school_outlined},
      {'name': 'Groupes', 'icon': Icons.groups_outlined},
    ];

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1E241E) : const Color(0xFFF9FAFB);
    final textColor = isDark ? Colors.white : const Color(0xFF1F2937);
    final subtitleColor = isDark ? Colors.white54 : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      drawer: const CustomSidebar(currentRoute: '/messagerie'),
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: ScreenHeader(title: 'Messages', showBackButton: false),
            ),
            const SizedBox(height: 16),

            // Search Bar with Filter Icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !isDark
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: GoogleFonts.poppins(
                          color: textColor,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Rechercher un professeur, un groupe...',
                          hintStyle: GoogleFonts.poppins(
                            color: subtitleColor,
                            fontSize: 13,
                          ),
                          prefixIcon: Icon(
                            Icons.search,
                            color: subtitleColor,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                        ),
                        onChanged: _filterChats,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Filter Categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: categories.map((catInfo) {
                  final cat = catInfo['name'] as String;
                  final icon = catInfo['icon'] as IconData;
                  final double? iconSize = catInfo['iconSize'] as double?;
                  final isSelected = _selectedCategory == cat;

                  return GestureDetector(
                    onTap: () => _selectCategory(cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF10B981) // Green for active
                            : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: !isDark && !isSelected
                            ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            icon,
                            size: iconSize ?? 16,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569)),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            cat,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark
                                        ? Colors.white
                                        : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),

            // Chat List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredChats.isEmpty
                  ? Center(
                      child: Text(
                        _isSearching
                            ? "Aucun résultat trouvé"
                            : "Aucune conversation trouvée",
                        style: GoogleFonts.poppins(
                          color: subtitleColor,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 32),
                      physics: const BouncingScrollPhysics(),
                      itemCount: _filteredChats.length,
                      itemBuilder: (context, index) {
                        final chat = _filteredChats[index];
                        return _buildChatCard(
                          chat,
                          index,
                          isDark,
                          textColor,
                          subtitleColor,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatCard(
    dynamic chat,
    int index,
    bool isDark,
    Color textColor,
    Color subtitleColor,
  ) {
    final int id = chat['id'] ?? 0;
    final String name = chat['name'] ?? 'Inconnu';
    final String role = (chat['role'] ?? 'Professeur').toString().toLowerCase();

    bool isOnline = chat['is_online'] == true;
    String timeStr = chat['last_seen_diff'] ?? 'Jamais';
    int unreadCount = chat['unread_count'] ?? 0;
    String lastMessage =
        chat['last_message'] ??
        (role.contains('group')
            ? 'Groupe de discussion'
            : 'Commencer la discussion');

    bool isPinned = false;
    bool isMuted = false;
    bool isStarred = false;
    bool isStarredFilled = false;
    String displayRole = chat['role'] != null
        ? chat['role'].toString()
        : 'Professeur';

    final bool hasUnread = unreadCount > 0;
    final String initials = name.isNotEmpty
        ? name.substring(0, 1).toUpperCase()
        : 'P';
    final String avatarUrl = chat['avatar_url'] ?? '';
    final String targetType = role.contains('group') ? 'group' : 'user';

    // Pastel backgrounds for avatars
    final List<Color> pastelColors = [
      const Color(0xFFD1FAE5), // Mint
      const Color(0xFFDCFCE7), // Greenish
      const Color(0xFFF3E8FF), // Purpleish
      const Color(0xFFFFEDD5), // Orangey
      const Color(0xFFDBEAFE), // Blueish
      const Color(0xFFFCE7F3), // Pinkish
    ];
    final Color avatarBg = isDark
        ? const Color(0xFF2C2C2C)
        : pastelColors[index % pastelColors.length];

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
      child: Container(
        margin: const EdgeInsets.only(left: 20, right: 20, bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: !isDark
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start, // Align to top slightly
            children: [
              // Avatar
              Stack(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      shape: BoxShape.circle,
                    ),
                    child: avatarUrl.isNotEmpty
                        ? ClipOval(
                            child: Image.network(avatarUrl, fit: BoxFit.cover),
                          )
                        : Center(
                            child:
                                role.contains('group') ||
                                    targetType == 'group' ||
                                    displayRole.contains('roupe')
                                ? Icon(
                                    Icons.groups,
                                    color: const Color(0xFF64748B),
                                    size: 28,
                                  )
                                : Text(
                                    initials,
                                    style: GoogleFonts.poppins(
                                      color: const Color(0xFF1F2937),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                          ),
                  ),
                  if (isOnline)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isDark
                                ? const Color(0xFF2C2C2C)
                                : Colors.white,
                            width: 2.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),

              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: hasUnread
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: const Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      displayRole,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: const Color(0xFF94A3B8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: hasUnread
                                  ? textColor
                                  : const Color(0xFF64748B),
                              fontWeight: hasUnread
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),

                        // Right Trailing Badges / Icons
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (hasUnread)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFD1FAE5,
                                  ), // Light green background
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  unreadCount.toString(),
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF10B981),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                            if (isPinned ||
                                isMuted ||
                                isStarred ||
                                isStarredFilled) ...[
                              const SizedBox(width: 8),
                              if (isPinned)
                                const Icon(
                                  Icons.push_pin_outlined,
                                  size: 16,
                                  color: Color(0xFF10B981),
                                ),
                              if (isMuted)
                                const Icon(
                                  Icons.notifications_off_outlined,
                                  size: 16,
                                  color: Color(0xFF94A3B8),
                                ),
                              if (isStarredFilled)
                                const Icon(
                                  Icons.star_rounded,
                                  size: 18,
                                  color: Color(0xFFFBBF24),
                                ),
                              if (isStarred)
                                const Icon(
                                  Icons.star_border_rounded,
                                  size: 18,
                                  color: Color(0xFF94A3B8),
                                ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
