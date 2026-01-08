# Changelog
Semua perubahan penting pada proyek Kalender Unitas SI akan dicatat di file ini.  
Format versi mengikuti Semantic Versioning (MAJOR.MINOR.PATCH).

---

## [1.2.1] – 2025-12-30

### Penambahan Fitur
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

### Peningkatan UI & UX
- Animasi transisi bulan yang lebih halus dan arah-aware.
- Event yang sudah lewat tanggal **otomatis disembunyikan** dari daftar event.
- Posisi scroll pada daftar event **tetap terjaga** setelah edit event.
- Tampilan filter lebih jelas dengan chip aktif dan tombol aksi yang kontras.

### Perbaikan & Stabilitas
- Perbaikan routing admin (`/admin`) agar tombol tambah event berfungsi dengan benar.
- Perapihan kode dan perbaikan minor lint (tanpa error pada analyzer).
- Logika filter dan UI event list tidak memengaruhi data maupun tampilan kalender.

---

## Catatan
- Update ini berfokus pada peningkatan pengalaman pengguna (UX), konsistensi visual,
  dan stabilitas sistem tanpa mengubah data event yang sudah ada.


## [1.3.0] - 2026-01-04
### Added
- Guardrails dan dokumentasi navigasi bulan vertikal
- Widget test stres untuk mencegah loncatan multi-bulan
- Debug hook dan counter khusus testing deterministik

### Changed
- Tidak ada perubahan perilaku runtime


## [1.3.1] – 2026-01-06

### Perbaikan & Stabilisasi
- Perbaikan logika navigasi bulan pada kondisi ekstrem (scroll cepat dan input beruntun).
- Penyesuaian internal state agar tidak terjadi loncatan bulan ganda pada interaksi cepat.
- Sinkronisasi ulang antara state tampilan kalender dan kontrol navigasi.

### Testing & Reliability
- Penambahan validasi internal untuk memastikan navigasi bulan bersifat deterministik.
- Penyempurnaan widget test agar lebih selaras dengan perilaku aktual aplikasi.

### Perapihan Kode
- Refactor minor pada struktur navigasi tanpa mengubah perilaku runtime.
- Pembersihan sisa hook debug yang tidak relevan untuk produksi.

---

## [1.3.2] – 2026-01-08

### Peningkatan UI & UX
- Stabilisasi dan finalisasi **TopBar** sebagai baseline resmi.
- Struktur TopBar kini konsisten di semua ukuran layar:
  - Informasi peran pengguna berada di sisi kiri.
  - Judul kalender **Kalender Unitas SI** selalu berada di tengah secara visual absolut.
  - Tombol logout terkunci di sisi kanan dengan jarak presisi.
- Perilaku layout TopBar dijamin tidak terpengaruh oleh perubahan lebar layar.

### Perbaikan & Stabilitas
- Revert dan penguncian TopBar ke state terverifikasi untuk mencegah regresi layout.
- Penandaan baseline TopBar untuk referensi pengembangan lanjutan.
- Validasi build dan runtime pada Chrome tanpa error kompilasi.

### Testing
- Penyesuaian ekspektasi test agar selaras dengan baseline TopBar yang dikunci.
- Fokus test diarahkan pada stabilitas layout, bukan eksperimen UI sementara.

---

## [1.3.3] – 2026-01-09

### Peningkatan UI & UX
- Refactor **Navbar** menjadi struktur tiga zona yang konsisten dengan TopBar:
  - Zona kiri: navigasi ke tanggal hari ini dan toggle libur nasional.
  - Zona tengah: navigasi bulan (sebelumnya / dropdown bulan / sesudah) dengan posisi absolut di tengah.
  - Zona kanan: dropdown tahun dan indikator koneksi server.
- Zona tengah Navbar kini benar-benar terpusat secara visual, tidak terdorong oleh elemen kiri maupun kanan.
- Pada layar sempit, kontrol navigasi bulan mendukung **scroll horizontal** untuk mencegah overflow.

### Perbaikan & Stabilitas
- Pemisahan logika dan struktur Navbar dari TopBar tanpa mengubah implementasi TopBar.
- Tidak ada perubahan key widget navigasi sehingga kompatibel dengan test yang sudah ada.
- Seluruh perilaku interaksi Navbar tetap sama, hanya struktur dan layout yang disempurnakan.

### Testing & Verifikasi
- Seluruh test terkait Navbar lulus tanpa regresi.
- Pengujian visual manual pada berbagai ukuran layar memastikan konsistensi dan presisi layout.
- Build dan runtime Chrome berjalan stabil tanpa error baru.

---

## Catatan
- Versi 1.3.x berfokus pada stabilisasi internal, konsistensi layout,
  dan peningkatan kualitas struktur UI tanpa menambah fitur baru bagi pengguna akhir.