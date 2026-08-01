# BAB 8 - `bootstrap_scons_gui.py`: MANAJEMEN OPSI (`build_options.json`)

## 1. Pendahuluan: Inti Konfigurasi Build

Setelah kita memahami fungsi-fungsi utility untuk mengelola versi godot-cpp, kini saatnya membahas **jantung konfigurasi** dari seluruh sistem build: file `build_options.json`. Di sinilah semua preferensi pengguna disimpan - mode build, platform aktif, jumlah pekerja paralel, versi godot-cpp, target API, dan **arsitektur (bits)** yang baru diperkenalkan di v2.4.0.

Pada Bab 8, kita akan membahas:
1. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default|Fungsi `load_options()` - memuat dan menggabungkan nilai default dengan JSON yang tersimpan.]]
2. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#3. Fungsi `save_options(opts)` - Menyimpan Opsi ke JSON + Backup|Fungsi `save_options(opts)` - menyimpan opsi ke file, lengkap dengan mekanisme backup otomatis.]]
3. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#Mekanisme Backup Otomatis|Struktur `build_options.json` secara mendalam.]]
4. [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#5. Interaksi dengan Utility Functions|Peran opsi `bits` dan dampaknya terhadap kompilasi (baik untuk proyek maupun godot-cpp).]]

Semua kode yang dibahas dalam bab ini berada di dalam **heredoc `PYEOF_INNER`**, setelah fungsi-fungsi utility dan sebelum konstanta CREDITS & MENU. Fungsi-fungsi ini dipanggil langsung dari `main()` dan juga digunakan oleh `setup_godot_cpp.py` untuk membaca mode dan arsitektur.

>[!quote] **Referensi Silang:**
> - `load_options()` dipanggil di awal `main()` untuk menginisialisasi opsi.
> - `save_options()` dipanggil setiap kali pengguna mengubah opsi (lewat navigasi keyboard) dan saat generate.
> - `build_options.json` juga dibaca oleh `build_logic.py` dan `setup_godot_cpp.py`.     

---

## 2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default

^cd24e4

*(Lokasi Baris 677 - 698)*
```python
def load_options():
    import json as _json
    opts = {"mode": "release", "platforms": {"linux": True, "windows": True}, "jobs": 0, 
            "godot_cpp_branch": "4.2", "godot_cpp_api_version": "4.7", "bits": "64"}
    if os.path.exists("build_options.json"):
        try:
            with open("build_options.json", "r") as f:
                saved = _json.load(f)
            if "mode" in saved:
                opts["mode"] = saved["mode"]
            if "platforms" in saved:
                for p in opts["platforms"]:
                    opts["platforms"][p] = p in saved["platforms"]
            if "jobs" in saved:
                opts["jobs"] = saved["jobs"]
            if "godot_cpp_branch" in saved:
                opts["godot_cpp_branch"] = saved["godot_cpp_branch"]
            if "godot_cpp_api_version" in saved:
                opts["godot_cpp_api_version"] = saved["godot_cpp_api_version"]
            if "bits" in saved:
                opts["bits"] = saved["bits"]
        except: pass
    return opts
```

### Struktur Dictionary `opts`
Fungsi ini mengembalikan sebuah dictionary Python dengan 7 kunci:

|Kunci|Tipe|Nilai Default|Deskripsi|
|---|---|---|---|
|`mode`|`str`|`"release"`|Mode build: `"debug"` atau `"release"`|
|`platforms`|`dict`|`{"linux": True, "windows": True}`|Platform aktif (boolean)|
|`jobs`|`int`|`0`|Jumlah pekerja paralel (`0` = auto semua core)|
|`godot_cpp_branch`|`str`|`"4.2"`|Branch godot-cpp yang dipilih|
|`godot_cpp_api_version`|`str`|`"4.7"`|Target `api_version` (hanya untuk branch `master`)|
|`bits`|`str`|`"64"`|Arsitektur: `"64"` atau `"32"`|

### Logika Penggabungan (Merge)
1. **Inisialisasi dengan default** - dictionary `opts` diisi dengan nilai default yang telah ditentukan.
2. **Cek keberadaan file** - jika `build_options.json` tidak ada, fungsi langsung mengembalikan `opts` default.
3. **Baca JSON** - jika file ada, baca isinya ke `saved`.
4. **Perbarui nilai** - untuk setiap kunci yang ada di `saved`, perbarui nilai di `opts`. Khusus untuk `platforms`, karena format di JSON berupa **array** (daftar platform aktif), kita konversi kembali ke dictionary boolean.

### Format `platforms` di JSON vs di Memory
- **Di Memory (opts)**: `{"linux": True, "windows": True}` - dictionary boolean.
- **Di JSON (saved)**: `{"platforms": ["linux", "windows"]}` - array string.

Fungsi `load_options()` melakukan konversi dari array ke boolean: jika platform ada di array, bernilai `True`; jika tidak, `False`.

### Penanganan Error
Jika terjadi error saat membaca JSON (misal file corrupt), `except: pass` akan mengabaikan error dan melanjutkan dengan nilai default. Ini mencegah menu crash hanya karena file konfigurasi rusak.

---

## 3. Fungsi `save_options(opts)` - Menyimpan Opsi ke JSON + Backup

*(Lokasi Baris 701 - 720)*
```python
def save_options(opts):
    import json as _json
    data = {
        "mode": opts["mode"],
        "platforms": [p for p, on in opts["platforms"].items() if on],
        "jobs": opts["jobs"],
        "godot_cpp_branch": opts["godot_cpp_branch"],
        "godot_cpp_api_version": opts["godot_cpp_api_version"],
        "bits": opts["bits"],
    }
    if os.path.exists("build_options.json"):
        try:
            shutil.copy2("build_options.json", "build_options.json.bak")
        except Exception:
            pass
    with open("build_options.json", "w") as f:
        _json.dump(data, f, indent=4)
    return data
```

### Konversi ke Format JSON
Fungsi ini mengambil dictionary `opts` dan mengonversinya menjadi dictionary `data` yang siap disimpan ke JSON:
- `platforms` diubah dari dict boolean menjadi **array string** (hanya platform yang `True` yang dimasukkan).
- Kunci lainnya dipertahankan dengan nama yang sama.

### Mekanisme Backup Otomatis

^237532

Sebelum menimpa `build_options.json`, fungsi melakukan **backup** ke `build_options.json.bak` menggunakan `shutil.copy2`. Backup ini penting karena: ^2e67e6
- Jika pengguna salah mengubah opsi dan tidak ingat nilai sebelumnya, mereka bisa membandingkan atau memulihkan dari `.bak`.
- Jika terjadi error saat menulis file (misal disk full), file asli masih aman di backup.    

>[!warning] **Catatan:** 
>Backup **hanya** dibuat jika file `build_options.json` sudah ada. Jika file belum ada (pertama kali jalankan menu), tidak ada backup yang dibuat (karena tidak ada yang perlu dibackup).

### Format JSON yang Dihasilkan
Contoh isi `build_options.json` setelah disimpan:

```json
{
    "mode": "release",
    "platforms": ["linux", "windows"],
    "jobs": 0,
    "godot_cpp_branch": "4.2",
    "godot_cpp_api_version": "4.7",
    "bits": "64"
}
```

### Kapan `save_options()` Dipanggil?
- **Setiap kali pengguna mengubah opsi** melalui navigasi keyboard (LEFT/RIGHT atau ENTER/SPACE) di menu utama.
- **Saat menu `[ Save options + Generate! ]`** dipilih - setelah konfirmasi, opsi disimpan lalu file-file build di-generate.
- **Saat menu `[ Setup godot-cpp ]`** dipanggil - opsi disimpan terlebih dahulu agar `setup_godot_cpp.py` membaca mode dan arsitektur yang terbaru.

---

## 4. Opsi `bits` - Arsitektur 64/32-bit (Fitur Baru v2.4.0)

>[!hint]- **NEW UPDATE**
> - Update V2.4.0 - Add Options bits

Opsi `bits` adalah tambahan penting di versi 2.4.0 yang memungkinkan pengguna memilih antara build **64-bit** (default) atau **32-bit**. Opsi ini memengaruhi hampir seluruh alur build:

### Dampak pada Nama Folder Output
- Folder output di `bin/` akan menyertakan bit-width:  
    `bin/linux_64_release/`, `bin/windows_32_debug/`, dst.
- Ini memastikan bahwa hasil compile untuk arsitektur berbeda tidak saling menimpa.

### Dampak pada Argumen SCons
- Di `build_logic.py` , opsi `bits` dikonversi menjadi `arch`:
    - `"64"` atau `"x86_64"`
    - `"32"` atau `"x86_32"`
- Argumen `arch` diteruskan ke compiler dan linker, menentukan flag `-m64` atau `-m32` untuk Linux, dan memilih compiler mingw yang sesuai untuk Windows.

### Dampak pada `setup_godot_cpp.py`
- Fungsi `baca_bits_dari_build_options()` membaca nilai `bits` dari JSON.
- Compiler Mingw yang digunakan untuk Windows disesuaikan:
    - `"64"` menjadi `x86_64-w64-mingw32-g++`
    - `"32"` menjadi `i686-w64-mingw32-g++`
- SCons `arch` juga disesuaikan saat mengompilasi godot-cpp.

### Dampak pada Menu Curses
- Di menu utama, opsi `bits` muncul sebagai baris `Architecture : 64-bit` atau `32-bit`.
- Navigasi LEFT/RIGHT atau ENTER/SPACE akan mengganti nilai antara `"64"` dan `"32"`.

### Validasi Dependensi (di `setup_godot_cpp.py`)
- Saat mengompilasi godot-cpp untuk Windows, sistem memeriksa apakah compiler mingw yang sesuai dengan arsitektur terinstall. Jika tidak, kompilasi Windows dilewati dan diberikan saran instalasi paket yang tepat:
    - 64-bit: `sudo apt install mingw-w64`
    - 32-bit: `sudo apt install mingw-w64-i686-dev g++-mingw-w64-i686`

---

## 5. Interaksi dengan Utility Functions

Fungsi-fungsi utility ini menggunakan opsi-opsi dari `build_options.json` (baik langsung melalui `load_options()` atau melalui pembacaan ulang di `setup_godot_cpp.py`):
- **`get_godot_cpp_status()`** - menerima `branch` dan `api_version` sebagai argumen. Nilai `branch` dan `api_version` berasal dari `opts` yang sudah dimuat.
- **`get_last_build_info()`** - tidak bergantung pada opsi, hanya membaca log.
- **`cek_semua_godot_cpp()`** - tidak bergantung pada opsi, memindai semua folder.

>[!bug] **Catatan:**
>Seperti disebutkan di, [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#^02277e|`get_godot_cpp_status()`]] **tidak** membaca `bits` saat menentukan status kompilasi. Ini adalah keterbatasan yang perlu diperbaiki di versi mendatang.

---

## 6. Contoh Alur Penggunaan Opsi

Berikut adalah skenario tipikal pengguna yang mengubah opsi dan menyimpannya:
1. **Menu dimulai** lalu `load_options()` dipanggil lalu opsi default dimuat.
2. **Pengguna menekan Navigasi RIGHT** pada `mode` lalu `mode` berubah dari `"release"` ke `"debug"` lalu `save_options()` dipanggil, `build_options.json` diperbarui.
3. **Pengguna menekan ENTER pada `bits`** lalu `bits` berubah dari `"64"` ke `"32"` lalu `save_options()` dipanggil lagi.
4. **Pengguna memilih `[ Setup godot-cpp ]`** lalu `save_options()` dipanggil sekali lagi (untuk memastikan opsi terbaru tersimpan) lalu `setup_godot_cpp.py` dijalankan dengan membaca langsung dari `build_options.json`.
5. **Pengguna memilih `[ Save options + Generate! ]`** lalu `save_options()` dipanggil ke `generate_files()` menulis `SConstruct` dan `build_logic.py` yang **akan membaca** `build_options.json` saat dieksekusi oleh SCons.

---

## 7. Keamanan dan Robustness

- **Exception Handling** - Semua operasi I/O dibungkus dengan `try/except` untuk mencegah crash jika file corrupt atau permission error.
- **Backup** - Setiap kali menimpa, dibuat backup `.bak` sehingga pengguna tidak kehilangan konfigurasi.
- **Default yang Aman** - Default `"release"`, `"64"`, dan `"4.2"` adalah pilihan paling umum dan stabil.

---

## 8. Tabel Perbandingan: Opsi Default vs Opsi yang Disimpan

|Opsi|Default di `load_options()`|Di `build_options.json` (contoh)|
|---|---|---|
|`mode`|`"release"`|`"debug"`|
|`platforms`|`{"linux": True, "windows": True}`|`["linux", "windows"]`|
|`jobs`|`0`|`4`|
|`godot_cpp_branch`|`"4.2"`|`"master"`|
|`godot_cpp_api_version`|`"4.7"`|`"4.7"`|
|`bits`|`"64"`|`"32"`|

---

## 9. Keterkaitan dengan Fitur Lain v2.4.0

- **`bits`** - Fitur utama yang ditambahkan di v2.4.0, membuat sistem mendukung baik 64-bit maupun 32-bit.
- **`LICENSE_TEXT` dan menu lisensi** - Tidak memengaruhi `build_options.json`.
- **`STYLE` dan event mouse** - Tidak memengaruhi manajemen opsi.
- **`show_scrollable_dialog`** - Tidak memengaruhi opsi.

---

## 10. Kesimpulan

Fungsi `load_options()` dan `save_options()` adalah **jembatan** antara antarmuka pengguna (menu curses) dan sistem build (SCons, godot-cpp). Dengan adanya backup otomatis dan nilai default yang bijak, pengguna dapat bereksperimen dengan konfigurasi tanpa risiko kehilangan pengaturan sebelumnya.