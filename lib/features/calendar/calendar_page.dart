import 'package:flutter/material.dart';

class CalendarPage extends StatelessWidget {
  const CalendarPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kalender Unitas Sistem Informasi periode 2025-2026'),
      ),
      body: Column(
        children: [
          // Header info bulan (placeholder)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'January 2026',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),

          // Box kalender (placeholder)
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey),
              ),
              child: const Center(
                child: Text('Kalender Grid (belum dibuat)'),
              ),
            ),
          ),

          // Tombol untuk Admin/Kadiv: tambah event
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Tambah Event'),
            ),
          ),
        ],
      ),
    );
  }
}
