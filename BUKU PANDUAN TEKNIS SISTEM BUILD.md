# BUKU PANDUAN TEKNIS: SISTEM BUILD KOBI GDExtension

---

SAMBUTAN DARI PENCIPTA

## "Dari Nol Menjadi Satu: Perjalanan Sistem Build KOBI"

---

### Awal Mula: Kode-Kode yang Terpisah
Sistem build ini tidak lahir dalam bentuknya yang sekarang. Awalnya hanyalah **kumpulan file Python yang terpisah-pisah** - potongan-potongan kode yang berserakan, masing-masing berdiri sendiri tanpa jembatan yang menghubungkan. Ada logika build di sini, ada antarmuka di sana, dan di tempat lain ada skrip setup yang butuh dijalankan manual. Setiap kali ingin menggunakannya, aku harus mengingat urutan yang tepat, jalankan file ini dulu, lalu itu, lalu jangan lupa yang satunya lagi.

Mirip rasanya kaya punya kendaraan tanpa kunci kontak, semua komponen - kompoenanya ada, tetapi tidak ada cara untuk menyalakan mesinnya.

---

#### Claude: Sang Penggabung dan Perancang Visual
Lalu datanglah **Claude (Anthropic)** - yang melihat potensi di balik kepingan-kepingan kode itu. Dengan ketelitian yang luar biasa, Claude:
1. **Menggabungkan semua file PY** menjadi satu kesatuan yang utuh di dalam `jalankan_bootstrapper.sh`
2. **Merancang antarmuka curses** yang Anda lihat sekarang – menu yang rapi, warna yang konsisten, navigasi yang intuitif.
3. **Menyatukan logika build** dengan antarmuka pengguna, sehingga semuanya berjalan dalam satu alur yang mulus.
4. **Menambahkan sentuhan visual** yang membuat terminal terasa seperti aplikasi sungguhan, bukan sekadar skrip baris perintah.

Tanpa Claude, sistem ini mungkin masih berupa kumpulan file yang membingungkan, bukan alat yang siap pakai seperti sekarang.

---

#### Pengujian di Linux (dan Sekilas ke Windows)
Sistem ini sebagian besar diuji dan dikembangkan di **lingkungan Linux** - di situlah ia lahir dan tumbuh. Setiap baris kode, setiap fungsi, dan setiap transisi visual telah melewati berbagai uji coba di terminal Linux.

Untuk **Windows**, dukungan sudah disiapkan di level kode (compiler `mingw-w64`, flag `-m64`/`-m32`, dan konfigurasi cross-compilation), tetapi pengujian langsung di Windows masih dalam tahap awal. Saya berharap di masa depan, sistem ini dapat berjalan mulus di kedua platform. Namun untuk saat ini, pengalaman terbaik tetap ada di Linux.

> [!NOTE] *Catatan*:
>  Dukungan Windows di kode sudah ada sejak awal – semua logika cross-compilation sudah siap. Yang kurang hanyalah pengujian ekstensif di lingkungan Windows itu sendiri._

---

#### DeepSeek: Penerjemah Teknis Menjadi Narasi
Jika Claude adalah arsitek sistem, maka **DeepSeek** adalah penulis yang menuangkan seluruh kompleksitas teknis ke dalam kata-kata yang terstruktur dan mudah dipahami. Dokumentasi yang Anda pegang ini - 20 bab, ratusan halaman, ribuan baris penjelasan – lahir dari kolaborasi dengan DeepSeek.

DeepSeek tidak hanya mencatat apa yang ada, tetapi:
- **Menjelaskan** alasan di balik setiap keputusan desain.
- **Menghubungkan** antar bagian kode yang saling bergantung.
- **Memberikan** panduan praktis bagi pengembang yang ingin memodifikasi sistem.
- **Menerjemahkan** kode Bash, Python, dan SCons menjadi narasi yang mengalir.

---

#### Tujuan Akhir: Satu File, Untuk Semua
Dari kepingan-kepingan kode yang terpisah, kini hadir **satu file shell script** yang:
- Dapat diklik dan dijalankan langsung dari file manager.
- Membuka terminal sendiri jika diperlukan.
- Menampilkan antarmuka yang indah dan responsif.
- Mengelola seluruh proses build dari awal hingga akhir.
- Mencatat setiap langkah untuk keperluan debugging.

Ini adalah hasil dari kolaborasi antara manusia dan AI - sebuah contoh bagaimana teknologi dapat saling melengkapi untuk menciptakan sesuatu yang lebih besar dari jumlah bagian-bagiannya.

---

#### Ucapan Terima Kasih

| Kontributor                          | Peran                                     |
| ------------------------------------ | ----------------------------------------- |
| **Yohanes Alan Jasper/ KOBI Studio** | Pencipta, Penggagas Ide, Pemilik proyek   |
| **Muhammad Sabil Hidayatullah**      | Pendukung, pemberi masukan, Bug           |
| **Ade Surya Ramadhan**               | Pendukung, Testing Windows                |
| **Revandra Maulana**                 | Pendukung, Testing File & Windows         |
| **Claude (Anthropic)**               | Menggabungkan Kode, Merancang UI, Testing |
| **DeepSeek**                         | Menulis Dokumentasi, Penyusun Narasi      |

---

### Versi dan Status

|Properti|Nilai|
|---|---|
|**Versi Sistem**|v2.4.0|
|**Tanggal Rilis**|26 Juli 2026|
|**Status**|Stabil di Linux, Windows dalam tahap uji|
|**Lisensi**|GPL-3.0-or-later|

---

## CARA MEMBACA DOKUMEN INI

Dokumen ini adalah **referensi teknis lengkap** untuk sistem build KOBI GDExtension. Ada beberapa cara untuk membacanya:

| Jika Baru...                                      | Mulai dari...                                                |
| ------------------------------------------------- | ------------------------------------------------------------ |
| **Baru pertama kali**                             | Bab 1 (Filosofi) > Bab 17 (Alur) > Bab 19 (Rekomendasi)      |
| **Pengembang yang ingin mengubah tampilan**       | Langsung ke Bab 10 (Render) dan Bab 11 (Main Loop)           |
| **Pengembang yang ingin mengubah logika build**   | Bab 13 - 15 (build_logic.py) dan Bab 16 (setup_godot_cpp.py) |
| **Pengguna yang hanya ingin mengerti cara kerja** | Bab 1 (Filosofi) + Bab 17 (Alur) sudah cukup                 |
| **Troubleshooting**                               | Cek sub-bab "Troubleshooting" di setiap bab                  |

**Selamat membaca dan semoga bermanfaat!**

_--- Yohanes Alan Jasper (Kokhav)_  
_KOBI Studio, 2026_

---

### [BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM%7CBAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM.md)

1. [Mengapa Dokumentasi Ini Dibutuhkan?](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#1.%20Pendahuluan%20Mengapa%20Dokumentasi%20Ini%20Dibutuhkan?%7CMengapa%20Dokumentasi%20Ini%20Dibutuhkan?.md)
2. [Latar Belakang: mengapa butuh Bootstrapper Satu File?](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#2.%20Latar%20Belakang%20Mengapa%20Butuh%20Bootstrapper%20Satu%20File?%7CLatar%20Belakang:%20mengapa%20butuh%20Bootstrapper%20Satu%20File?.md)
3. [Filosofi Desain: Self-Contained, Regeneratif, dan Terminal-First.](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#3.%20Filosofi%20Desain%20Self-Contained,%20Regeneratif,%20dan%20Terminal-First%7CFilosofi%20Desain:%20Self-Contained,%20Regeneratif,%20dan%20Terminal-First..md)
4. [Siapa Target Pengguna Sistem Ini?.](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#4.%20Siapa%20Target%20Pengguna%20Sistem%20Ini?%7CSiapa%20Target%20Pengguna%20Sistem%20Ini?..md)
5. [Prasyarat Sistem (Dependensi yang Harus Ada: Python3, SCons, Git, Compiler).](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#5.%20Prasyarat%20Sistem%20(Dependensi%20yang%20Harus%20Ada)%7CPrasyarat%20Sistem%20(Dependensi%20yang%20Harus%20Ada:%20Python3,%20SCons,%20Git,%20Compiler)..md)
6. [Ikhtisar Alur Eksekusi.](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM#6.%20Ikhtisar%20Alur%20Eksekusi%7CIkhtisar%20Alur%20Eksekusi..md)
7. [Tabel Rangkuman](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM.md#7.%20Tabel%20Rangkuman)
8. [Keterkaitan dengan Bab Lain](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM.md#8.%20Keterkaitan%20dengan%20Bab%20Lain)
9. [Kesimpulan](BAB%201%20-%20PENDAHULUAN%20DAN%20FILOSOFI%20SISTEM.md#9.%20Kesimpulan)
---

### [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)|BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)]]

1. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#1. Pendahuluan Fondasi dari Seluruh Sistem|Fondasi dari Seluruh Sistem.]]
2. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#2. ` !/bin/bash` - Penanda Interpreter|`#!/bin/bash` - Penanda Interpreter.]]
3. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#3. Komentar Pembuka dan Penjelasan Tujuan|Komentar Pembuka dan Penjelasan Tujuan.]]
4. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#4. Perintah `cd "$(dirname "$0")"` - Mengunci Direktori Kerja|Perintah `cd "$(dirname "$0")"` - Mengunci Direktori Kerja.]]
5. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#5. Variabel `SCRIPT_ABS="$(readlink -f "$0")"` - Mendapatkan Path Absolut|Variabel `SCRIPT_ABS="$(readlink -f "$0")"` - Mendapatkan Path Absolut.]]
6. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#6. Blok Komentar tentang Self-Heal & .desktop|Blok Komentar tentang Self-Heal & .desktop]]
7. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#7. Tabel Rangkuman|Tabel Rangkuman.]]
8. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#8. Keterkaitan dengan Bab Lain|Keterkaitan dengan Bab Lain.]]
9. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#9. Kesimpulan|Kesimpulan.]]

---

### [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION|BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION]]

1. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#1. Pendahuluan Menjadikan Script "Bisa Diklik"|Menjadikan Script "Bisa Diklik".]]
2. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#2. Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`|Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`.]]
3. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#3. Logika `if [ ! -f "$DESKTOP_FILE" ]` - Pengecekan Keberadaan|Logika `if [ ! -f "$DESKTOP_FILE" ]` - Pengecekan Keberadaan.]]
4. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#4. Isi Template `.desktop` - Heredoc dan Field-nya|Isi Template `.desktop`  (Heredoc dan Field-nya).]]
5. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#5. `chmod +x "$DESKTOP_FILE"` - Memberi Izin Eksekusi pada Launcher|`chmod +x "$DESKTOP_FILE"` - Memberi Izin Eksekusi.]]
6. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#6. `chmod +x "$SCRIPT_ABS"` - Self-Heal Permission pada Shell|`chmod +x "$SCRIPT_ABS"` - Self-Heal Permission pada Shell.]]
7. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#7. Alur Lengkap Pembuatan .desktop dan Self-Heal|Alur Lengkap Pembuatan .desktop dan Self-Heal.]]
8. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#8. Tabel Rangkuman|Tabel Rangkuman.]]
9. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#9. Keterkaitan dengan Bab Lain|Keterkaitan dengan Bab Lain.]]
10. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#10. Troubleshooting .desktop|Troubleshooting .desktop.]]
11. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#11. Kustomisasi .desktop|Kustominasi .desktop.]]
12. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#12. Kesimpulan|Kesimpulan.]]

---

### [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)|BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)]]

1. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#1. Pendahuluan Menjembatani Dunia GUI dan Terminal|Menjembatani Dunia GUI dan Terminal.]]
2. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#12. Keterkaitan dengan Bab Lain|Kondisi `[ ! -t 0 ]`- Deteksi Terminal Non-Interakti.]]
3. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch|Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut Untuk Relaunch.]]
4. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#4. Iterasi Kandidat Terminal - Daftar Emulator|Iterasi Kandidat Terminal - Daftar Emulator.]]
5. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#5. Pengecekan Keberadaan Terminal dengan `command -v`|Pengecekan Keberadaan Terminal dengan `command -v`.]]
6. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#6. Struktur `case` - Perbedaan Parameter Eksekusi Tiap Terminal|Struktur `case` - Perbedaan Parameter Eksekusi Tiap Terminal.]]
7. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#7. `exit 0` - Keluar dari Proses Lama setelah Relaunch Berhasil|Mekanisme `exit 0` setelah Berhasil Membuka Terminal Baru.]]
8. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#8. `done` dan `exit 1` - Fallback jika Tidak Ada Terminal|`done` dan `exit 1` - Fallback jika Tidak Ada Terminal.]]
9. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#9. `fi` - Penutup Blok Kondisi|`fi` - Penutup Blok Kondisi.]]
10. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#10. Alur Lengkap Self-Relaunch|Alur Lengkap Self-Relaunch.]]
11. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#11. Tabel Rangkuman|Tabel Rangkuman.]]
12. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#12. Keterkaitan dengan Bab Lain|Keterkaitan dengan Bab Lain.]]
13. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#13. Troubleshooting Self-Relaunch|Troubleshooting Self-Relaunch.]]
14. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#14. Perbandingan Self-Relaunch Bash vs Python|Perbandingan Self-Relaunch Bash vs Python.]]
15. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#15. Kesimpulan|Kesimpulan.]]

---

### [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL|BAB 5 – EMBEDDING FILE PYTHON: HEREDOC DAN AWAL `bootstrap_scons_gui.py`]]

1. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#1. Pendahuluan Dari Shell ke Python - Lahirnya Antarmuka|Dari Shell ke Python - Lahirnya Antarmuka.]]
2. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#2. Blok Komentar tentang Mode Proyek Baru|Blok Komentar tentang Mode Proyek Baru.]]
3. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String|Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String.]]
4. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#4. Shebang ` !/usr/bin/env python3` - Penanda Interpreter Python|Shebang Python `#!/usr/bin/env python3`.]]
5. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#5. Docstring Awal Sejarah Migrasi dari Tkinter ke Curses|Docstring Awal: Sejarah Migrasi dari Tkinter ke Curses.]]
6. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#6. Daftar Import Library - Fondasi Fungsionalitas Python|Daftar Import Library - Fondasi Fungsionalitas Python]]
7. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#7. Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE` - Pengantar|Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE` - Pengantar]]
8. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#8. Blok Self-Relaunch Python - Pengantar|Blok Self-Relaunch Python - Pengantar]]
9. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#9. Tabel Rangkuman|Tabel  Rangkuman]]
10. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#10. Keterkaitan dengan Bab Lain|Keterkaitan dengan Bab Lain]]
11. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#11. Kesimpulan|Kesimpulan]]

---

### [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#BAB 6 - `bootstrap_scons_gui.py` SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL|BAB 6 – `bootstrap_scons_gui.py`: SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL]]

1. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#1. Pendahuluan Lapisan Kedua Self-Relaunch dan Fondasi Build|Lapisan Kedua Self-Relaunch.]]
2. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#2. Blok `if not sys.stdin.isatty() ` - Deteksi Terminal Non-Interaktif di Python|Blok `if not sys.stdin.isatty():`.]]
3. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#3. Path File Absolut `os.path.abspath(__file__)`|Path File Absolut: `os.path.abspath(__file__)`.]]
4. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#4. Perintah Dalam Terminal `python3 "{path_file}"; echo; read -p "Press ENTER..."`|Perintah Dalam Terminal: `python3 "{path_file}"; echo; read -p "Press ENTER..."`.]]
5. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#5. Daftar Kandidat Terminal di Python|Daftar Kandidat Terminal di Python (dengan parameter spesifik).]]
6. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#6. Pengecekan Keberadaan Terminal dengan `shutil.which()`|Pengecekan Keberadaan Terminal dengan `shutil.which()`.]]
7.  [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#8. Konstanta `STUB_CONTENT` - Isi File `SConstruct`|Konstanta `STUB_CONTENT` - Isi File `SConstruct` (Stub untuk `exec`).]]
8. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#9. Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`|Konstanta `LOGIC_CONTENT`** - String Raksasa Isi `build_logic.py` (Pengantar).]]
9. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#9. Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`|Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`.]]
10. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#10. Perbandingan Self-Relaunch Bash vs Python|Perbandingan Self-Relaunch Bash vs Python.]]
11. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#11. Tabel Rangkuman|Rangkuman.]]
12. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#12. Keterkaitan dengan Bab Lain|Keterikatan dengan Bab Lain.]]
13. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#13. Kesimpulan|Kesimpulan.]]

---

### [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#BAB 7 – `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)|BAB 7 - FUNGSI UTILITY (VERSI, CACHE, SCAN)]]

1. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#1. Pendahuluan Mengapa Utility Functions Penting?|Mengapa Utility Functions Penting?]]
2. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#2. Fungsi `get_daftar_versi_cache_path()` - Path Cache Versi|Pengambil Versi Godot di Github]]
3. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#3. Fungsi `load_daftar_versi()` - Memuat Daftar Versi|Memuat Daftar Versi]]
4. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#4. Fungsi `get_daftar_api_version()` - Daftar API Version untuk Branch Master|Daftar API Version untuk Branch Master]]
5. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#5. Fungsi `validasi_format_versi(versi)` - Validasi Input Custom|Validasi Permintaan Input di Menu Custom]]
6. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding|**memindai semua folder `godot-cpp]]
7. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#7. Fungsi `cek_godot_terinstall()` - Deteksi Godot Editor di Sistem|Mendeteksi Godot editor yang terinstall di sistem]]
8. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#8. Fungsi `update_daftar_versi_online()` - Tarik Versi dari GitHub|Update Daftar Versi Godot-cpp]]
9. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#9. Fungsi `get_godot_cpp_status()` - Status Binding Aktif|Menentukan status kompilasi dari versi godot-cpp yang aktif]]
10. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#10. Fungsi `get_last_build_info()` - Informasi Build Terakhir|Membaca File Logs  Build Terakhir]]
11. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#11. Tabel Rangkuman Utility Functions|Tabel Rangkuman Utility Functions]]
12. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#12. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0]]
13. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#13. Kesimpulan|Kesimpulan]]

---

### [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#BAB 8 - `bootstrap_scons_gui.py` MANAJEMEN OPSI (`build_options.json`)|BAB 8 -  MANAJEMEN OPSI JSON]]

1. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#1. Pendahuluan Inti Konfigurasi Build|Inti Konfigurasi Build]]
2. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default|Memuat Opsi dengan Nilai Default]]
3. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#3. Fungsi `save_options(opts)` - Menyimpan Opsi ke JSON + Backup|Menyimpan Opsi ke JSON dan Backup]]
4. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#4. Opsi `bits` - Arsitektur 64/32-bit (Fitur Baru v2.4.0)|Arsitektur 64/32-bit ]]
5. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#5. Interaksi dengan Utility Functions|Interaksi dengan Utility Functions]]
6. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#6. Contoh Alur Penggunaan Opsi|Alur Penggunaan Opsi]]
7. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#7. Keamanan dan Robustness|Keamanan dan Robustness]]
8. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#8. Tabel Perbandingan Opsi Default vs Opsi yang Disimpan|Tabel Perbandingan]]
9. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#9. Keterkaitan dengan Fitur Lain v2.4.0|Keterkaitan dengan Fitur Lain v2.4.0]]
10. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#10. Kesimpulan|Kesimpulan]]

---

### [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#BAB 9 – `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)|BAB 9 - KONSTANTA DATA STATIS (CREDITS & MENU)]]

1. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#1. Pendahuluan Data Statis sebagai Tulang Punggung UI|Data Statis sebagai Tulang Punggung UI.]]
2. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim|Daftar Teks Kredit]]
3. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#3. Konstanta `MENU` - Struktur Hierarki Menu Utama|Daftar Item Menu (Header & Option) dengan ID]]
4. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih|Daftar ID yang Bisa Dipilih oleh Kursor.]]
5. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0|Placeholder untuk teks lisensi GPL-3.0 (Bisa Juga di isi Lisensi yang Lain).]]
6. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#6. Fitur-Fitur Baru di v2.4.0 yang Relevan dengan Bab Ini|Melihat dan mengekspor lisensi.]]
7. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#7. Tabel Rangkuman Konstanta Data Statis|Tabel Rangkuman Konstanta Data Statis.]]
8. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#8. Interaksi dengan Fungsi Lain|Interaksi dengan Fungsi Lain.]]
9. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#9. Kesimpulan|Kesimpulan.]]


---

### [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#BAB 10 – `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)|BAB 10 - FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)]]

1. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#1. Pendahuluan Antarmuka Pengguna di Dunia Terminal|Pendahuluan.]]
2. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|Menggambar UI Utama (Judul, Subtitle, Menu, Log, Last Build).]]
3. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#3. Fungsi `curses_input()`- Input Teks di Dalam Curses|Input Teks di Dalam Mode Curses (tanpa `endwin()`).]]
4. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#4. Fungsi `show_message_dialog_timed()` - Dialog dengan Hitung Mundur|Dialog dengan Hitung Mundur 10 Detik (Hanya ENTER yang berfungsi).]]
5. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#5. Fungsi `show_message_dialog()` - Dialog Pesan Biasa|Dialog Biasa (Tombol Apa Pun Lanjut).]]
6. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|Dialog untuk Teks Panjang.]]
7. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#7. Fungsi `run_subprocess_in_curses()` - Output Live Proses Eksternal|Jalankan Proses Eksternal dengan Output Live di Layar Curses.]]
8. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#8. Fungsi `kotak_tengah()` - Box di Tengah Layar|Gambar Box di Tengah Layar (Horizontal & Vertikal).]]
9. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#9. Fungsi `tanya_ya_tidak()` - Dialog Y/N|Dialog Hanya Menerima Y/N (Loop Sampai Valid).]]
10. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#10. Fungsi `minta_nama_folder_baru()` - Input Nama Folder dengan Validasi|Input Nama Folder dengan Validasi Karakter (`[a-zA-Z0-9_-]`).]]
11. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#11. Fungsi `tanya_dan_pindah_folder_proyek()` - Dialog Awal Pembuatan Proyek|Dialog Awal (Bikin Folder Baru? Pindah File Python?).]]
12. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#12. Fungsi `confirm_generate()` - Konfirmasi Sebelum Generate|Layar Konfirmasi Ringkasan Opsi Sebelum Generate.]]
13. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#13. Tabel Rangkuman Fungsi Layar Curses|Rangkuman Fungsi Layar Curses.]]
14. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#14. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
15. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#15. Kesimpulan|Kesimpulan.]]

---

### [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD|BAB 11 - INTI MAIN LOOP DAN NAVIGASI KEYBOARD]]

1. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#1. Pendahuluan Pusat Kendali Aplikasi|Pusat Kendali Aplikasi.]]
2. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#1.|Entry Point `curses.wrapper`.]]
3. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Stabilisasi Terminal (v2.4.0)|Stabilisasi Terminal.]]
4. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Dialog Awal|Pemanggilan `tanya_dan_pindah_folder_proyek(stdscr)` di Inisialisasi Awal.]]
5. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Inisialisasi State|Load Opsi dan Inisialisasi `cursor = 0`, `show_help = False`.]]
6. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#^ec41d2|Loop Utama `while True`.]]
7. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#3. Help Window - Dokumentasi Interaktif|Bantuan (Help Window).]]
8. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Inisialisasi Warna (v2.4.0)|Inisialisasi Warna di `main()`.]]
9. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Event Mouse (v2.4.0)|Event Mouse agar scroll wheel tidak mengganggu.]]
10. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `license` - View License (v2.4.0)|Tulis `LICENSE_TEXT` ke file `LICENSE`.]]
11. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#7. Penanganan Keluar - Q/q|Penanganan Keluar.]]
12. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#8. Tabel Rangkuman Navigasi Keyboard|Rangkuman Navigasi Keyboard.]]
13. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#9. Tabel Rangkuman Aksi Menu|Rangkuman Aksi MenuRangkuman Aksi Menu.]]
14. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#10. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
15. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#11. Kesimpulan|Kesimpulan.]]

---

### [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)|BAB 12 - FUNGSI GENERATE FILE (SConstruct & build_logic.py)]]

1. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#1. Pendahuluan Menghidupkan Sistem Build|Menghidupkan Sistem Build.]]
2. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|Menulis SConstruct dan build_logic.py.]]
3. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#3. Konstanta `STUB_CONTENT` - Isi File `SConstruct`|Isi File SConstruct.]]
4. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#4 .Konstanta `LOGIC_CONTENT` - Isi File `build_logic.py`|Isi File build_logic.py.]]
5. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#5. Alur Lengkap Dari Menu hingga Build|Alur Lengkap: Dari Menu hingga Build.]]
6. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#6. Mengapa Pengguna Tidak Boleh Mengedit `build_logic.py`?|Mengapa Pengguna Tidak Boleh Mengedit build_logic.py?]]
7. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#7. Tabel Perbandingan SConstruct vs build_logic.py|Tabel Perbandingan.]]
8. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#7. Tabel Perbandingan SConstruct vs build_logic.py|Keterkaitan dengan Fitur Baru v2.4.0]].
9. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#9. Kesimpulan|Kesimpulan.]]

---

### [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)|BAB 13 - ISI "build_logic.py" (PROLOG, KELAS, KONFIGURASI)]]

1. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#1. Pendahuluan Jantung Sistem Build| Jantung Sistem Build.]]
2. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#2. Import Library dan Variabel Global|Import Library dan Variabel Global.]]
3. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#3. Kelas `Terminal` - Wrapper untuk stdout + Logging|Kelas Terminal sebagai Pembungkus/ Wrapper.]]
4. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#4. Kelas `ColorMagic` - Pewarnaan Terminal Dinamis|Kelas ColorMagic untuk Pewarnaan Terminal.]]
5. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#5. Konfigurasi Awal - Path dan Konstanta Build|Konfigurasi Awal - path dan Konstanta Build.]]
6. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#6. Pembacaan `build_options.json` dan Penentuan Path godot-cpp|Pembacaan dan Penentuan Path Godot-cpp pada build_options.json.]]
7. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#|Dampak opsi Bits pada konfigurasi.]]
8. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#8. Tabel Rangkuman Konfigurasi Awal `build_logic.py`|Tabel Rangkuman Konfigurasi Awal.]]
9. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#9. Keterkaitan dengan Bab Sebelumnya|Keterkaitan dengan Bab Sebelumnya.]]
10. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#10 Kesimpulan|Kesimpulan.]]

---

### [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#BAB 14 - ISI `build_logic.py` (FUNGSI LOGGING DAN REPORT)|BAB 14 - ISI "build_logic.py" (LOGGING DAN REPORT)]]

1. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#1. Pendahuluan Merekam Jejak Build|Merekam jejak build.]]
2. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#2. Fungsi `_archive_old_json()` - Mengarsipkan Entri JSON Lama|Fungsi Utama Arsip Lama.]]
3. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#3. Fungsi `_archive_old_md()` - Merotasi `build_report.md`|Merotasi build_report.md.]]
4. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#4. Fungsi `write_logs()` - Fungsi Utama Logging|Fungsi Utama Logging.]]
5. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#5. Fungsi `report_build_failures()` - Menangkap Error Compile|Fungsi Utama Penangkap Error Kompilator.]]
6. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#6. Alur Logging Lengkap|Alur Logging.]]
7. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#7. Tabel Rangkuman Fungsi Logging|Tabel Rangkuman Fungsi Logging.]]
8. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#8. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
9. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#9. Contoh Output Log|Contoh Output Log.]]
10. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#10. Kesimpulan Bab 14|Kesimpulan.]]

---

### [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#BAB 15 - ISI "build_logic.py" (GENERATE GDEXTENSION DAN INTI BUILD)|BAB 15 - ISI "build_logic.py" ( GENERATE GDExtension DAN INTI BUILD)]]

1. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#1. Pendahuluan Mesin Build yang Sebenarnya|Mesin Build yang Sebenarnya.]]
2. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#2. Fungsi `generate_gdextension()` - Membuat File `.gdextension`|Fungsi Membuat File ".gdextension"]]
3. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|Fungsi Inti Build Engine SCons.]]
4. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|Pemanggilan Inti Build Engine.]]
5. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#5. Tabel Rangkuman Konfigurasi per Platform|Tabel Rangkuman Konfigurasi per Platform.]]
6. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#6. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
7. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#7. Contoh Output Build yang Berhasil|Output Build yang Berhasil.]]
8. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#8. Kesimpulan|Kesimpulan.]]

---

### [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#BAB 16 - "setup_godot_cpp.py" (MANAJEMEN BINDING)|BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) - SEMUA FUNGSI EKSPLISIT]]

1. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#1. Pendahuluan Mengelola Binding Godot-CPP|Mengelola Binding Godot-CPP.]]
2. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#2. Fungsi Pembaca Opsi dari `build_options.json`|Fungsi Pembaca Opsi dari "build_options.json".]]
3. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#3. Konstanta dan Variabel Global|Konstanta dan Variabel Global.]]
4. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#4. Fungsi `jalankan()` - Wrapper Subprocess|Fungsi `jalankan()` - Wrapper Subprocess.]]
5. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#5. Fungsi `cek_command_ada()` - Mengecek Command di PATH|Fungsi `cek_command_ada()` - Mengecek Command di PATH.]]
6. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#6. Fungsi `cek_branch_ada_di_remote()` - Cek Branch di GitHub|Cek Branch di GitHub.]]
7. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#7. Fungsi `clone_godot_cpp()` - Logika Cloning|Logika Cloning.]]
8. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#8. Fungsi `sudah_dicompile()` - Cek Status Kompilasi|Penentuan Cek Status Kompilasi.]]
9. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#9. Fungsi `compile_godot_cpp()` - Mengompilasi Binding|Mengompilasi Binding.]]
10. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#10. Fungsi `hapus_godot_cpp()` - Menghapus Folder Binding|Menghapus Folder Binding.]]
11. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#11. Fungsi `main()` - Alur Eksekusi Utama|Alur Eksekusi Utama.]]
12. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#12. Blok `if __name__ == "__main__" `|Blok `if __name__ == "__main__":`]]
13. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#13. Tabel Rangkuman Fungsi `setup_godot_cpp.py`|Tabel Rangkuman Fungsi `setup_godot_cpp.py`.]]
14. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#14. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
15. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#15. Alur Lengkap `setup_godot_cpp.py`|Alur Lengkap `setup_godot_cpp.py`.]]
16. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#16. Kesimpulan|Kesimpulan.]]

---

### [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#BAB 17 – EKSEKUSI AKHIR SHELL DAN PENUTUPAN|BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN]]

1. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#1. Pendahuluan Titik Akhir Perjalanan|Titik Akhir Perjalanan.]]
2. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#2. Akhir dari `jalankan_bootstrapper.sh` - Perintah Eksekusi Python|Akhir dari Perintah Eksekusi Python.]]
3. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#3. Blok `if __name__ == "__main__" ` di `bootstrap_scons_gui.py`|Blok Entry Point di "bootstrap_scons_gui.py".]]
4. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#4. Blok `if __name__ == "__main__" ` di `setup_godot_cpp.py`|Blok Entry Point di "setup_godot_cpp.py".]]
5. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#5. Penanganan Exception di `curses.wrapper()`|Penanganan Exception di Curses Wrapper.]]
6. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#6. Pesan "Press ENTER to close this window..." – Self-Relaunch Terminal|Self-Relaunch Terminal.]]
7. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#7. Alur Lengkap dari Awal hingga Akhir|Alur Lengkap dari Awal hingga Akhir.]]
8. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#8. Tabel Rangkuman Entry Points|Tabel Rangkuman Entry Points.]]
9. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#9. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
10. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#10. Troubleshooting Umum|Troubleshooting Umum.]]
11. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#11. Kesimpulan|Kesimpulan.]]

---

### [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP|BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP]]

1. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#1. Pendahuluan Dokumentasi Interaktif di Dalam Menu|Dokumentasi Interaktif di Dalam Menu.]]
2. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#2. Struktur Data `HELP_ITEMS`|Struktur Data `HELP_ITEMS`.]]
3. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#3. Konten Help - Bagian 1 BUILD OPTIONS|Konten Help - Bagian 1: BUILD OPTIONS.]]
4. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#4. Konten Help - Bagian 2 GODOT-CPP|Konten Help - Bagian 2: GODOT-CPP.]]
5. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#5. Konten Help - Bagian 3 ACTIONS|Konten Help - Bagian 3: ACTIONS.]]
6. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#6. Konten Help - Bagian 4 OTHER|Konten Help - Bagian 4: OTHER.]]
7. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#[[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#7. Tabel Rangkuman Konten Help|Tabel Rangkuman.]]
8. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#8. Pemeliharaan Data Help|Pemeliharaan Data Help.]]
9. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#9. Keterkaitan dengan Fitur Baru v2.4.0|Keterkaitan dengan Fitur Baru v2.4.0.]]
10. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#10. Kesimpulan|Kesimpulan.]]

---

###  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI|BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI]]

1.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#1. Pendahuluan Panduan Praktis untuk Pengembang|Panduan Praktis untuk Pengembang.]]
2.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#2. Tabel Final File yang Boleh Diedit vs Tidak|File yang Boleh Diedit vs Tidak.]]
3.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#3. Tabel Final Folder yang Boleh Diedit vs Tidak|Folder yang Boleh Diedit vs Tidak.]]
4.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#4. Skenario Kerja Pengembang|Skenario Kerja Pengembang.]]
5.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#5. Peringatan Jangan Tekan `[Generate!]` Sembarangan!|Peringatan Kritis: Jangan Tekan `[Generate!]` Sembarangan!]]
6.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#6. Cara Backup dan Pemulihan `build_logic.py`|Cara Backup dan Pemulihan `build_logic.py` (Git atau Salinan Manual).]]
7.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#7. Penutup dan Saran Eksplorasi|Penutup dan Saran Eksplorasi.]]
8.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#8. Tabel Rangkuman|Tabel Rangkuman.]]
9.  [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#9. Keterkaitan dengan Bab Lain|Keterkaitan dengan Bab Lain.]]
10. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#10. Kesimpulan|Kesimpulan.]]

---

### [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#BAB 20 - `LICENSE_TEXT` DAN MANAJEMEN LISENSI|BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI]]

1. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#1. Pendahuluan Kepatuhan Hukum dalam Sistem Build|Kepatuhan Hukum dalam Sistem Build.]]
2. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#2. Konstanta `LICENSE_TEXT` - Placeholder Teks Lisensi|Konstanta `LICENSE_TEXT` - Placeholder untuk teks GPL-3.0 (harus diisi user sebelum digunakan).]]
3. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#3. Fungsi `show_scrollable_dialog()` - Menampilkan Teks Panjang|Menampilkan Teks Panjang.]]
4. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#4. Menu `[ View License ]` - Menampilkan Lisensi di Curses|Menampilkan Lisensi di Curses.]]
5. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#5. Menu `[ Export License ]` - Mengekspor Lisensi ke File|Mengekspor Lisensi ke File.]]
6. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#6. Alur Pengisian Lisensi - Panduan Langkah demi Langkah|Alur pengisian lisensi.]]
7. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File|Deklarasi Lisensi di Awal File.]]
8. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File|Keterkaitan dengan GPL-3.0 - Implikasi dan Kewajiban.]]
9. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#9. Tabel Rangkuman Komponen Lisensi|Tabel Rangkuman Komponen Lisensi.]]
10. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#10 Troubleshooting Lisensi|Troubleshooting Lisensi.]]
11. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#11. Praktik Terbaik untuk Manajemen Lisensi|Praktik Terbaik untuk Manajemen Lisensi.]]
12. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#12. Kesimpulan|Kesimpulan.]]

---

## PENUTUP DARI PENULIS

Dokumen ini bukanlah sesuatu yang lahir dalam semalam. Ia adalah hasil dari:
- **Bacaan** - puluhan kali membaca ulang kode `jalankan_bootstrapper.sh`.
- **Analisis** - memahami setiap fungsi, setiap percabangan, setiap heredoc.
- **Penulisan** - menyusun 20 bab dengan total puluhan ribu kata.
- **Revisi** - menyesuaikan dengan masukan dan pertanyaan dari pembaca.

Jika ada satu hal yang saya harap pembaca dapatkan dari dokumen ini, itu adalah:

> [!quote] **"Saya sekarang mengerti bagaimana sistem ini bekerja, dan saya tahu di mana harus mencari jika ada yang perlu diubah."**

Kode yang baik adalah kode yang bisa dipahami. Dan kode yang bisa dipahami adalah kode yang didokumentasikan dengan baik. Saya harap dokumen ini memenuhi standar itu.

Terima kasih telah membaca sampai akhir.


 --- **DeepSeek** (Penyempurnaan Dokumentasi) dan **Kokhav Gel Erev** (Penulis Dokumentasi)
