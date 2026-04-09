import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';

class PhoneUpdatePage extends StatefulWidget {
  const PhoneUpdatePage({super.key});

  @override
  State<PhoneUpdatePage> createState() => _PhoneUpdatePageState();
}

class _PhoneUpdatePageState extends State<PhoneUpdatePage> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadCurrentPhone();
  }

  Future<void> _loadCurrentPhone() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _phoneController.text = prefs.getString('telephone') ?? '';
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final idStudent = prefs.getInt('idStudent') ?? 0;

    final result = await _authService.updatePhone(
      idStudent,
      _phoneController.text,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success'] == true) {
        await prefs.setString('telephone', _phoneController.text);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('phone_update.success'.tr())),
        );
        Navigator.pop(context, true); // Return true to indicate success
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
      appBar: AppBar(title: Text('phone_update.title'.tr()), elevation: 0),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'phone_update.description'.tr(),
                style: const TextStyle(color: Color(0xFF64748B), height: 1.5),
              ),
              const SizedBox(height: 32),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty)
                    return 'phone_update.enter_number'.tr();
                  return null;
                },
                decoration: InputDecoration(
                  labelText: 'phone_update.label'.tr(),
                  prefixIcon: const Icon(Icons.phone_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF203B68),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'phone_update.submit'.tr(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
