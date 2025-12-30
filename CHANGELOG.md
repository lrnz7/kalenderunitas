# Changelog
Semua perubahan penting pada proyek Kalender Unitas SI akan dicatat di file ini.  
Format versi mengikuti Semantic Versioning (MAJOR.MINOR.PATCH).

---

## [1.2.1] – 2025-12-30

### ✨ Penambahan Fitur
- Navigasi langsung ke bulan dan tahun tertentu melalui dropdown di AppBar.
- Penambahan divisi baru **Unitas SI**:
  - Disimpan sebagai `Unitas SI`
  - Ditampilkan ringkas sebagai **“Unitas”** pada kalender dan daftar event.
- Filter event berdasarkan:
  - **Kategori**: Akademik, Kampus, Umum, Organisasi
  - **Divisi**: BPH, PSDM, Komwira, PPPM, Unitas SI, dan lainnya
  - Filter dapat digunakan secara bersamaan (combined filtering).
- Dukungan **multi-day event**:
  - Event dapat memiliki tanggal mulai dan tanggal selesai.
  - Kalender menampilkan penanda visual berkelanjutan untuk satu rangkaian event.
  - Mendukung beberapa event multi-day yang saling overlap tanpa konflik data atau tampilan.

### 🎨 Peningkatan UI & UX
- Animasi transisi bulan yang lebih halus dan arah-aware.
- Event yang sudah lewat tanggal **otomatis disembunyikan** dari daftar event.
- Posisi scroll pada daftar event **tetap terjaga** setelah edit event.
- Tampilan filter lebih jelas dengan chip aktif dan tombol aksi yang kontras.

### 🛠️ Perbaikan & Stabilitas
- Perbaikan routing admin (`/admin`) agar tombol tambah event berfungsi dengan benar.
- Perapihan kode dan perbaikan minor lint (tanpa error pada analyzer).
- Logika filter dan UI event list tidak memengaruhi data maupun tampilan kalender.

---

## Catatan
- Update ini berfokus pada peningkatan pengalaman pengguna (UX), konsistensi visual,
  dan stabilitas sistem tanpa mengubah data event yang sudah ada.
