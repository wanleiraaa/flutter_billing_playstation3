// lib/main.dart
import 'package:flutter/material.dart';
import 'ps_unit.dart';
import 'detail_page.dart';
import 'payment_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Rental PS App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const PSUnitPage(),
    );
  }
}

class PSUnitPage extends StatefulWidget {
  const PSUnitPage({super.key});
  @override
  State<PSUnitPage> createState() => _PSUnitPageState();
}

class _PSUnitPageState extends State<PSUnitPage> {
  final List<PSUnit> units = List.generate(7, (i) => PSUnit(id: i + 1, name: "PS3 Unit ${i + 1}"));

  void refresh() => setState(() {});

  void openPaymentDashboard() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PaymentPage(units: units, onUpdate: refresh)),
    );
    refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rental PlayStation - 7 Unit'),
        actions: [
          IconButton(
            onPressed: openPaymentDashboard,
            icon: const Icon(Icons.payment_outlined),
            tooltip: "Menu Pembayaran",
          ),
        ],
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 1.05,
        ),
        itemCount: units.length,
        itemBuilder: (context, index) {
          final u = units[index];
          return GestureDetector(
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => DetailPage(unit: u, onUpdate: refresh)));
              refresh();
            },
            child: Container(
              decoration: BoxDecoration(
                color: u.isUsed ? Colors.red.shade300 : Colors.green.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(u.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(u.isUsed ? "Sedang digunakan" : "Tersedia"),
                  const SizedBox(height: 8),
                  if (u.isUsed)
                    Text(
                      "${u.remainingSeconds ~/ 3600}j ${(u.remainingSeconds % 3600) ~/ 60}m ${u.remainingSeconds % 60}s",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                ]),
              ),
            ),
          );
        },
      ),
    );
  }
}
