import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';
import '../services/data_loader.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  final List<String> _categories = [
    "Akademik",
    "Organisasi",
    "Kampus",
    "Event Umum",
  ];

  final List<String> _divisions = [
    "BPH",
    "PSDM",
    "Komwira",
    "PPPM",
    "Umum"
  ];

  String? _selectedCategory;
  String? _selectedDivision;
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2050),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0066CC),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveEvent() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final desc = _descController.text.trim();
    final date = _selectedDate;

    if (date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tanggal terlebih dahulu")),
      );
      return;
    }

    final dateStr = "${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}";

    final newEvent = EventModel(
      title: title,
      date: dateStr,
      category: _selectedCategory,
      division: _selectedDivision,
      description: desc.isNotEmpty ? desc : null,
    );

    // TAMPILKAN LOADING
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Menyimpan event...'),
          ],
        ),
      ),
    );

    try {
      // SIMPAN EVENT
      await DataLoader.addEvent(newEvent, createdBy: "Admin");
      
      // TUTUP LOADING
      Navigator.pop(context);

      // TAMPILKAN SUKSES
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 64,
          ),
          content: const Text(
            "Event berhasil ditambahkan!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 18),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _resetForm();
              },
              child: const Text('TAMBAH LAGI'),
            ),
            ElevatedButton(
              onPressed: () {
                // Kembali ke halaman utama
                Navigator.popUntil(context, (route) => route.isFirst);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
              ),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      // TUTUP LOADING JIKA ERROR
      Navigator.pop(context);
      
      // TAMPILKAN ERROR
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _titleController.clear();
    _descController.clear();
    setState(() {
      _selectedCategory = null;
      _selectedDivision = null;
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Tambah Event Baru"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Informasi Event",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Isi detail event yang akan ditambahkan ke kalender",
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 30),

              // Judul Event
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Judul Event *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.title),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Judul event wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Deskripsi
              TextFormField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "Deskripsi (opsional)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.white,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              // Kategori
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Kategori *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.category),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedCategory,
                items: _categories
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Pilih kategori event';
                  }
                  return null;
                },
                onChanged: (v) {
                  setState(() {
                    _selectedCategory = v;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Divisi
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: "Divisi *",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  prefixIcon: Icon(Icons.groups),
                  filled: true,
                  fillColor: Colors.white,
                ),
                value: _selectedDivision,
                items: _divisions
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e),
                        ))
                    .toList(),
                validator: (value) {
                  if (value == null) {
                    return 'Pilih divisi';
                  }
                  return null;
                },
                onChanged: (v) {
                  setState(() {
                    _selectedDivision = v;
                  });
                },
              ),
              const SizedBox(height: 20),

              // Tanggal
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Tanggal Event *",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _selectedDate == null
                                  ? "Belum memilih tanggal"
                                  : DateFormat('EEEE, d MMMM yyyy').format(_selectedDate!),
                              style: TextStyle(
                                fontSize: 16,
                                color: _selectedDate == null
                                    ? Colors.grey
                                    : Colors.black87,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _pickDate,
                            icon: const Icon(Icons.calendar_month),
                            label: Text(
                              _selectedDate == null
                                  ? "PILIH TANGGAL"
                                  : "UBAH",
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066CC),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDate == null)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            "Tanggal wajib dipilih",
                            style: TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Preview
              if (_selectedDate != null && _titleController.text.isNotEmpty)
                Card(
                  elevation: 1,
                  color: Colors.grey[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Preview:",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _titleController.text,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0066CC),
                          ),
                        ),
                        if (_selectedCategory != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Kategori: $_selectedCategory",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        if (_selectedDivision != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              "Divisi: $_selectedDivision",
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            "Tanggal: ${DateFormat('d MMMM yyyy').format(_selectedDate!)}",
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              // Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 12),
                      Text(
                        "SIMPAN EVENT",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}