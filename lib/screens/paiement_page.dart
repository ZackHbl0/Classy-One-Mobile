import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../widgets/screen_header.dart';
import 'package:provider/provider.dart';
import '../providers/payment_provider.dart';

class PaiementPage extends StatefulWidget {
  final bool? showBackButton;
  const PaiementPage({super.key, this.showBackButton = false});

  @override
  State<PaiementPage> createState() => _PaiementPageState();
}

class _PaiementPageState extends State<PaiementPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final prefs = await SharedPreferences.getInstance();
      final idStudent = prefs.getInt('idStudent') ?? 0;
      if (idStudent != 0) {
        context.read<PaymentProvider>().fetchPaymentData(idStudent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (context, paymentProvider, child) {
        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _buildContent(paymentProvider),
        );
      },
    );
  }

  Widget _buildContent(PaymentProvider paymentProvider) {
    if (paymentProvider.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF2A8B5B)));
    }

    if (paymentProvider.errorMessage.isNotEmpty) {
      return _buildErrorState(paymentProvider);
    }

    final paymentData = paymentProvider.paymentData;
    if (paymentData == null) {
      return const Center(child: Text('Aucune donnée de paiement', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 16)));
    }

    final currentProgression = paymentProvider.progression;
    
    // Derived stats
    final formatter = NumberFormat("#,##0", "fr_FR");
    final totalRestant = paymentProvider.targetAmount - paymentProvider.totalPaid;
    final formattedRestant = "${formatter.format(totalRestant).replaceAll(',', ' ')} MAD";
    
    final tranches = (paymentData['tranches'] ?? []) as List;
    String nextDate = 'Aucune';
    try {
      final nextTranche = tranches.firstWhere((t) => t['status'] != 'Payé');
      nextDate = nextTranche['dueDate'] ?? 'Aucune';
    } catch (_) {}

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsetsDirectional.only(top: 32.0, start: 20.0, end: 20.0, bottom: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ScreenHeader(title: 'Paiements', showBackButton: widget.showBackButton ?? false),
            const SizedBox(height: 24),
            
            _buildHeroCard(paymentProvider, currentProgression),
            const SizedBox(height: 24),
            
            _buildStatsRow(paymentProvider.formattedTotalPaid, formattedRestant, nextDate, "${currentProgression.toInt()}%", isDark),
            const SizedBox(height: 32),
            
            _buildHistoriqueHeader(isDark),
            const SizedBox(height: 20),
            
            ...tranches.asMap().entries.map((entry) {
               return _buildTrancheCard(entry.value, isDark, isLast: entry.key == tranches.length - 1);
            }).toList(),
            

          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard(PaymentProvider provider, double progression) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2A8B5B), Color(0xFF1B4E3B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2A8B5B).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text('Total payé', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                  const SizedBox(width: 6),
                  const Icon(Icons.info_outline, color: Colors.white70, size: 16),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                provider.formattedTotalPaid.replaceAll(' MAD', ''),
                style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold, height: 1),
              ),
              const SizedBox(width: 8),
              const Text(
                'MAD',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF137E4C),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.arrow_upward, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text('+12% ce mois', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Progression : ${progression.toInt()}%', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Cible', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w500)),
                  Text(provider.formattedTargetAmount, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            height: 6,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                if (progression > 0)
                  Flexible(
                    flex: progression.toInt(),
                    child: Container(decoration: BoxDecoration(color: const Color(0xFF7FF3A1), borderRadius: BorderRadius.circular(10))),
                  ),
                if (100 - progression.toInt() > 0)
                  Flexible(flex: 100 - progression.toInt(), child: Container()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(String totalPaye, String totalRestant, String prochaineEch, String taux, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A322A) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatItem(Icons.trending_up, const Color(0xFFE8F5E9), const Color(0xFF2A8B5B), 'Total payé', totalPaye, const Color(0xFF2A8B5B), isDark),
          _buildVerticalDivider(),
          _buildStatItem(Icons.account_balance_wallet_outlined, const Color(0xFFF3E8FF), const Color(0xFF9333EA), 'Total restant', totalRestant, const Color(0xFF9333EA), isDark),
          _buildVerticalDivider(),
          _buildStatItem(Icons.calendar_today_outlined, const Color(0xFFE0F2FE), const Color(0xFF0284C7), 'Prochaine échéance', prochaineEch, const Color(0xFF0284C7), isDark),
          _buildVerticalDivider(),
          _buildStatItem(Icons.percent, const Color(0xFFFFF7ED), const Color(0xFFEA580C), 'Taux de paiement', taux, const Color(0xFFEA580C), isDark),
        ],
      ),
    );
  }

  Widget _buildStatItem(IconData icon, Color bgColor, Color iconColor, String title, String value, Color valueColor, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: isDark ? bgColor.withOpacity(0.1) : bgColor, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(title, textAlign: TextAlign.center, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text(value, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: valueColor)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.grey.withOpacity(0.2),
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
    );
  }

  Widget _buildHistoriqueHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Historique des paiements',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF1F2937)),
        ),

      ],
    );
  }

  Widget _buildTrancheCard(dynamic tranche, bool isDark, {bool isLast = false}) {
    String status = tranche['status'] ?? 'En attente';
    Color statusColor = _getStatutColor(status);
    bool isPaid = status == 'Payé';

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline indicator
          SizedBox(
            width: 24,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isLast)
                  Positioned(
                    top: 24,
                    bottom: -20,
                    child: Container(width: 1, color: Colors.grey.withOpacity(0.3)),
                  ),
                Positioned(
                  top: 24,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: isPaid ? const Color(0xFF3BBE7A) : (isDark ? const Color(0xFF2A322A) : Colors.white),
                      shape: BoxShape.circle,
                      border: isPaid ? null : Border.all(color: Colors.grey.shade400, width: 2),
                    ),
                    child: isPaid ? const Icon(Icons.check, color: Colors.white, size: 10) : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2A322A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.credit_card, color: Color(0xFF2A8B5B), size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tranche['title'] ?? '',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 11, color: Color(0xFF6B7280)),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                'Échéance : ${tranche['dueDate']}',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            tranche['amount'] ?? '',
                            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: isDark ? Colors.white : const Color(0xFF1F2937)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(status, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 10)),
                              if (isPaid) ...[
                                const SizedBox(width: 4),
                                Icon(Icons.check, size: 10, color: statusColor),
                              ]
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatutColor(String status) {
    switch (status) {
      case 'Payé': return const Color(0xFF3BBE7A);
      case 'En retard': return Colors.red;
      case 'En attente': return Colors.orange;
      default: return Colors.grey;
    }
  }

  Widget _buildSupportBanner() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            child: const Icon(Icons.headset_mic_outlined, color: Color(0xFF2A8B5B)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Besoin d'aide ?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
                const SizedBox(height: 4),
                const Text("Notre équipe est là pour vous aider.", style: TextStyle(fontSize: 11, color: Color(0xFF4B5563))),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF16A34A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text('Contacter le support', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.chevron_right, color: Colors.white, size: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(PaymentProvider paymentProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
          const SizedBox(height: 16),
          Text(paymentProvider.errorMessage, style: const TextStyle(color: Colors.redAccent, fontSize: 16)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final prefs = await SharedPreferences.getInstance();
              final idStudent = prefs.getInt('idStudent') ?? 0;
              if (idStudent != 0) {
                paymentProvider.fetchPaymentData(idStudent);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A8B5B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }
}
