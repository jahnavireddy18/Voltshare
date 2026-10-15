import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vnest_app/core/theme/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<Map<String, dynamic>> _methods = [
    {'type': 'Visa', 'number': '•••• 4242', 'icon': Icons.credit_card, 'isDefault': true},
    {'type': 'Mastercard', 'number': '•••• 8888', 'icon': Icons.credit_card, 'isDefault': false},
    {'type': 'Apple Pay', 'number': 'apple.com/pay', 'icon': Icons.apple, 'isDefault': false},
  ];

  void _showAddPaymentDialog() {
    final cs = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: cs.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 24, right: 24, top: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Add New Card', style: GoogleFonts.sora(
                fontSize: 24, fontWeight: FontWeight.bold, color: cs.onSurface,
              )),
              const SizedBox(height: 24),
              TextField(
                keyboardType: TextInputType.number,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: 'Card Number',
                  labelStyle: TextStyle(color: cs.onSurfaceVariant),
                  enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.outlineVariant)),
                  focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: cs.primary)),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _methods.add({
                        'type': 'New Card', 
                        'number': '•••• 1234', 
                        'icon': Icons.credit_card, 
                        'isDefault': false
                      });
                    });
                    context.pop();
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Add Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: cs.onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text('Payment Methods', style: GoogleFonts.sora(
          fontSize: 20, fontWeight: FontWeight.bold, color: cs.onSurface,
        )),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Your Cards & Wallets', style: GoogleFonts.manrope(
                fontSize: 18, fontWeight: FontWeight.bold, color: cs.onSurface,
              )),
              const SizedBox(height: 16),
              ..._methods.asMap().entries.map((e) {
                final method = e.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: method['isDefault'] == true ? cs.primary.withValues(alpha: 0.5) : cs.outlineVariant),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(method['icon'] as IconData, color: cs.onSurface),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(method['type'] as String, style: GoogleFonts.manrope(
                              fontSize: 16, fontWeight: FontWeight.bold, color: cs.onSurface,
                            )),
                            const SizedBox(height: 4),
                            Text(method['number'] as String, style: GoogleFonts.plusJakartaSans(
                              fontSize: 14, color: cs.onSurfaceVariant,
                            )),
                          ],
                        ),
                      ),
                      if (method['isDefault'] == true)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(color: cs.primary.withValues(alpha: 0.3)),
                          ),
                          child: Text('Default', style: GoogleFonts.plusJakartaSans(
                            fontSize: 12, fontWeight: FontWeight.bold, color: cs.primary,
                          )),
                        ),
                    ],
                  ),
                ).animate(key: ValueKey(e.key)).fadeIn(delay: (200 + e.key * 100).ms).slideX(begin: 0.1);
              }),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddPaymentDialog,
                  icon: Icon(Icons.add, color: cs.onPrimary),
                  label: Text('Add New Payment Method', style: GoogleFonts.manrope(
                    fontSize: 16, fontWeight: FontWeight.bold, color: cs.onPrimary,
                  )),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2),
            ],
          ),
        ),
      ),
    );
  }
}
