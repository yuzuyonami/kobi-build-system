# BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP

---

## 1. Pendahuluan: Dokumentasi Interaktif di Dalam Menu

Setelah kita menyelesaikan seluruh alur eksekusi dan komponen teknis sistem (Bab 1 - 17), kini tiba saatnya untuk membahas salah satu fitur **paling ramah pengguna** dari antarmuka curses: **Help Window**. Fitur ini memungkinkan pengguna mengakses dokumentasi interaktif tentang setiap opsi dan aksi di menu utama hanya dengan menekan tombol `H`.

Pada Bab 18, kita akan membahas:
1. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#2. Struktur Data `HELP_ITEMS`|Struktur data `HELP_ITEMS` - format dan isi dari seluruh konten help.]]
2. Tipe-tipe item - `section`, `body`, dan `blank` - serta bagaimana mereka dirender.]]
3. Konten help secara detail - setiap bagian dari help window:
    - [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#3. Konten Help - Bagian 1 BUILD OPTIONS|BUILD OPTIONS - mode build, platform, arsitektur, dan jobs.]]   
    - [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#4. Konten Help - Bagian 2 GODOT-CPP|GODOT-CPP - versi binding, api_version, update versi, setup, dan cleanup.]]
    - [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#5. Konten Help - Bagian 3 ACTIONS|ACTIONS - generate, credits, lisensi, dan keluar. ]]   
    - [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#6. Konten Help - Bagian 4 OTHER|OTHER - last build dan folder otomatis.]]
4. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|Bagaimana `HELP_ITEMS` dirender - oleh help window di `main()`.]]
5. [[BAB 18 - DATA STATIS HELP (`HELP_ITEMS`) - STRUKTUR LENGKAP#8. Pemeliharaan Data Help|Pemeliharaan data help - menjaga sinkronisasi antara help text dan fungsionalitas aktual.]]

Semua data dalam bab ini adalah bagian dari `HELP_ITEMS` yang didefinisikan di **Baris 1042** dari `bootstrap_scons_gui.py` (di dalam `main()`) dan memiliki panjang sekitar 80 baris.

> [!quote] 📌 **Referensi Silang:**
> - `HELP_ITEMS` dirender di help window di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]].
> - `HELP_ITEMS` menggunakan [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]] seperti rendering.
> - Konten help merujuk ke opsi-opsi yang dijelaskan di Bab 8 dan aksi-aksi di Bab 11.

---

## 2. Struktur Data `HELP_ITEMS`

`HELP_ITEMS` adalah **list of tuples** dengan format `(kind, teks)`:

| `kind`      | Deskripsi                                                                 | Style                  |
| ----------- | ------------------------------------------------------------------------- | ---------------------- |
| `"section"` | Judul bagian (ditampilkan dengan style `STYLE["section"]` – bold + warna) | Tebal, warna cerah     |
| `"body"`    | Teks penjelasan (ditampilkan dengan style normal)                         | Normal (putih/default) |
| `"blank"`   | Baris kosong untuk spasi visual                                           | Tidak ada teks         |

### Mengapa Menggunakan Data Terstruktur?
Dengan menggunakan data terstruktur, help window dapat:
- **Menerapkan style berbeda** untuk section dan body.
- **Melakukan word wrapping** secara otomatis (dengan `textwrap`).
- **Mendeteksi indentasi** - baris `body` yang diawali dengan dua spasi akan di-indent dengan benar setelah wrapping.

### Word Wrapping di Help Window
Di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#3. Help Window - Dokumentasi Interaktif|help window]], setiap baris `body` di-**wrap** dengan `textwrap.wrap()` agar pas dengan lebar terminal. Indentasi (dua spasi) dipertahankan.

```python
indent = "  " if teks.startswith("  ") else ""
untuk_wrap = teks.strip()
lebar_wrap = max(10, lebar_konten - len(indent))
potongan = _textwrap.wrap(untuk_wrap, lebar_wrap) or [""]
for p in potongan:
    baris_wrap.append((kind, f"{indent}{p}"))
```

---

## 3. Konten Help - Bagian 1: BUILD OPTIONS

### Section Header

*(Lokasi Baris 1376)*
```python
("section", "BUILD OPTIONS"),
```

Bagian ini menjelaskan opsi-opsi yang mengontrol **bagaimana proyek dikompilasi**.

### Build Mode

*(Lokasi Baris 1377 - 1380)*
```python
("body", "Build mode"),
("body", "  Debug   -> slow & large compile, but easy to trace if there's a bug/crash"),
("body", "  Release -> most optimized & fastest compile, but error messages are less clear"),
("blank", ""),
```

**Penjelasan:**
- **Debug** - menambahkan flag `-g` (debug symbols) dan `-O0` (no optimization). Hasil compile lebih lambat dan lebih besar, tetapi memudahkan debugging dengan GDB atau debugger lain. Macro `DEBUG_ENABLED` didefinisikan, yang bisa digunakan di kode C++ untuk conditional compilation.
- **Release** - menambahkan flag `-O3` (optimasi maksimum). Hasil compile lebih cepat dan lebih kecil, tetapi pesan error kurang jelas karena simbol debug dihilangkan. Macro `NDEBUG` didefinisikan, yang menghilangkan `assert()`.

**Kaitan dengan Bab:** Opsi `mode` dijelaskan di [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#BAB 8 - `bootstrap_scons_gui.py` MANAJEMEN OPSI (`build_options.json`)|Bab 8 (`build_options.json`)]] dan diimplementasikan di [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|Bab 15 (`build_with_logging()`]]).

### Platform (Linux/Windows)

*(Lokasi Baris 1381 - 1383)*
```python
("body", "Linux Platform / Windows Platform"),
("body", "  Toggle active/inactive -- which targets to compile. At least 1 must be active."),
("blank", ""),
```

**Penjelasan:**
- Pengguna dapat mengaktifkan atau menonaktifkan platform Linux dan Windows secara independen.
- Setidaknya **satu platform harus aktif** - jika tidak, menu `[ Generate! ]` akan menolak dengan pesan error.
- Platform aktif menentukan:
    - Target yang akan dibangun di `build_logic.py`.
    - Entri yang akan muncul di `compile.gdextension`.

**Kaitan dengan Bab:** Opsi [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default|`platforms` dijelaskan di Bab 8]] dan diimplementasikan di [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#2. Fungsi `generate_gdextension()` - Membuat File `.gdextension`|Bab 15  (loop `targets`)]].

### Arsitektur (64-bit / 32-bit)

*(Lokasi Baris 1384 - 1388)*
```python
("body", "Architecture (64-bit / 32-bit)"),
("body", "  Toggle bit-width for both the project build and godot-cpp itself. 32-bit"),
("body", "  needs the matching mingw-w64 32-bit compiler installed for Windows builds"),
("body", "  (i686-w64-mingw32-g++), separate from the 64-bit one."),
("blank", ""),
```

**Penjelasan:**
- Opsi `bits` (v2.4.0) mengontrol arsitektur target: 64-bit atau 32-bit.
- **Dampak:**
    - Nama folder output: `bin/{plat}_{bits}_{mode}/`.
    - Argumen `arch` di SCons: `x86_64` atau `x86_32`.
    - Compiler Windows: `x86_64-w64-mingw32-g++` (64-bit) atau `i686-w64-mingw32-g++` (32-bit).
    - Flag Linux: `-m64` atau `-m32`.
- Untuk Windows 32-bit, **compiler terpisah** harus diinstall (`i686-w64-mingw32-g++`), yang tidak selalu tersedia secara default. `setup_godot_cpp.py` akan mendeteksi dan memberikan saran instalasi.

**Kaitan dengan Bab:** [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#BAB 8 - `bootstrap_scons_gui.py` MANAJEMEN OPSI (`build_options.json`)|Opsi `bits` dijelaskan di Bab 8]] dan [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#6. Keterkaitan dengan Fitur Baru v2.4.0|diimplementasikan di Bab 15]].

### Parallel Jobs

(Lokasi Baris 1389 - 1391)
```python
("body", "Parallel jobs"),
("body", "  Number of parallel compile processes (cycle: auto -> 2 -> 4 -> 8)."),
("blank", ""),
```

**Penjelasan:**
- Opsi `jobs` mengontrol berapa banyak proses kompilasi yang berjalan secara paralel.
- **`0` (auto)** - menggunakan semua core CPU (via `os.cpu_count()` di SCons).
- **`2`, `4`, `8`** - jumlah proses tetap.
- Cycle: `0` > `2` > `4` > `8` > kembali ke `0`.
- Semakin banyak proses paralel, semakin cepat build (tergantung jumlah core dan RAM).

**Kaitan dengan Bab:** Opsi `jobs` dijelaskan di Bab 8 dan diimplementasikan di Bab 13 (`SetOption("num_jobs", ...)`).

---

## 4. Konten Help - Bagian 2: GODOT-CPP

### Section Header

*(Lokasi Baris 1392)*
```python
("section", "GODOT-CPP"),
```

Bagian ini menjelaskan opsi-opsi yang terkait dengan **manajemen binding godot-cpp**.

### godot-cpp Version

*(Lokasi Baris 1393 - 1399)*
```python
("body", "godot-cpp version"),
("body", "  Toggle between available branches (4.0-4.5 etc), 'master', or"),
("body", "  'custom...' to type a branch freely. This version's compile status shows"),
("body", "  right next to its name (not downloaded / not compiled /"),
("body", "  compiled). IMPORTANT: godot-cpp 10.x no longer has per-version branches"),
("body", "  for Godot 4.6 and up -- use 'master' + set Target api_version below instead."),
("blank", ""),
```

**Penjelasan:**
- Opsi `godot_cpp_branch` memilih versi godot-cpp yang akan digunakan.
- **Daftar versi** - diambil dari cache lokal (Bab 7), diperbarui dengan menu `[ Update version list ]`.
- **`master`** - branch utama godot-cpp 10.x, digunakan untuk Godot 4.6 ke atas.
- **`custom...`** - memungkinkan pengguna mengetik branch secara manual (misal `4.5-rc1`).

- **Status kompilasi** - ditampilkan di sebelah nama versi di menu utama (Bab 10):
    - `not downloaded yet` - folder belum ada.
    - `downloaded, not compiled yet` - folder ada tapi belum di-compile.
    - `compiled: linux only` / `compiled: windows only` / `compiled: linux+windows`.

**Kaitan dengan Bab:** Opsi `branch` dijelaskan di Bab 8, daftar versi di Bab 7, status di Bab 7 (`get_godot_cpp_status()`).

### Target api_version

*(Lokasi Baris 1400 - 1404)*
```python
("body", "Target api_version"),
("body", "  Only applies when godot-cpp version = master. Determines which Godot"),
("body", "  version is targeted at compile time (e.g. 4.7). Presets: 4.3/4.4/4.5/4.6/4.7, or"),
("body", "  'custom...' for another version."),
("blank", ""),
```

**Penjelasan:**
- Opsi `api_version` **hanya berlaku** jika `branch == "master"`.
- Menentukan versi Godot yang menjadi target saat mengompilasi godot-cpp.
- **Preset:** `4.3`, `4.4`, `4.5`, `4.6`, `4.7` (tergantung dukungan di godot-cpp master).
- **`custom...`** - memungkinkan pengguna mengetik versi secara manual (misal `4.8`).
- Format harus **angka.angka** - divalidasi oleh [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#5. Fungsi `validasi_format_versi(versi)` - Validasi Input Custom|`validasi_format_versi()`]].

**Kaitan dengan Bab:** [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default|Opsi `api_version` dijelaskan di Bab 8]] dan diimplementasikan di [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#9. Fungsi `compile_godot_cpp()` - Mengompilasi Binding|Bab 16 (`compile_godot_cpp()`]] dengan `api_version=`).

### Update Version List

*(Lokasi Baris 1405 - 1411)*
```python
("body", "[ Update version list (check GitHub) ]"),
("body", "  Pulls the list of OLD version branches from GitHub godot-cpp (number.number"),
("body", "  format, oldest to newest), saved as a local cache. 'master' and"),
("body", "  'custom...' are always in the toggle regardless, since godot-cpp"),
("body", "  10.x no longer creates a new branch per Godot version. If it fails (no"),
("body", "  internet), the old list is still used, nothing breaks."),
("blank", ""),
```

**Penjelasan:**
- Menu `[ Update version list ]` menjalankan `update_daftar_versi_online()` (Bab 7).
- Menarik daftar branch `refs/heads/<maj>.<minr>` dari GitHub
- Menyimpan ke cache lokal `godot_cpp_versi_cache.json`.
- `"master"` dan `"custom..."` selalu ada, tidak tergantung cache.
- Jika gagal (tidak ada internet), cache lama tetap digunakan.

**Kaitan dengan Bab:** [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#8. Fungsi `update_daftar_versi_online()` - Tarik Versi dari GitHub|Fungsi `update_daftar_versi_online()` di Bab 7]].

### Check Installed Godot

*(Lokasi Baris 1412 - 1416)*
```python
("body", "[ Check installed Godot version ]"),
("body", "  Best-effort detection of the Godot editor installed on this system, just"),
("body", "  as a SUGGESTION for which api_version to use -- doesn't change any option"),
("body", "  automatically."),
("blank", ""),
```

**Penjelasan:**
- Menu `[ Check installed Godot ]` menjalankan `cek_godot_terinstall()` (Bab 7).
- Mencari binary `godot4`, `godot`, `godot.x11.opt.tools.64`, `godot-mono` di `PATH`.
- Menjalankan `--version` untuk mendapatkan versi.
- **Hanya saran** - tidak mengubah opsi apapun secara otomatis.
- Berguna untuk menentukan `api_version` yang tepat.

**Kaitan dengan Bab:** [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#8. Fungsi `update_daftar_versi_online()` - Tarik Versi dari GitHub|Fungsi `cek_godot_terinstall()` di Bab 7]].

### View All godot-cpp Versions

*(Lokasi Baris 1417 - 1420)*
```python
("body", "[ View all godot-cpp versions ]"),
("body", "  Lists every godot-cpp-* folder in this project along with its compile"),
("body", "  status and size, without having to toggle through each one."),
("blank", ""),
```

**Penjelasan:**
- Menu `[ View all godot-cpp versions ]` menjalankan [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding|`cek_semua_godot_cpp()`]].
- Memindai semua folder `godot-cpp-*` di direktori proyek.
- Menampilkan: nama folder, status kompilasi, dan ukuran dalam MB.
- Membantu pengguna melihat semua versi yang sudah di-_setup_ tanpa harus toggle satu per satu.

**Kaitan dengan Bab:** Fungsi [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding|`cek_semua_godot_cpp()` di Bab 7]].

### Setup godot-cpp

*(Lokasi Baris 1421 - 1427)*
```python
("body", "[ Setup godot-cpp ]"),
("body", "  Runs setup_godot_cpp.py interactively (clone/compile). If the"),
("body", "  godot-cpp-<version> folder already exists, asks whether to keep it or"),
("body", "  re-download. Before cloning, the branch is checked against GitHub -- if"),
("body", "  not found, you get a warning before continuing. Compile target follows"),
("body", "  the Build mode above."),
("blank", ""),
```

**Penjelasan:**
- Menu `[ Setup godot-cpp ]` menjalankan [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#11. Fungsi `main()` - Alur Eksekusi Utama|`setup_godot_cpp.py`]].
- **Clone** - jika folder belum ada, clone dari GitHub dengan branch yang dipilih.
- **Redownload** - jika folder sudah ada, tanya "Use existing atau Re-download?".
- **Cek branch** - sebelum clone, cek apakah branch ada di remote (atau validasi api_version untuk master).
- **Compile** - compile godot-cpp untuk Linux dan Windows (jika mingw terinstall).
- Mengikuti mode `debug`/`release` dan arsitektur `bits` yang dipilih di menu.

**Kaitan dengan Bab:** [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#11. Fungsi `main()` - Alur Eksekusi Utama|`setup_godot_cpp.py` dijelaskan di Bab 16]].

###  Clean Up Old godot-cpp

*(Lokasi Baris 1428 - 1432)*
```python
`("body", "[ Clean up old godot-cpp ]"),
("body", "  Deletes every godot-cpp-* folder EXCEPT the one currently active"),
("body", "  (asks you to type 'DELETE' to confirm). Handy for freeing up disk space"),
("body", "  after trying several versions/api_versions."),
("blank", ""),`
```

**Penjelasan:**

- Menu `[ Clean up old godot-cpp ]` (Bab 11) menghapus semua folder `godot-cpp-*` **kecuali** yang aktif.
- **Konfirmasi** - meminta pengguna mengetik `"DELETE"` untuk mencegah penghapusan tidak sengaja.
- Berguna untuk membersihkan ruang disk setelah mencoba banyak versi (folder godot-cpp bisa mencapai >500 MB per versi).

**Kaitan dengan Bab:** Implementasi di Bab 11 (`bersihkan_lama`).

### Delete godot-cpp

*(Lokasi Baris 1433 - 1437)*
```python
("body", "[ Delete godot-cpp ]"),
("body", "  COMPLETELY deletes the currently active godot-cpp-<version> folder"),
("body", "  (asks you to type 'DELETE' to confirm). Useful if the folder is corrupted"),
("body", "  or you just want to clean up."),
("blank", ""),
```

**Penjelasan:**
- Menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `hapus` - Delete Active godot-cpp|`[ Delete godot-cpp ]`]] menghapus **folder aktif**.
- **Konfirmasi** – meminta pengguna mengetik `"DELETE"`.
- Berguna jika folder corrupt (misal clone gagal, compile error misterius) dan ingin memulai ulang dari awal.

**Kaitan dengan Bab:** Implementasi di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `hapus` - Delete Active godot-cpp|Bab 11 (`hapus`)]] dan [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#10. Fungsi `hapus_godot_cpp()` - Menghapus Folder Binding|Bab 16 (`hapus_godot_cpp()`]]).

---

## 5. Konten Help - Bagian 3: ACTIONS

### Section Header

*(Lokasi Baris 1438)*
```python
("section", "ACTIONS"),
```

Bagian ini menjelaskan aksi-aksi yang dapat dieksekusi dari menu utama.

### Save Options + Generate!

*(Lokasi Baris 1439 - 1443)*
```python
("body", "[ Save options + Generate! ]"),
("body", "  Shows a confirmation screen summarizing the options before actually"),
("body", "  generating SConstruct + build_logic.py. The old build_options.json is"),
("body", "  automatically backed up to build_options.json.bak before being overwritten."),
("blank", ""),
```

**Penjelasan:**
- Menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `generate` - Save Options + Generate!|`[ Generate! ]`]] adalah **aksi utama** yang menghasilkan file build.
- **Konfirmasi** - menampilkan ringkasan opsi (mode, platform, bits, jobs, branch) sebelum mengeksekusi.
- **Backup** - `build_options.json` di-backup ke `build_options.json.bak` sebelum ditimpa.
- **Generate** - menulis `SConstruct` dan [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|`build_logic.py`]].

**Kaitan dengan Bab:** Implementasi di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `generate` - Save Options + Generate!|Bab 11 (`generate`)]] dan [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|Bab 12 (`generate_files()`]]).

### Quit

*(Lokasi Baris 1444 - 1446)*
```python
("body", "[ Quit ]"),
("body", "  Closes the menu without regenerating (already-saved options still apply)."),
("blank", ""),
```

**Penjelasan:**
- Menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `keluar` - Quit|`[ Quit ]`]] keluar dari menu curses.
- Opsi yang sudah disimpan di `build_options.json` tetap berlaku.
- Tidak menghasilkan file build baru – pengguna harus menjalankan `[ Generate! ]` terlebih dahulu jika ingin build.

**Kaitan dengan Bab:** Implementasi di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `keluar` - Quit|Bab 11 (`keluar`).]]

---

## 6. Konten Help - Bagian 4: OTHER

### Section Header

(Lokasi Baris 1447)
```python
("section", "OTHER"),
```

Bagian ini berisi informasi tambahan yang tidak termasuk dalam kategori sebelumnya.

### Last Build

(Lokasi Baris 1448 - 1450)
```python
("body", "Last build (below the menu) is read from logs/build_history.json."),
("body", "Folders auto-created during build: bin/, src/, build/, logs/"),
("body", "  bin/<platform>_<bits>_<mode>/ -> compile output, separated per platform & mode"),
```

**Penjelasan:**
- **Last build** - ditampilkan di bawah [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|menu utama]], diambil dari [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#3. Fungsi `_archive_old_md()` - Merotasi `build_report.md`|`logs/build_history.json`]].
- **Folder auto-created** - `bin/`, `src/`, `build/`, `logs/` dibuat secara otomatis oleh [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()`]].
- **Output structure** - `bin/{plat}_{bits}_{mode}/` – memisahkan hasil compile per platform, arsitektur, dan mode.

**Kaitan dengan Bab:** [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#10. Fungsi `get_last_build_info()` - Informasi Build Terakhir|`get_last_build_info()` di Bab 7]], [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()` di Bab 15]].

---

## 7. Tabel Rangkuman Konten Help

|Bagian|Item|Jumlah Baris|Topik|
|---|---|---|---|
|**BUILD OPTIONS**|Section header|1|Judul bagian|
||Build mode|3|Debug vs Release|
||Linux/Windows Platform|2|Toggle aktif/nonaktif|
||Architecture|4|64-bit vs 32-bit (v2.4.0)|
||Parallel jobs|2|Cycle auto/2/4/8|
|**GODOT-CPP**|Section header|1|Judul bagian|
||godot-cpp version|6|Toggle versi, status kompilasi|
||Target api_version|4|Master-only, presets, custom|
||Update version list|5|Pull dari GitHub|
||Check installed Godot|3|Deteksi PATH|
||View all versions|2|Scan folder|
||Setup godot-cpp|4|Clone & compile|
||Clean up old versions|3|Hapus selain aktif|
||Delete godot-cpp|3|Hapus aktif|
|**ACTIONS**|Section header|1|Judul bagian|
||Save + Generate!|3|Konfirmasi, backup, generate|
||Quit|2|Keluar tanpa generate|
|**OTHER**|Section header|1|Judul bagian|
||Last build & folders|3|Info tambahan|

---

## 8. Pemeliharaan Data Help

### Mengapa Help Perlu Dipelihara?
Help window adalah **dokumentasi pertama** yang dilihat pengguna baru. Jika konten help tidak sinkron dengan fungsionalitas aktual:
- Pengguna akan bingung dan frustrasi.
- Dukungan teknis akan menerima pertanyaan yang seharusnya dijawab oleh help.
- Sistem terlihat tidak profesional.

### Kapan Help Harus Diperbarui?

|Perubahan|Tindakan|
|---|---|
|Opsi baru ditambahkan|Tambahkan `body` di bagian yang sesuai|
|Opsi lama dihapus|Hapus `body` yang terkait|
|Perilaku opsi berubah|Update teks `body`|
|Menu baru ditambahkan|Tambahkan `body` di ACTIONS|
|Fitur baru (v2.4.0: `bits`, `license`)|Tambahkan `body` yang menjelaskan|

### Tips Menulis Help yang Baik
1. **Jelas dan ringkas** - gunakan bahasa sederhana, hindari jargon berlebihan.
2. **Terstruktur** - gunakan section untuk mengelompokkan topik terkait.
3. **Konsisten** - gunakan format yang sama untuk semua item.
4. **Aktual** - selalu perbarui saat fungsionalitas berubah.
5. **Bahasa Indonesia** - konsisten dengan komentar di kode, target pengguna utama.

---

## 9. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Opsi bits di Help
> ### Opsi `bits` di Help
> 
> Help window di v2.4.0 memiliki **4 baris** yang menjelaskan opsi `bits`:
> ```python
> ("body", "Architecture (64-bit / 32-bit)"),
> ("body", "  Toggle bit-width for both the project build and godot-cpp itself. 32-bit"),
> ("body", "  needs the matching mingw-w64 32-bit compiler installed for Windows builds"),
> ("body", "  (i686-w64-mingw32-g++), separate from the 64-bit one."),
> ```
> 
> Ini adalah tambahan baru yang menjelaskan:
> - Apa itu opsi `bits`.
> - Dampaknya pada proyek dan godot-cpp.
> - Kebutuhan compiler terpisah untuk 32-bit Windows.

> [!done]- Menu license dan export_license
> ### Menu `license` dan `export_license`
> 
> Meskipun menu `license` dan `export_license` **tidak** memiliki `body` di `HELP_ITEMS` (karena mereka cukup jelas dari namanya), help window tetap menampilkan section ACTIONS yang mencakup semua menu aksi.

> [!done]- STYLE dan Warna di Help
> ### `STYLE` dan Warna di Help
> 
> Help window menggunakan `STYLE["section"]` dan `STYLE["title"]` yang sudah diinisialisasi dengan warna di `main()` (Bab 11). Ini membuat help window terlihat lebih profesional dan mudah dibaca.

---

## 10. Kesimpulan

Pada bab ini, kita telah membahas **data statis `HELP_ITEMS`** - dokumentasi interaktif yang tersedia di dalam menu curses. Kita mempelajari:
1. **Struktur data `HELP_ITEMS`** - list of tuples `(kind, teks)` dengan tiga tipe: `section`, `body`, dan `blank`.
2. **Konten help secara detail** - empat bagian utama:
    - **BUILD OPTIONS** - mode, platform, arsitektur, jobs.
    - **GODOT-CPP** - versi, api_version, update, setup, cleanup.
    - **ACTIONS** - generate, credits, lisensi, keluar.
    - **OTHER** - last build dan folder otomatis.
3. **Bagaimana help dirender** - word wrapping, scroll, style, dan navigasi.
4. **Pemeliharaan data help** - pentingnya menjaga sinkronisasi dengan fungsionalitas aktual.
5. **Fitur v2.4.0** - opsi `bits` dijelaskan di help, menu `license` dan `export_license` muncul di ACTIONS.