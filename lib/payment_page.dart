// lib/payment_page.dart
import 'package:flutter/material.dart';
import 'ps_unit.dart';

class PaymentPage extends StatefulWidget {
  final List<PSUnit> units;
  final VoidCallback onUpdate;

  const PaymentPage({super.key, required this.units, required this.onUpdate});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  List<PSUnit> get dueUnits => widget.units.where((u) => u.isUsed && !u.isPaid).toList();

  void _payNow(PSUnit unit) {
    final total = unit.rentalType == 'harian' ? 70000 : unit.getPrice();
    final ctrl = TextEditingController();

    showDialog(context: context, builder: (_) {
      return AlertDialog(
        title: Text("Bayar - ${unit.name}"),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text("Total: Rp $total"),
          const SizedBox(height: 8),
          TextField(controller: ctrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jumlah Diterima")),
        ]),
        actions: [
          TextButton(onPressed: () { Navigator.pop(context); }, child: const Text("Batal")),
          TextButton(onPressed: () {
            final paid = int.tryParse(ctrl.text) ?? 0;
            if (paid < total) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Uang tidak cukup')));
              return;
            }
            final change = paid - total;
            // mark paid
            setState(() {
              unit.isPaid = true;
            });
            widget.onUpdate();
            Navigator.pop(context);
            showDialog(context: context, builder: (_) => AlertDialog(
              title: const Text("Selesai"),
              content: Text("Pembayaran diterima. Kembalian: Rp $change"),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            ));
          }, child: const Text("Bayar")),
        ],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final dues = dueUnits;
    return Scaffold(
      appBar: AppBar(title: const Text("Payment Dashboard")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          if (dues.isEmpty) const Text("Tidak ada pembayaran tertunda", style: TextStyle(fontSize: 18)),
          if (dues.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: dues.length,
                itemBuilder: (context, idx) {
                  final u = dues[idx];
                  final price = u.rentalType == 'harian' ? 70000 : u.getPrice();
                  final remH = u.remainingSeconds ~/ 3600;
                  final remM = (u.remainingSeconds % 3600) ~/ 60;
                  final remS = u.remainingSeconds % 60;
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      title: Text(u.name),
                      subtitle: Text("${u.rentalType} • Total: Rp $price\nSisa: ${remH}j ${remM}m ${remS}s"),
                      trailing: ElevatedButton(onPressed: () => _payNow(u), child: const Text("Bayar Sekarang")),
                    ),
                  );
                },
              ),
            ),
        ]),
      ),
    );
  }
}
