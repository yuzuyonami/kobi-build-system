# BAB 13 - ISI "build_logic.py" (PROLOG, KELAS, KONFIGURASI)

---

## 1. Pendahuluan: Jantung Sistem Build

Setelah kita memahami bagaimana [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#4 .Konstanta `LOGIC_CONTENT` - Isi File `build_logic.py`|`generate_files()` menulis `build_logic.py` ke folder proyek]], kini saatnya membahas **isi sebenarnya** dari file tersebut. `build_logic.py` adalah **jantung dari sistem build** – di sinilah semua logika kompilasi, logging, dan pelaporan error terjadi. File ini dijalankan oleh SCons melalui `SConstruct` stub, dan merupakan kode Python murni yang memanfaatkan API SCons untuk melakukan kompilasi silang (cross-compilation) untuk Linux dan Windows.

Pada Bab 13, kita akan membahas **bagian pertama** dari `LOGIC_CONTENT`, yang mencakup:
1. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#2. Import Library dan Variabel Global|Prolog - import library dan variabel global.]]
2. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#3. Kelas `Terminal` - Wrapper untuk stdout + Logging|Kelas `Terminal` - wrapper untuk `stdout` yang juga menulis ke file log.]]
3. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#4. Kelas `ColorMagic` - Pewarnaan Terminal Dinamis|Kelas `ColorMagic` - pewarnaan terminal dengan akses dinamis.]]
4. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#5. Konfigurasi Awal - Path dan Konstanta Build|Konfigurasi awal - path log, konstanta build, dan pembacaan `build_options.json`.]]
5. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#6. Pembacaan `build_options.json` dan Penentuan Path godot-cpp|Penentuan path godot-cpp - berdasarkan branch dan api_version.]]
6. [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#7. Dampak Opsi `bits` pada Konfigurasi|Penentuan daftar target - platform dan arsitektur yang akan dibangun.]]

Semua kode dalam bab ini adalah bagian dari konstanta `LOGIC_CONTENT` yang didefinisikan di **Baris 75 - 154** dari `bootstrap_scons_gui.py`.

> [!quote] **Referensi Silang:**
> - `build_logic.py` membaca `build_options.json` yang disimpan oleh [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#3. Fungsi `save_options(opts)` - Menyimpan Opsi ke JSON + Backup|`save_options()`]].
> - `build_logic.py` menggunakan fungsi-fungsi utility dari Bab 7 (meskipun diimplementasikan ulang di sini).
> - `build_logic.py` akan dipanggil oleh SCons setelah pengguna menjalankan perintah `scons`.

---

## 2. Import Library dan Variabel Global

*(Lokasi Baris 163 - 173)*
```python
import time
import datetime
import os
import subprocess
import json
import sys
import glob
import atexit
from SCons.Script import GetBuildFailures
Start = time.time()
```

### Import Standar Python

|Library|Fungsi dalam `build_logic.py`|
|---|---|
|`time`|Mengukur durasi build (`Start`, `time.time()`)|
|`datetime`|Membuat timestamp untuk log (`%Y-%m-%d %H:%M:%S`)|
|`os`|Operasi file dan path (`os.makedirs`, `os.path.join`, `os.walk`)|
|`subprocess`|Menjalankan proses eksternal (tidak digunakan langsung di sini, tapi di-import untuk kemungkinan perluasan)|
|`json`|Membaca/menulis `build_history.json` dan `build_options.json`|
|`sys`|Mengganti `stdout`/`stderr` dengan `Terminal` wrapper|
|`glob`|Mencari file sumber (`src/**/*.cpp`) dan file hasil compile|
|`atexit`|Mendaftarkan `report_build_failures()` agar dipanggil saat SCons selesai|

### Import Khusus SCons

*(Lokasi Baris 171)*
```python
from SCons.Script import GetBuildFailures
```

`GetBuildFailures()` adalah fungsi bawaan SCons yang mengembalikan daftar error yang terjadi selama proses build. Ini adalah **satu-satunya cara yang benar** untuk menangkap error compile, karena:
- `try/except` di sekitar `env.SharedLibrary()` hanya menangkap error **konfigurasi** (misal argumen salah).
- Error **compile** (misal syntax error di C++) terjadi **setelah** `SConstruct` selesai diparse, di luar jangkauan `try/except` manapun.
- `GetBuildFailures()` dipanggil dari `atexit` setelah seluruh proses build selesai, sehingga dapat menangkap semua kegagalan.

### Variabel `Start`

*(Lokasi Baris 173)*
```python
Start = time.time()
```

Mencatat waktu **saat `build_logic.py` mulai dieksekusi**. Ini digunakan untuk menghitung durasi build total, yang kemudian dicatat di log.

---

## 3. Kelas `Terminal` - Wrapper untuk stdout + Logging

*(Lokasi Baris 176 - 196)*
```python
class Terminal(object):
    def __init__(self):
        self.terminal = sys.stdout
        os.makedirs("logs", exist_ok=True)
        self.log = open("logs/terminal_cctv.log", "a", encoding="utf-8")
    def write(self, message):
        self.terminal.write(message)
        self.log.write(message)
        
    def log_only(self, message):
        timestamp = datetime.datetime.now().strftime("[%H:%M:%S] ")
        self.log.write(f"{timestamp}{message}\n")
    def flush(self):
        if hasattr(self.terminal, "flush"):
            self.terminal.flush()
        self.log.flush()
sys.stdout = Terminal()
sys.stderr = sys.stdout
```

### Tujuan
Kelas `Terminal` adalah **wrapper** untuk `sys.stdout` yang:
1. **Meneruskan** semua output ke terminal asli (`self.terminal`).
2. **Menulis salinan** ke file log `logs/terminal_cctv.log`.
3. Menyediakan metode `log_only()` untuk menulis **hanya ke log** (tidak ke terminal).
4. Memastikan `flush()` dipanggil pada kedua stream.

Ini adalah pola yang sangat berguna untuk **forensic debugging** – semua output yang muncul di terminal juga terekam di file, sehingga jika ada error yang cepat hilang dari layar, pengembang masih bisa melihatnya di log.

### Inisialisasi (`__init__`)

*(Lokasi Baris 178 - 180)*
```python
self.terminal = sys.stdout
os.makedirs("logs", exist_ok=True)
self.log = open("logs/terminal_cctv.log", "a", encoding="utf-8")
```

- **`self.terminal`** - menyimpan referensi ke `stdout` asli sebelum di-override.
- **`os.makedirs("logs", exist_ok=True)`** - membuat folder `logs/` jika belum ada.
- **`self.log`** - membuka file log dalam mode **append** (`"a"`) dengan encoding UTF-8.

### Metode `write()`

*(Lokasi Baris 182 - 184)*
```python
def write(self, message):
    self.terminal.write(message)
    self.log.write(message)
```

Setiap kali ada yang menulis ke `sys.stdout` (misal `print()`), metode ini:
1. Menulis ke terminal asli.
2. Menulis ke file log.

### Metode `log_only()`

*(Lokasi Baris 186 - 188)*
```python
def log_only(self, message):
    timestamp = datetime.datetime.now().strftime("[%H:%M:%S] ")
    self.log.write(f"{timestamp}{message}\n")
```

Metode ini digunakan untuk menulis pesan **hanya ke log**, dengan timestamp. Ini berguna untuk:
- Mencatat peristiwa internal yang tidak perlu ditampilkan ke terminal.
- Memberi timestamp pada entri log untuk memudahkan tracing.

### Metode `flush()`

*(Lokasi Baris 190 - 193)*
```python
def flush(self):
    if hasattr(self.terminal, "flush"):
        self.terminal.flush()
    self.log.flush()
```

Memastikan kedua stream di-_flush_, mencegah data tertahan di buffer.

### Pengalihan `sys.stdout` dan `sys.stderr`

*(Lokasi Baris 195 - 196)*
```python
sys.stdout = Terminal()
sys.stderr = sys.stdout
```

- `sys.stdout` diganti dengan instance `Terminal`.
- `sys.stderr` diarahkan ke `sys.stdout` yang sama, sehingga semua error juga masuk ke log.

> [!note] **Catatan:**
> Karena `sys.stderr` diarahkan ke `sys.stdout`, semua output (termasuk error) akan masuk ke `terminal_cctv.log`. Ini memudahkan debugging karena semua informasi ada di satu file.

---

## 4. Kelas `ColorMagic` - Pewarnaan Terminal Dinamis

*(Lokasi Baris 198 - 222)*
```python
class ColorMagic:
    def __init__(self):
        self.codes = {
            'Y': "\033[93m",  # Yellow
            'G': "\033[92m",  # Green
            'R': "\033[91m",  # Red
            'N': "\033[0m",   # Reset
            'B': "\033[94m",  # Blue
            'C': "\033[96m",  # Cyan
            'W': "\033[1m",   # Bold
            'I': "\033[3m",   # Italic
            'U': "\033[4m",   # Underline
            'S': "\033[9m",   # Strikethrough
        }
    def __getattr__(self, name):
        return "".join([self.codes.get(char, "") for char in name])
C = ColorMagic()
```

### Tujuan
`ColorMagic` adalah kelas yang memungkinkan pewarnaan terminal dengan **sintaks yang sangat ringkas**. Pengguna dapat menulis:

*(Contoh pemakaiannya)*
```python
print(f"{C.RIW}Ini teks merah, italic, bold{C.N}")
```

Di mana:
- `C.RIW` untuk Red + Italic + Bold (kode ANSI untuk merah, italic, dan bold).
- `C.N` untuk Reset (kembali ke warna normal).

### Kamus `codes`
Kamus ini memetakan **huruf tunggal** ke **kode ANSI escape**:

|Huruf|Kode ANSI|Efek|
|---|---|---|
|`Y`|`\033[93m`|Yellow (kuning)|
|`G`|`\033[92m`|Green (hijau)|
|`R`|`\033[91m`|Red (merah)|
|`N`|`\033[0m`|Reset (kembali ke default)|
|`B`|`\033[94m`|Blue (biru)|
|`C`|`\033[96m`|Cyan|
|`W`|`\033[1m`|Bold (tebal)|
|`I`|`\033[3m`|Italic (miring)|
|`U`|`\033[4m`|Underline (garis bawah)|
|`S`|`\033[9m`|Strikethrough (coret)|

### Metode `__getattr__()`

*(Lokasi Baris 216 - 219)*
```python
def __getattr__(self, name):
    return "".join([self.codes.get(char, "") for char in name])
```

Metode ini adalah **magic method** yang dipanggil ketika atribut yang tidak ada diakses. Contoh:

```python
C.RIW
```

1. Python mencari atribut `RIW` di `ColorMagic`.
2. Tidak ditemukan, maka panggil `__getattr__(self, "RIW")`.
3. Iterasi setiap karakter di `"RIW"`:
    - `'R'` untuk `self.codes.get('R')` maka jadi `"\033[91m"`
    - `'I'` untuk `self.codes.get('I')` maka jadi `"\033[3m"`
    - `'W'` untuk `self.codes.get('W')` maka jadi `"\033[1m"`
4. Gabungkan maka akan menjadi `"\033[91m\033[3m\033[1m"`.
5. Kembalikan string gabungan.

### Objek `C`

*(Lokasi Baris 222)*
```python
C = ColorMagic()
```

Objek global `C` memungkinkan pewarnaan di seluruh `build_logic.py` tanpa harus membuat instance baru.

### Contoh Penggunaan

*(Lokasi Baris 236 - 263)*
```python
print(f"{C.RIW}>>> Build FAILED -- {errstr}{C.N}")
print(f"{C.GIW}>>> Build SUCCESS in {durasi}{C.N}")
print(f"{C.CIW}--- Registering {plat} {bits}-bit ---{C.N}")
```

### Mengapa Tidak Menggunakan Library `colorama`?
Meskipun `colorama` adalah library standar untuk pewarnaan terminal, penggunaannya memerlukan **instalasi tambahan** (`pip install colorama`). Karena `build_logic.py` harus **self-contained** dan berjalan di sistem mana pun tanpa dependensi eksternal, `ColorMagic` adalah solusi yang lebih ringan dan portabel.

---

## 5. Konfigurasi Awal - Path dan Konstanta Build

*(Lokasi Baris 226 - 233)*
```python
LOG_FILE = "logs/build_report.md"
JSON_LOG = "logs/build_history.json"
ERROR_LOG_FILE = "logs/build_errors.log"
JSON_ARCHIVE = "logs/build_history_archive.json"
MAX_HISTORY = 50
BASE_TARGET_NAME = "bin/compile"
SOURCE_FILES = [File(f) for f in glob.glob("src/**/*.cpp", recursive=True)]
GEXT_FILE = "bin/compile.gdextension"
```

### Path Log

|Variabel|Path|Fungsi|
|---|---|---|
|`LOG_FILE`|`logs/build_report.md`|File Markdown dengan ringkasan build (manusia-readable)|
|`JSON_LOG`|`logs/build_history.json`|File JSON dengan riwayat build (machine-readable)|
|`ERROR_LOG_FILE`|`logs/build_errors.log`|File teks dengan detail error (hanya untuk build gagal)|
|`JSON_ARCHIVE`|`logs/build_history_archive.json`|Arsip entri JSON lama (saat `MAX_HISTORY` terlampaui)|

### `MAX_HISTORY`

*(Lokasi Baris 230)*
```python
MAX_HISTORY = 50
```

Jumlah **entri terakhir** yang disimpan di `build_report.md` dan `build_history.json`. Entri yang lebih lama akan di-_archive_ ke:
- `build_history_archive.json` (untuk JSON).
- File Markdown terpisah dengan timestamp (untuk `build_report.md`).

Ini mencegah file log membengkak tanpa batas.

### `BASE_TARGET_NAME`

*(Lokasi Baris 231)*
```python
BASE_TARGET_NAME = "bin/compile"
```

Nama dasar untuk file output. Nama lengkapnya akan menjadi:
- Linux: `bin/compile.linux.64.so` atau `bin/compile.linux.32.so`
- Windows: `bin/compile.windows.64.dll` atau `bin/compile.windows.32.dll`

### `SOURCE_FILES`

*(Lokasi Baris 232)*
```python
SOURCE_FILES = [File(f) for f in glob.glob("src/**/*.cpp", recursive=True)]
```

Mencari **semua file `.cpp`** di folder `src/` dan subfoldernya secara rekursif. Hasilnya adalah list objek `File` (tipe SCons) yang akan digunakan sebagai sumber build.
- **`glob.glob("src/**/*.cpp", recursive=True)`** - mencari semua file `.cpp` di `src/` dan subfolder.
- **`File(f)`** - mengonversi path string menjadi objek `File` SCons, yang diperlukan untuk operasi build.

### `GEXT_FILE`

*(Lokasi Baris 233)*
```python
GEXT_FILE = "bin/compile.gdextension"
```

File `.gdextension` yang akan digenerate secara otomatis setelah build selesai. File ini memberi tahu Godot tentang:
- Simbol entry point (`entry_symbol`).
- Versi kompatibilitas minimum (`compatibility_minimum`).
- Path ke library untuk setiap platform.

---

## 6. Pembacaan `build_options.json` dan Penentuan Path godot-cpp

*(Lokasi Baris 236 - 263)*
```python
OPTIONS_FILE = "build_options.json"
build_options = {"mode": "release", "platforms": ["linux", "windows"], "jobs": 0, "godot_cpp_branch": "4.2", "godot_cpp_api_version": "4.7", "bits": "64"}
if os.path.exists(OPTIONS_FILE):
    try:
        with open(OPTIONS_FILE, "r") as f:
            build_options.update(json.load(f))
    except: pass
GODOT_CPP_BRANCH = build_options.get("godot_cpp_branch", "4.2")
GODOT_CPP_API_VERSION = build_options.get("godot_cpp_api_version", "4.7")
if GODOT_CPP_BRANCH == "master":
    godot_cpp_path = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
    godot_cpp_path = f"godot-cpp-{GODOT_CPP_BRANCH}"
if not os.path.isdir(godot_cpp_path):
    print(f"{C.RIW}>>> WARNING: folder '{godot_cpp_path}' doesn't exist / hasn't been set up yet!{C.N}")
    print(f"{C.RIW}>>> Run [ Setup godot-cpp ] in the menu first for version {GODOT_CPP_BRANCH}.{C.N}")
BUILD_MODE = build_options.get("mode", "release")
if build_options.get("jobs", 0) and build_options["jobs"] > 0:
    SetOption("num_jobs", build_options["jobs"])
targets = [(p, build_options.get("bits", "64")) for p in build_options.get("platforms", ["linux", "windows"])]
```

###  Membaca `build_options.json`

*(Lokasi Baris 236 - 242)*
```python
OPTIONS_FILE = "build_options.json"
build_options = {"mode": "release", "platforms": ["linux", "windows"], "jobs": 0, "godot_cpp_branch": "4.2", "godot_cpp_api_version": "4.7", "bits": "64"}
if os.path.exists(OPTIONS_FILE):
    try:
        with open(OPTIONS_FILE, "r") as f:
            build_options.update(json.load(f))
    except: pass
```

- **Nilai default** - jika `build_options.json` tidak ada, gunakan default yang aman.
- **`build_options.update()`** - menggabungkan nilai dari JSON ke dictionary default. Ini memastikan bahwa jika ada kunci baru di JSON, mereka ditambahkan; jika ada kunci yang hilang, default tetap dipakai.

### Penentuan `godot_cpp_path`

*(Lokasi Baris 246 - 254)*
```python
GODOT_CPP_BRANCH = build_options.get("godot_cpp_branch", "4.2")
GODOT_CPP_API_VERSION = build_options.get("godot_cpp_api_version", "4.7")
if GODOT_CPP_BRANCH == "master":
    godot_cpp_path = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
    godot_cpp_path = f"godot-cpp-{GODOT_CPP_BRANCH}"
```

Logika ini **harus identik** dengan yang ada di [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#15. Alur Lengkap `setup_godot_cpp.py`|`setup_godot_cpp.py`]] dan [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#9. Fungsi `get_godot_cpp_status()` - Status Binding Aktif|`get_godot_cpp_status()`]], untuk memastikan semua komponen merujuk ke folder yang sama.
- **Jika branch `"master"`** maka, folder `godot-cpp-master-api{api_version}`.
- **Jika branch bukan `"master"`** maka, folder `godot-cpp-{branch}`.

### Peringatan Jika Folder Tidak Ada

*(Lokasi Baris 255 - 257)*
```python
if not os.path.isdir(godot_cpp_path):
    print(f"{C.RIW}>>> WARNING: folder '{godot_cpp_path}' doesn't exist / hasn't been set up yet!{C.N}")
    print(f"{C.RIW}>>> Run [ Setup godot-cpp ] in the menu first for version {GODOT_CPP_BRANCH}.{C.N}")
```

Jika folder godot-cpp belum ada (belum di-_clone_ atau di-_setup_), tampilkan peringatan merah yang jelas.

### `BUILD_MODE`

*(Lokasi Baris 259)*
```python
BUILD_MODE = build_options.get("mode", "release")
```

- `"debug"` = tambahkan flag `-g -O0` dan definisi `DEBUG_ENABLED`.
- `"release"` = tambahkan flag `-O3` dan definisi `NDEBUG`.

### `jobs` – Jumlah Pekerja Paralel

*(Lokasi Baris 260 - 261)*
```python
if build_options.get("jobs", 0) and build_options["jobs"] > 0:
    SetOption("num_jobs", build_options["jobs"])
```

`SetOption("num_jobs", ...)` adalah fungsi SCons untuk mengatur jumlah proses paralel. Jika `jobs == 0`, SCons akan menggunakan jumlah core otomatis.

### `targets` – Daftar Target Build

*(Lokasi Baris 263)*
```python
targets = [(p, build_options.get("bits", "64")) for p in build_options.get("platforms", ["linux", "windows"])]
```

Membuat list of tuples `(platform, bits)` untuk setiap platform aktif. Contoh:

- Jika `platforms = ["linux", "windows"]` dan `bits = "64"` → `[("linux", "64"), ("windows", "64")]`
- Jika `platforms = ["linux"]` dan `bits = "32"` → `[("linux", "32")]`

---

## 7. Dampak Opsi `bits` pada Konfigurasi

Fitur baru **`bits`** di v2.4.0 memengaruhi beberapa aspek konfigurasi di `build_logic.py`:

### Nama Folder Output

Di [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()`]], folder output akan menyertakan `bits`:

*(Lokasi Baris 460)*
```python
bin_subdir = f"bin/{plat}_{bits}_{BUILD_MODE}"
```

Contoh:

- `bits = "64"` > `bin/linux_64_release/`
- `bits = "32"` > `bin/windows_32_debug/`

### Argumen `arch` untuk SCons

*(Lokasi Baris 431)*
```python
arch = "x86_64" if bits == "64" else "x86_32"
```

Nilai `arch` diteruskan ke compiler dan linker untuk menentukan arsitektur target.

### Compiler Mingw untuk Windows

*(Lokasi Baris 436)*
```python
env["CXX"] = "x86_64-w64-mingw32-g++" if bits == "64" else "i686-w64-mingw32-g++"
```

Compiler yang digunakan untuk Windows berbeda tergantung arsitektur.

### Flag Compiler untuk Linux

*(Lokasi Baris 440 - 441)*
```python
env.Append(CCFLAGS=["-m64" if bits == "64" else "-m32"])
env.Append(LINKFLAGS=["-m64" if bits == "64" else "-m32"])
```

Flag `-m64` atau `-m32` menentukan arsitektur output untuk Linux.

### Nama Library godot-cpp

*(Lokasi Baris 444)*
```python
lib_name = f"godot-cpp.{plat}.{scons_target}.{arch}"
```

Nama library godot-cpp yang akan di-_link_ juga menyertakan `arch`:
- `godot-cpp.linux.template_release.x86_64`
- `godot-cpp.windows.template_debug.x86_32`

---

## 8. Tabel Rangkuman Konfigurasi Awal `build_logic.py`

|Konstanta/Variabel|Nilai (Default)|Deskripsi|
|---|---|---|
|`LOG_FILE`|`"logs/build_report.md"`|File log Markdown|
|`JSON_LOG`|`"logs/build_history.json"`|File log JSON|
|`ERROR_LOG_FILE`|`"logs/build_errors.log"`|File error detail|
|`JSON_ARCHIVE`|`"logs/build_history_archive.json"`|Arsip JSON lama|
|`MAX_HISTORY`|`50`|Entri maksimum di log utama|
|`BASE_TARGET_NAME`|`"bin/compile"`|Nama dasar output|
|`SOURCE_FILES`|`glob.glob("src/**/*.cpp")`|Semua file sumber C++|
|`GEXT_FILE`|`"bin/compile.gdextension"`|File konfigurasi GDExtension|
|`build_options`|Dari `build_options.json`|Opsi build (mode, platform, jobs, branch, api_version, bits)|
|`godot_cpp_path`|`godot-cpp-{branch}` atau `godot-cpp-master-api{api_version}`|Path ke folder godot-cpp|
|`BUILD_MODE`|`"release"` atau `"debug"`|Mode kompilasi|
|`targets`|`[(plat, bits), ...]`|Daftar target (platform + arsitektur)|

---

## 9. Keterkaitan dengan Bab Sebelumnya

###  Keterkaitan dengan Bab 8 (Manajemen Opsi)
- `build_options.json` yang disimpan oleh `save_options()` di Bab 8 **dibaca** oleh `build_logic.py` di sini.
- Opsi `bits`, `mode`, `jobs`, `platforms`, `godot_cpp_branch`, dan `godot_cpp_api_version` semuanya berasal dari file yang sama.

### Keterkaitan dengan Bab 7 (Utility Functions)
- Logika penentuan `godot_cpp_path` di sini **identik** dengan `get_godot_cpp_status()` di Bab 7.
- Ini memastikan bahwa menu curses dan sistem build merujuk ke folder godot-cpp yang sama.

### Keterkaitan dengan Bab 10 (Fungsi Curses)
- Pesan peringatan `print(f"{C.RIW}...")` menggunakan `C` yang didefinisikan di sini. Meskipun `build_logic.py` tidak berjalan di dalam curses, warna ANSI tetap bekerja di terminal biasa.

---

## 10 Kesimpulan

Pada bab ini, kita telah membahas **bagian pertama** dari `LOGIC_CONTENT` - prolog, kelas-kelas utility, dan konfigurasi awal `build_logic.py`. Kita mempelajari:
1. **Prolog** - import library dan variabel `Start` untuk mengukur durasi build.
2. **Kelas `Terminal`** - wrapper untuk `stdout` yang menulis ke terminal dan file log secara bersamaan.
3. **Kelas `ColorMagic`** - pewarnaan terminal dengan sintaks ringkas (`C.RIW`, `C.GIW`, dll).
4. **Konfigurasi awal** - path log, `MAX_HISTORY`, `SOURCE_FILES`, `GEXT_FILE`.
5. **Pembacaan `build_options.json`** - memuat opsi build dari file yang disimpan oleh menu curses.
6. **Penentuan `godot_cpp_path`** - berdasarkan branch dan api_version.
7. **Penentuan `targets`** - daftar platform dan arsitektur yang akan dibangun.
8. **Dampak opsi `bits`** - bagaimana arsitektur 64/32-bit memengaruhi konfigurasi build.