# BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM

---

## 1. Pendahuluan: Mengapa Dokumentasi Ini Dibutuhkan?

Sistem build KOBI GDExtension adalah sebuah **ekosistem lengkap** untuk mengembangkan ekstensi Godot 4 menggunakan C++ dan GDExtension API. Namun, yang membuat sistem ini unik bukanlah fitur teknisnya semata, melainkan **cara ia dikemas dan disampaikan kepada pengguna**: sebagai **satu file shell script** yang mampu meregenerasi dirinya sendiri, menciptakan antarmuka pengguna berbasis terminal (curses), dan mengelola seluruh proses build dari awal hingga akhir. ^850f27

Dokumentasi ini hadir untuk membedah setiap baris kode, setiap keputusan desain, dan setiap alur eksekusi dari sistem tersebut. Dengan membaca dokumen ini, Anda akan memahami:

1. [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#Masalah dengan Pendekatan Tradisional|Mengapa sistem dirancang sebagai satu file shell script.]]
2. [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#6. Ikhtisar Alur Eksekusi|Bagaimana file shell script tersebut menghasilkan file Python dan menjalankannya.]]
3. [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#^c9cd43|Bagaimana antarmuka curses bekerja tanpa perlu menginstal library tambahan.]]
4. [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#^f0a5a8|Bagaimana proses build SCons dikonfigurasi dan dijalankan.]]
5. [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#^0d831e|Bagaimana manajemen binding godot-cpp dilakukan secara otomatis.]]

Dokumentasi ini ditulis dengan gaya **teknis yang mendalam**, mencakup lokasi baris kode yang tepat (dengan format `(Lokasi Baris X-Y)`), tabel perbandingan, referensi silang antar bab, dan penjelasan panjang yang memastikan tidak ada detail yang terlewat.

> [!note] **Catatan untuk Pembaca**
Dokumentasi ini mengacu pada file `jalankan_bootstrapper.sh` versi **2.4.0** (26 Juli 2026). Semua lokasi baris yang disebutkan merujuk pada versi tersebut.

---

## 2. Latar Belakang: Mengapa Butuh Bootstrapper Satu File?

### Tantangan Pengembangan GDExtension
Mengembangkan GDExtension untuk Godot 4 melibatkan beberapa lapisan kompleksitas:
1. **Binding C++** - pengembang harus mengelola godot-cpp (binding resmi dari Godot) yang harus dikompilasi terlebih dahulu sebelum kode ekstensi dapat dikompilasi. ^0d831e
2. **Cross-compilation** - ekstensi harus dikompilasi untuk berbagai platform (Linux, Windows, dan idealnya macOS dan Android), yang memerlukan toolchain berbeda.
3. **Konfigurasi build** - SCons (sistem build yang digunakan Godot) memerlukan file `SConstruct` yang kompleks dengan banyak opsi. ^f0a5a8
4. **Manajemen versi** - godot-cpp memiliki banyak branch (3.x, 4.0, 4.1, 4.2, ..., master) dan setiap versi memiliki API yang sedikit berbeda.
5. **Logging dan debugging** - proses build yang gagal harus meninggalkan jejak yang cukup untuk dilacak.

### Masalah dengan Pendekatan Tradisional
Pendekatan tradisional untuk mengelola kompleksitas ini biasanya melibatkan:
- **Dokumentasi terpisah** - pengguna harus membaca README, menginstall dependensi, dan menjalankan perintah manual.
- **Beberapa file** - `SConstruct`, skrip setup, skrip build, dan file konfigurasi terpisah.
- **Instalasi dependensi** - pengguna harus menginstall Python, SCons, Git, compiler, dan seringkali library tambahan seperti `python3-tk` untuk GUI.

**Masalah utamanya:** Pengguna baru seringkali tersesat. Mereka harus:
1. Membaca dokumentasi.
2. Menginstall dependensi yang mungkin tidak disebutkan dengan jelas.
3. Menjalankan perintah di terminal dengan argumen yang tepat.
4. Memahami error yang muncul jika ada yang salah.

### Solusi: Bootstrapper Satu File

`jalankan_bootstrapper.sh` adalah solusi untuk semua masalah di atas. Dengan **satu file**, pengguna dapat:
1. **Mengklik file** (atau menjalankannya di terminal) - tanpa perlu membaca dokumentasi terlebih dahulu.
2. **Mendapatkan antarmuka** - menu curses yang intuitif muncul secara otomatis.
3. **Mengatur opsi** - memilih mode build, platform, arsitektur, dan versi godot-cpp.
4. **Menjalankan setup** - meng-clone dan mengompilasi godot-cpp secara otomatis.
5. **Menjalankan build** - mengompilasi ekstensi dengan sekali klik.

**Inti dari solusi ini adalah:** semua logika, semua template file, dan semua antarmuka pengguna di-_embed_ di dalam satu file shell script. File tersebut kemudian menulis ulang file-file Python yang diperlukan dan menjalankannya. Ini adalah pendekatan **self-extracting archive** yang sudah dikenal di dunia Windows (misal file `.exe` yang mengekstrak dirinya sendiri), tetapi diimplementasikan di lingkungan Linux dengan Bash dan Python.

---

## 3. Filosofi Desain: Self-Contained, Regeneratif, dan Terminal-First

Sistem build KOBI GDExtension dibangun di atas tiga pilar filosofi utama:

### Self-Contained (Mandiri)

> [!quote] **"Satu file, tidak ada yang lain."**

- Semua kode (Bash, Python, template file) berada di **satu file shell script**.
- Tidak ada dependensi tambahan selain yang sudah menjadi standar di sebagian besar distribusi Linux: `bash`, `python3`, `scons`, `git`, dan compiler (`g++`, `mingw-w64`).
- Tidak perlu mengunduh file terpisah, tidak perlu menyalin template, tidak perlu menginstall library Python tambahan (kecuali yang sudah ada di standard library).    

**Implementasi:** File `jalankan_bootstrapper.sh` berisi dua heredoc raksasa:

- `PYEOF_INNER` - berisi seluruh kode `bootstrap_scons_gui.py` (~1400 baris).
- `PYEOF_SETUP` - berisi seluruh kode `setup_godot_cpp.py` (~220 baris).

Saat script dijalankan, ia menulis file-file ini ke disk, lalu menjalankannya.

### Regeneratif (Self-Healing dan Self-Generating)

> [!quote] **"Memperbaiki ulang Komponennya sendiri setiap kali di jalankan"**

- **Self-heal permission** - script secara otomatis menjalankan `chmod +x` pada dirinya sendiri dan file `.desktop` setiap kali dijalankan (Bab 3). ^cecf3e
- **Self-generating** - script menulis ulang file Python setiap kali dijalankan, memastikan pengguna selalu memiliki versi terbaru (Bab 5). ^3bbebb
- **Backup otomatis** - `build_options.json` di-backup ke `.bak` sebelum ditimpa (Bab 8).
- **Rotasi log** - log di-rotate secara otomatis setelah mencapai `MAX_HISTORY` (Bab 14).

**Filosofi di balik ini:** Pengguna tidak boleh bergantung pada pengetahuan teknis untuk memelihara sistem. Sistem harus memelihara dirinya sendiri.

### Terminal-First (Namun Ramah Pengguna)

> [!quote] **"Berjalan di terminal, tetapi serasa seperti di aplikasi."**

- **Antarmuka curses** - menggunakan library curses (bawaan Python) untuk menampilkan menu yang interaktif, dengan warna, navigasi keyboard, dan dialog (Bab 10–11). ^c9cd43
- [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#2. Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`|File `.desktop` otomatis]] - pengguna dapat mengklik ikon di file manager untuk menjalankan script.
- **Self-relaunch** - jika script dijalankan tanpa terminal (misal diklik dari file manager), ia akan membuka terminal sendiri (Bab 4 dan 6).
- **Pesan yang jelas** - semua error dan status ditampilkan dengan warna dan format yang mudah dibaca (Bab 13 -14).

**Filosofi di balik ini:** Terminal adalah alat yang kuat, tetapi tidak semua pengguna nyaman menggunakannya. Sistem harus menjembatani kesenjangan antara "kekuatan terminal" dan "kemudahan GUI".

---

## 4. Siapa Target Pengguna Sistem Ini?

Sistem build KOBI GDExtension dirancang untuk **tiga kelompok pengguna**:

> [!hint]- Pengembang Game Godot Pemula
> ### Pengembang Game Godot Pemula
> - **Karakteristik:** Ingin membuat ekstensi C++ untuk Godot, tetapi tidak terbiasa dengan terminal, SCons, atau cross-compilation.
> - **Kebutuhan:** Sistem yang "works out of the box" dengan antarmuka yang jelas.
> - **Bagaimana sistem membantu:** Menu curses yang intuitif, setup otomatis godot-cpp, dan pesan error yang jelas.

> [!hint]- Pengembang Game Godot Berpengalaman
> ### Pengembang Game Godot Berpengalaman
> - **Karakteristik:** Sudah familiar dengan Godot dan C++, tetapi ingin menghemat waktu dalam konfigurasi build.
> - **Kebutuhan:** Sistem yang fleksibel dan dapat dikustomisasi dengan cepat.
> - **Bagaimana sistem membantu:** Opsi build yang lengkap (mode, platform, arsitektur, jobs), manajemen versi godot-cpp, dan file `build_options.json` yang dapat diedit manual.

> [!hint]- Kontributor Open Source dan Pengembang Sistem
> ### Kontributor Open Source dan Pengembang Sistem
> 
> - **Karakteristik:** Ingin memahami, memodifikasi, atau memperluas sistem build.
> - **Kebutuhan:** Kode yang terstruktur, terdokumentasi, dan mudah dipahami.
> - **Bagaimana sistem membantu:** Dokumentasi ini (yang Anda baca sekarang), komentar inline di kode, dan arsitektur modular (shell > Python > SCons).

---

## 5. Prasyarat Sistem (Dependensi yang Harus Ada)

Sistem build KOBI GDExtension memerlukan **beberapa dependensi** yang harus diinstall di sistem pengguna. Berikut adalah daftar lengkapnya:

> [!warning]+ Dependensi yang Wajib ada/ di Install
> ### Dependensi Wajib (Semua Pengguna)
>
> |Dependensi|Perintah Install (Ubuntu/Debian)|Fungsi|
> |---|---|---|
> |**Bash**|(Sudah terinstall di semua distro Linux)|Menjalankan `jalankan_bootstrapper.sh`|
> |**Python 3**|`sudo apt install python3`|Menjalankan `bootstrap_scons_gui.py` dan `setup_godot_cpp.py`|
> |**SCons**|`sudo apt install scons`|Sistem build untuk godot-cpp dan ekstensi|
> |**Git**|`sudo apt install git`|Meng-clone godot-cpp dari GitHub|
> |**g++**|`sudo apt install g++`|Compiler C++ untuk Linux|
> 

> [!tip]- Build for Windows (Opsional) 
> ### Dependensi Opsional (Untuk Build Windows)
> 
> | Dependensi             | Perintah Install (Ubuntu/Debian)                         | Fungsi                              |
> | ---------------------- | -------------------------------------------------------- | ----------------------------------- |
> | **mingw-w64 (64-bit)** | `sudo apt install mingw-w64`                             | Cross-compiler untuk Windows 64-bit |
> | **mingw-w64 (32-bit)** | `sudo apt install mingw-w64-i686-dev g++-mingw-w64-i686` | Cross-compiler untuk Windows 32-bit |
> 

> [!abstract]- Dependensi Python
> ### Dependensi Python (Bawaan Standard Library)
> 
> Semua library Python yang digunakan sudah termasuk dalam **standard library** Python 3, sehingga tidak perlu `pip install` tambahan:
> 
> |Library|Fungsi|
> |---|---|
> |`os`|Operasi sistem file|
> |`sys`|Manipulasi interpreter Python|
> |`shutil`|Operasi file tingkat tinggi (copy, move, rmtree)|
> |`subprocess`|Menjalankan proses eksternal|
> |`curses`|Antarmuka terminal (bawaan di Linux)|
> |`json`|Membaca/menulis file JSON|
> |`glob`|Pencarian file dengan pattern|
> |`datetime`|Manipulasi tanggal dan waktu|
> |`time`|Pengukuran waktu dan sleep|
> |`atexit`|Pendaftaran fungsi saat keluar|
> |`re`|Regular expression (untuk validasi)|
> |`textwrap`|Word wrapping untuk help|
> 

> [!info]- Dependensi untuk curses (Jika Tidak Ada)
> ### Dependensi untuk `curses` (Jika Tidak Ada)
> 
> Pada beberapa distribusi Linux minimalis, library `curses` mungkin tidak terinstall secara default. Jika terjadi error `ImportError: No module named curses`, install dengan:
> 
> ```bash
> sudo apt install python3-curses
> ```
> 

> [!note]- Pengecekan Dependensi di Script
> ### Pengecekan Dependensi di Script
> 
> Script [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#1. Pendahuluan Mengelola Binding Godot-CPP|`setup_godot_cpp.py`]]  secara otomatis memeriksa dependensi:
> 
> ```python
> if not cek_command_ada("git"):
>     print("'git' is not installed. Install it first: sudo apt install git")
>     sys.exit(1)
> if not cek_command_ada("scons"):
>     print("'scons' is not installed / not found in PATH.")
>     sys.exit(1)
> ```
> 
> Jika ada dependensi yang hilang, script akan berhenti dan memberi tahu pengguna cara menginstallnya.

---

## 6. Ikhtisar Alur Eksekusi

Sebelum kita menyelami setiap bab secara mendetail, berikut adalah **gambaran besar** tentang bagaimana sistem bekerja dari awal hingga akhir:

> [!info]- Tahap 1
> ### Tahap 1: Pengguna Menjalankan Shell Script
> 
> ```text
> Pengguna mengklik jalankan_bootstrapper.sh (atau menjalankan di terminal)
> 	|
> Bash interpreter membaca shebang #!/bin/bash
> 	|
> Script mengunci direktori kerja ke lokasi script (Bab 2)
> 	|
> Script membuat .desktop dan self-heal permission(Bab 3)
> 	|
> Script mendeteksi apakah berjalan di terminal interaktif (Bab 4)
> 	|
> Jika tidak, script membuka terminal baru dan menjalankan ulang dirinya sendiri
> ```

> [!info]- Tahap 2
> ### Tahap 2: Script Menulis File Python
> 
> ```text
> Script menulis bootstrap_scons_gui.py dari heredoc PYEOF_INNER (Bab 5)
> 	|
> Script menulis setup_godot_cpp.py dari heredoc PYEOF_SETUP (Bab 16)
> 	|
> Script menjalankan python3 bootstrap_scons_gui.py
> ```
> 

> [!info]- Tahap 3
> ### Tahap 3: Antarmuka Curses (bootstrap_scons_gui.py)
> 
> ```text
> Python script mendeteksi apakah berjalan di terminal interaktif (Bab 6)
> 	|
> Jika tidak, script membuka terminal baru dan menjalankan ulang dirinya sendiri
> 	|
> curses.wrapper(main) menginisialisasi antarmuka curses (Bab 11)
> 	|
> Dialog awal: "Buat folder proyek baru?" (Bab 10)
> 	|
> Load opsi dari build_options.json (Bab 8)
> 	|
> Loop utama menu (Bab 11):
>    - Render menu dengan render_menu() (Bab 10)
>    - Tunggu input keyboard (↑/↓, ←/→, ENTER/SPACE, H, Q)
>    - Proses navigasi dan perubahan opsi
>    - Eksekusi aksi (setup, generate, credits, dll)
> ```
> 

> [!info]- Tahap 4
> ### Tahap 4: Setup godot-cpp (Jika Dipilih)
> 
> ```text
> Menu [ Setup godot-cpp ] dipilih (Bab 11)
> 	|
> run_subprocess_in_curses() menjalankan setup_godot_cpp.py (Bab 10)
> 	|
> setup_godot_cpp.py membaca build_options.json (Bab 16)
> 	|
> Jika folder godot-cpp belum ada → git clone (Bab 16)
> 	|
> Jika folder sudah ada → tanya redownload (Bab 16)
> 	|
> Compile godot-cpp untuk Linux (dan Windows jika mingw terinstall) (Bab 16)
> ```

> [!info]- Tahap 5
> ### Tahap 5: Generate File Build
> 
> ```text
> Menu [ Generate! ] dipilih (Bab 11)
> 	|
> confirm_generate() menampilkan ringkasan opsi (Bab 10)
> 	|
> Jika disetujui → save_options() (Bab 8)
> 	|
> generate_files() menulis SConstruct dan build_logic.py (Bab 12)
> 	|
> Kembali ke menu utama
> ```

> [!info]- Tahap 6
> ### Tahap 6: Build dengan SCons (Di Jalankan Pengguna)
> 
> ```text
> Pengguna keluar dari menu dan menjalankan scons di terminal
> 	|
> SCons membaca SConstruct (Bab 12)
> 	|
> SConstruct menjalankan exec(open("build_logic.py").read()) (Bab 12)
> 	|
> build_logic.py membaca build_options.json (Bab 13)
> 	|
> build_with_logging() mengompilasi semua source di src/**/*.cpp (Bab 15)
> 	|
> Hasil compile disimpan di bin/{plat}_{bits}_{mode}/ (Bab 15)
> 	|
> generate_gdextension() membuat compile.gdextension (Bab 15)
> 	|
> Jika sukses → write_logs() mencatat ke JSON dan Markdown (Bab 14)
> 	|
> Jika gagal → report_build_failures() mencatat error (Bab 14)
> ```

### Diagram Alur Visual

```text
┌─────────────────────────────────────────────────────────────────┐
│                    jalankan_bootstrapper.sh                     │
│  (Shell script utama yang di-klik/dijalankan pengguna)          │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Bab 2: Shebang & Inisialisasi                                  │
│  - #!/bin/bash                                                  │
│  - cd "$(dirname "$0")"                                         │
│  - SCRIPT_ABS="$(readlink -f "$0")"                             │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Bab 3: .desktop & Self-Heal Permission                         │
│  - Buat Jalankan KOBI Bootstrapper.desktop                      │
│  - chmod +x pada .desktop dan script                            │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Bab 4: Self-Relaunch (Bash)                                    │
│  - Deteksi [ ! -t 0 ]                                           │
│  - Buka terminal (gnome-terminal, konsole, xfce4-terminal,      │
│    x-terminal-emulator, xterm)                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Bab 5: Embedding Python Files (Heredoc)                        │
│  - cat > bootstrap_scons_gui.py << 'PYEOF_INNER'                │
│  - cat > setup_godot_cpp.py << 'PYEOF_SETUP'                    │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              python3 bootstrap_scons_gui.py                     │
│  (Antarmuka curses - Bab 6-12)                                  │
└─────────────────────────────────────────────────────────────────┘
                              │
              ┌───────────────┼───────────────┐
              ▼               ▼               ▼
┌─────────────────────┐ ┌─────────────────┐ ┌─────────────────────┐
│  Menu: Setup        │ │  Menu: Generate │ │  Menu: Credits      │
│  godot-cpp          │ │  !              │ │  / License          │
│  (Bab 16)           │ │  (Bab 12)       │ │  (Bab 20)           │
└─────────────────────┘ └─────────────────┘ └─────────────────────┘
        │                       │
        ▼                       ▼
┌─────────────────────┐ ┌─────────────────────────────────────────┐
│ setup_godot_cpp.py  │ │ generate_files() → SConstruct           │
│ - Clone godot-cpp   │ │                     + build_logic.py    │
│ - Compile binding   │ │                     (Bab 13-15)         │
└─────────────────────┘ └─────────────────────────────────────────┘
                                      │
                                      ▼
                              ┌───────────────────┐
                              │  scons (di        │
                              │  terminal)        │
                              └───────────────────┘
                                      │
                                      ▼
                              ┌───────────────────┐
                              │  build_logic.py   │
                              │  (Bab 13-15)      │
                              │  - Build engine   │
                              │  - Logging        │
                              │  - GDExtension    │
                              └───────────────────┘
                                      │
                                      ▼
                              ┌───────────────────┐
                              │  Output: bin/     │
                              │  compile.{plat}.  │
                              │  {bits}{ext}      │
                              │  compile.         │
                              │  gdextension      │
                              └───────────────────┘
```
---

## 7. Tabel Rangkuman

| Sub-Bab | Topik                                                        | Halaman |
| ------- | ------------------------------------------------------------ | ------- |
| 1       | Pendahuluan: Mengapa Dokumentasi Ini Dibutuhkan              | 1       |
| 2       | Latar Belakang: Mengapa Butuh Bootstrapper Satu File?        | 1 - 2   |
| 3       | Filosofi Desain: Self-Contained, Regeneratif, Terminal-First | 2 - 3   |
| 4       | Siapa Target Pengguna Sistem Ini?                            | 3       |
| 5       | Prasyarat Sistem (Dependensi yang Harus Ada)                 | 3 - 4   |
| 6       | Ikhtisar Alur Eksekusi dari 30.000 Kaki                      | 4 - 5   |

---


## 8. Keterkaitan dengan Bab Lain

| Konsep di Bab 1                                                                                                                    | Dibahas Lebih Lanjut di Bab                          |
| ---------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------- |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#Self-Contained (Mandiri)\|Self-contained (satu file)]]                                   | Bab 5 (Embedding Python via Heredoc)                 |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#^cecf3e\|Self-Heal Permission]]                                                          | Bab 3 (chmod +x pada script dan .desktop)            |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#^3bbebb\|Self-generating]]                                                               | Bab 5 (Menulis ulang file Python)                    |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#Terminal-First (Namun Ramah Pengguna)\|Terminal-first + ramah pengguna]]                 | Bab 4 (Self-relaunch), Bab 10 -11 (Curses UI)        |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#5. Prasyarat Sistem (Dependensi yang Harus Ada)\|Prasyarat sistem (Python, SCons, Git)]] | Bab 16 (Pengecekan dependensi di setup_godot_cpp.py) |
| [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#6. Ikhtisar Alur Eksekusi dari 30.000 Kaki\|Alur eksekusi]]                              | Seluruh bab 2 - 17                                   |

---

## 9. Kesimpulan

Pada bab ini, kita telah membahas **fondasi konseptual** dari sistem build KOBI GDExtension. Kita mempelajari:
1. **Latar Belakang** - mengapa sistem build GDExtension kompleks dan bagaimana bootstrapper satu file menyederhanakannya.
2. **Filosofi Desain** - tiga pilar utama: Self-Contained, Regeneratif, dan Terminal-First.
3. **Target Pengguna** - tiga kelompok: pemula, berpengalaman, dan kontributor.
4. **Prasyarat Sistem** - dependensi wajib (Bash, Python3, SCons, Git, g++) dan opsional (mingw-w64).
5. **Ikhtisar Alur Eksekusi** - gambaran besar dari awal hingga akhir, dalam 6 tahap.