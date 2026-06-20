// lib/widgets/reservation_sheet.dart
//
// Bottom sheet shown when a student taps an available, unreserved slot.
// Lets them pick a duration (1-4 hours), shows the price breakdown,
// and starts the Paymob checkout flow.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import '../providers/parking_provider.dart';
import '../services/paymob_service.dart';
import '../screens/student/payment_webview_screen.dart';
import '../utils/app_constants.dart';
import '../utils/app_theme.dart';

/// Shows the reservation bottom sheet for [slot]. Returns nothing —
/// any success/error feedback is shown via SnackBars.
Future<void> showReservationSheet(BuildContext context, ParkingSlotModel slot) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ReservationSheet(slot: slot),
  );
}

class ReservationSheet extends StatefulWidget {
  final ParkingSlotModel slot;
  const ReservationSheet({super.key, required this.slot});

  @override
  State<ReservationSheet> createState() => _ReservationSheetState();
}

class _ReservationSheetState extends State<ReservationSheet> {
  int _hours = AppConstants.reservationDurations.first;
  bool _processing = false;

  double get _total => AppConstants.reservedRatePerHour * _hours;
  double get _baseCost => AppConstants.baseRatePerHour * _hours;
  double get _fee => AppConstants.reservationFeePerHour * _hours;

  Future<void> _payAndReserve() async {
    final auth = context.read<AuthProvider>();
    final parking = context.read<ParkingProvider>();
    final user = auth.currentUser;
    if (user == null) return;

    setState(() => _processing = true);

    try {
      final checkout = await PaymobService.createCheckout(
        amountEgp: _total,
        merchantOrderId: 'SP-${widget.slot.label}-${DateTime.now().millisecondsSinceEpoch}',
        billingData: {
          'first_name': user.name.split(' ').first,
          'last_name': user.name.split(' ').length > 1 ? user.name.split(' ').last : 'Student',
          'email': user.email,
        },
      );

      if (!mounted) return;
      final success = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(checkoutUrl: checkout.iframeUrl),
        ),
      );

      if (!mounted) return;

      if (success == true) {
        await parking.confirmReservation(
          slot: widget.slot,
          userId: user.id,
          durationHours: _hours,
          amount: _total,
          paymobOrderId: checkout.orderId,
        );
        if (!mounted) return;
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Slot ${widget.slot.label} reserved for $_hours hour${_hours > 1 ? 's' : ''}.',
            ),
            backgroundColor: AppColors.success,
          ),
        );
      } else if (success == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment was not completed. Slot was not reserved.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      // success == null -> user closed the WebView manually, do nothing
    } on PaymobException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: AppColors.error),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Something went wrong starting the payment. Please try again.'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bookmark_add_rounded, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reserve Slot ${widget.slot.label}',
                        style: Theme.of(context).textTheme.headlineSmall),
                    const Text('Pay in advance to hold this spot',
                        style: TextStyle(color: Color(0xFF78909C), fontSize: 12)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Duration', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              children: AppConstants.reservationDurations.map((h) {
                final selected = h == _hours;
                return ChoiceChip(
                  label: Text('$h hr${h > 1 ? 's' : ''}'),
                  selected: selected,
                  onSelected: _processing ? null : (_) => setState(() => _hours = h),
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: selected ? Colors.white : AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppColors.primaryContainer.withOpacity(0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide.none,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _priceRow('Parking (${AppConstants.baseRatePerHour.toStringAsFixed(0)} EGP/hr × $_hours)',
                      _baseCost),
                  const SizedBox(height: 6),
                  _priceRow('Reservation fee (${AppConstants.reservationFeePerHour.toStringAsFixed(0)} EGP/hr × $_hours)',
                      _fee),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1),
                  ),
                  _priceRow('Total', _total, bold: true),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _processing ? null : _payAndReserve,
              icon: _processing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.lock_rounded, size: 18),
              label: Text(_processing
                  ? 'Processing...'
                  : 'Pay ${_total.toStringAsFixed(0)} EGP & Reserve'),
            ),
            const SizedBox(height: 6),
            const Center(
              child: Text(
                'Secure payment powered by Paymob',
                style: TextStyle(fontSize: 11, color: Color(0xFF90A4AE)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _priceRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 15 : 13,
      color: bold ? AppColors.primary : const Color(0xFF546E7A),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text('${value.toStringAsFixed(0)} EGP', style: style),
      ],
    );
  }
}
