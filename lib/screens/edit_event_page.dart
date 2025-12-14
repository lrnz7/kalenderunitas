import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/event_model.dart';

class EditEventPage extends StatefulWidget {
  final EventModel event;
  final Function(EventModel) onSave;
  
  const EditEventPage({
    super.key,
    required this.event,
    required this.onSave,
  });

  @override
  State<EditEventPage> createState() => _EditEventPageState();
}

class _EditEventPageState extends State<EditEventPage> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  final _formKey = GlobalKey<FormState>();
  
  final List<String> _categories = [
    "Akademik", "Organisasi", "Kampus", "Event Umum"
  ];
  
  final List<String> _divisions = [
    "BPH", "PSDM", "Komwira", "PPPM", "Umum"
  ];
  
  String? _selectedCategory;
  String? _selectedDivision;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title);
    _descController = TextEditingController(text: widget.event.description ?? '');
    _selectedCategory = widget.event.category;
    _selectedDivision = widget.event.division;
    
    // Parse date from string
    try {
      final parts = widget.event.date.split('-');
      if (parts.length == 3) {
        _selectedDate = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
      }
    } catch (e) {
      print('Error parsing date: $e');
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
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

  void _saveChanges() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Pilih tanggal terlebih dahulu")),
      );
      return;
    }
    
    final dateStr = "${_selectedDate!.year.toString().padLeft(4, '0')}-"
        "${_selectedDate!.month.toString().padLeft(2, '0')}-"
        "${_selectedDate!.day.toString().padLeft(2, '0')}";
    
    final updatedEvent = widget.event.copyWith(
      title: _titleController.text.trim(),
      date: dateStr,
      category: _selectedCategory,
      division: _selectedDivision,
      description: _descController.text.trim().isNotEmpty 
          ? _descController.text.trim() 
          : null,
    );
    
    widget.onSave(updatedEvent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Event"),
        centerTitle: true,
        backgroundColor: const Color(0xFF0066CC),
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Colors.white),
            onPressed: _saveChanges,
            tooltip: 'Simpan Perubahan',
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
                "Edit Event",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Edit detail event yang ada di kalender",
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
                  onPressed: _saveChanges,
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
                        "SIMPAN PERUBAHAN",
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