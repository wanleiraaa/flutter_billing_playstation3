// lib/detail_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'ps_unit.dart';

class DetailPage extends StatefulWidget {
  final PSUnit unit;
  final VoidCallback onUpdate;

  const DetailPage({super.key, required this.unit, required this.onUpdate});

  @override
  State<DetailPage> createState() => _DetailPageState();
}

class _DetailPageState extends State<DetailPage> {
  Timer? _timer;
  final TextEditingController hoursCtrl = TextEditingController();
  final TextEditingController minutesCtrl = TextEditingController();
  String? selectedJaminan;
  bool hasShownReminder = false;

  @override
  void initState() {
    super.initState();
    _startTicker();
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final u = widget.unit;
    if (u.isUsed && u.endTime != null) {
      final now = DateTime.now();
      final diffSec = u.endTime!.difference(now).inSeconds;
      setState(() {
        u.remainingSeconds = diffSec > 0 ? diffSec : 0;
        if (diffSec <= 0) {
          u.isUsed = false;
        }
      });

      // Pengingat 1 menit sekali
      if (u.remainingSeconds == 60 && !hasShownReminder) {
        hasShownReminder = true;
        Future.microtask(() {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text("Pengingat"),
              content: Text("${u.name} tersisa 1 menit lagi."),
              actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
            ),
          );
        });
      }

      widget.onUpdate();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    hoursCtrl.dispose();
    minutesCtrl.dispose();
    super.dispose();
  }

  // Calculate price using PSUnit.getPrice() but needs chosenMinutes set.
  int computePriceFor(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final rem = totalMinutes % 60;
    return (hours * 5000) + (rem * 100);
  }

  void startPerJam() {
    final h = int.tryParse(hoursCtrl.text) ?? 0;
    final m = int.tryParse(minutesCtrl.text) ?? 0;
    final totalMinutes = (h * 60) + m;
    if (totalMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan durasi valid')));
      return;
    }
    final price = computePriceFor(totalMinutes);

    setState(() {
      widget.unit.isUsed = true;
      widget.unit.isPaid = false;
      widget.unit.rentalType = "perjam";
      widget.unit.jaminan = null; // no jaminan for perjam
      widget.unit.chosenMinutes = totalMinutes;
      widget.unit.startTime = DateTime.now();
      widget.unit.endTime = widget.unit.startTime!.add(Duration(minutes: totalMinutes));
      widget.unit.remainingSeconds = totalMinutes * 60;
      hasShownReminder = false;
    });

    widget.onUpdate();

    // show price info
    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Konfirmasi Harga"),
      content: Text("Total: Rp $price"),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
    ));

    hoursCtrl.clear();
    minutesCtrl.clear();
  }

  void startHarian() {
    if (selectedJaminan == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pilih jaminan untuk sewa harian')));
      return;
    }

    setState(() {
      widget.unit.isUsed = true;
      widget.unit.isPaid = false;
      widget.unit.rentalType = "harian";
      widget.unit.jaminan = selectedJaminan;
      widget.unit.chosenMinutes = 12 * 60;
      widget.unit.startTime = DateTime.now();
      widget.unit.endTime = widget.unit.startTime!.add(const Duration(hours: 12));
      widget.unit.remainingSeconds = 12 * 3600;
      hasShownReminder = false;
    });

    widget.onUpdate();

    showDialog(context: context, builder: (_) => AlertDialog(
      title: const Text("Konfirmasi Harga"),
      content: const Text("Total: Rp 70000"),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("OK"))],
    ));
  }

  String formatDateTime(DateTime? dt) {
    if (dt == null) return "-";
    return "${dt.year}-${dt.month.toString().padLeft(2,'0')}-${dt.day.toString().padLeft(2,'0')} "
           "${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}:${dt.second.toString().padLeft(2,'0')}";
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.unit;
    final hours = u.remainingSeconds ~/ 3600;
    final minutes = (u.remainingSeconds % 3600) ~/ 60;
    final seconds = u.remainingSeconds % 60;

    // realtime price preview (if not running): compute from inputs
    int previewPrice = 0;
    {
      final h = int.tryParse(hoursCtrl.text) ?? 0;
      final m = int.tryParse(minutesCtrl.text) ?? 0;
      final tm = h * 60 + m;
      if (tm > 0) previewPrice = computePriceFor(tm);
    }

    return Scaffold(
      appBar: AppBar(title: Text(u.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Status: ${u.isUsed ? 'Dipakai' : 'Tersedia'}", style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 10),
          if (u.startTime != null) Text("Mulai: ${formatDateTime(u.startTime)}"),
          if (u.endTime != null) Text("Selesai: ${formatDateTime(u.endTime)}"),
          const SizedBox(height: 12),

          if (u.isUsed) ...[
            Text("Tipe: ${u.rentalType}"),
            const SizedBox(height: 6),
            Text("Sisa Waktu: ${hours.toString().padLeft(2,'0')}:${minutes.toString().padLeft(2,'0')}:${seconds.toString().padLeft(2,'0')}",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Total Harga: Rp ${u.rentalType == 'harian' ? 70000 : u.getPrice()}"),
            const SizedBox(height: 8),
            Row(children: [
              const Text("Sudah bayar: "),
              Switch(value: u.isPaid, onChanged: (v) { setState(() => u.isPaid = v); widget.onUpdate(); }),
            ]),
            const SizedBox(height: 8),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red), onPressed: () {
              setState(() {
                u.isUsed = false;
                u.isPaid = false;
                u.rentalType = "";
                u.jaminan = null;
                u.startTime = null;
                u.endTime = null;
                u.remainingSeconds = 0;
                u.chosenMinutes = 0;
              });
              widget.onUpdate();
            }, child: const Text("Stop Sewa")),
          ] else ...[
            const SizedBox(height: 8),
            const Text("Rental Per Jam / Menit", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(child: TextField(controller: hoursCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Jam"))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: minutesCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Menit"))),
            ]),
            const SizedBox(height: 8),
            Text("Preview Harga: ${previewPrice > 0 ? "Rp $previewPrice" : "-"}"),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: startPerJam, child: const Text("Mulai Rental Per Jam / Menit")),

            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            const Text("Rental Harian (12 jam) — membutuhkan jaminan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: selectedJaminan,
              hint: const Text("Pilih Jaminan"),
              items: const [
                DropdownMenuItem(value: "KTP", child: Text("KTP")),
                DropdownMenuItem(value: "SIM", child: Text("SIM")),
                DropdownMenuItem(value: "Kartu Pelajar", child: Text("Kartu Pelajar")),
              ],
              onChanged: (v) => setState(() => selectedJaminan = v),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: startHarian, child: const Text("Mulai Rental Harian (Rp 70.000)")),
          ],
        ]),
      ),
    );
  }
}
