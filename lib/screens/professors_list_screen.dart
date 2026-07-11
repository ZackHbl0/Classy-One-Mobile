import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import 'chat_screen.dart';
import '../widgets/screen_header.dart';

class ProfessorsListScreen extends StatefulWidget {
  const ProfessorsListScreen({super.key});

  @override
  State<ProfessorsListScreen> createState() => _ProfessorsListScreenState();
}

class _ProfessorsListScreenState extends State<ProfessorsListScreen> {
  final AuthService _authService = AuthService();
  List<dynamic> _professors = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfessors();
  }

  Future<void> _fetchProfessors() async {
    final profs = await _authService.getProfessors();
    if (mounted) {
      setState(() {
        _professors = profs;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          const ScreenHeader(title: 'Professeurs & Admin', showBackButton: true),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
          : _professors.isEmpty
              ? Center(
                  child: Text(
                    "Aucun professeur trouvé",
                    style: GoogleFonts.inter(
                      color: Colors.grey,
                      fontSize: 16,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _professors.length,
                  itemBuilder: (context, index) {
                    final prof = _professors[index];
                    return Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF2A322A) : Colors.white,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isDark ? Colors.white12 : Colors.grey.shade200,
                        ),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundColor:
                              const Color(0xFF708C70).withOpacity(0.1),
                          child: Text(
                            prof['name']?.substring(0, 1).toUpperCase() ?? 'P',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF708C70),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        title: Text(
                          prof['name'] ?? 'Inconnu',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Text(
                          prof['role'] ?? 'Professeur',
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.chat_bubble_outline,
                          color: Color(0xFF708C70),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatScreen(
                                receiverId: prof['id'],
                                receiverName: prof['name'] ?? 'Professeur',
                                isOnline: prof['is_online'] == true,
                                lastSeenDiff: prof['last_seen_diff'] ?? 'Jamais connecté',
                                targetType: prof['role'] == 'group' ? 'group' : 'user',
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}
