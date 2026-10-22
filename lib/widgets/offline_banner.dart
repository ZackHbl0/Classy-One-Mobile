import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/network_provider.dart';

/// Floating non-intrusive animated offline/reconnected banner.
class OfflineBanner extends StatelessWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<NetworkProvider>(
      builder: (context, net, _) {
        final isOffline = !net.isOnline;
        final showReconnected = net.showReconnectedBanner;

        return Stack(
          children: [
            child,
            if (isOffline || showReconnected)
              Positioned(
                top: MediaQuery.of(context).padding.top + 8,
                left: 16,
                right: 16,
                child: Material(
                  color: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isOffline
                          ? const Color(0xFF1E1708).withOpacity(0.95)
                          : const Color(0xFF0D2517).withOpacity(0.95),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isOffline
                            ? const Color(0xFFF59E0B).withOpacity(0.6)
                            : const Color(0xFF10B981).withOpacity(0.6),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (isOffline ? const Color(0xFFF59E0B) : const Color(0xFF10B981)).withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isOffline ? Icons.wifi_off_rounded : Icons.wifi_rounded,
                            size: 18,
                            color: isOffline ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isOffline ? 'Mode Hors-ligne' : 'Connexion rétablie',
                                style: TextStyle(
                                  color: isOffline ? const Color(0xFFFCD34D) : const Color(0xFF6EE7B7),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                isOffline
                                    ? 'Vous consultez les données sauvegardées en cache'
                                    : 'Synchronisation des données avec le serveur...',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isOffline)
                          GestureDetector(
                            onTap: () => net.manualRefresh(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Réessayer',
                                style: TextStyle(
                                  color: Color(0xFFFBBF24),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}