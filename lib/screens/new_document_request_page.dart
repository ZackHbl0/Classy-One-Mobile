import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';

class NewDocumentRequestPage extends StatefulWidget {
  const NewDocumentRequestPage({super.key});

  @override
  State<NewDocumentRequestPage> createState() => _NewDocumentRequestPageState();
}

class _NewDocumentRequestPageState extends State<NewDocumentRequestPage> {
  final AuthService _authService = AuthService();
  final _reasonController = TextEditingController();

  String _selectedDocType = 'Certificat de scolarité';
  String _selectedUrgency = 'normal';
  bool _isSubmitting = false;

  final List<String> _docTypes = [
    'Certificat de scolarité',
    'Attestation d\'inscription',
    'Relevé de notes',
    'Convention de stage',
    'Autre',
  ];

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _submitRequest() async {
    setState(() {
      _isSubmitting = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.createDocumentRequest(
      idStudent,
      _selectedDocType,
      _reasonController.text,
      _selectedUrgency,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });
      if (result['success'] == true) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF10B981),
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Demande envoyée !',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Votre demande a été envoyée à l\'administration.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context, true); // Go back with refresh flag
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF203B68),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      'Compris',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Erreur')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Nouvelle demande',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF1E293B),
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Type de document'),
            _buildDropdown(
              value: _selectedDocType,
              items: _docTypes,
              onChanged: (val) => setState(() => _selectedDocType = val!),
            ),

            const SizedBox(height: 24),

            _buildLabel('Niveau d\'urgence'),
            Row(
              children: [
                _buildUrgencyChip('Normal', 'normal', const Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                _buildUrgencyChip('Urgent', 'urgent', const Color(0xFFEF4444)),
              ],
            ),

            const SizedBox(height: 24),

            _buildLabel('Motif (Optionnel)'),
            TextField(
              controller: _reasonController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Ex: Besoin pour dossier de stage...',
                hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 48),

            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF203B68),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'ENVOYER LA DEMANDE',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          items: items
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildUrgencyChip(String label, String value, Color activeColor) {
    final bool isSelected = _selectedUrgency == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedUrgency = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.1)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? activeColor : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? activeColor : const Color(0xFF64748B),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
