# BAB 6 - `bootstrap_scons_gui.py`: SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL

---

## 1. Pendahuluan: Lapisan Kedua Self-Relaunch dan Fondasi Build

Setelah kita memahami bagaimana `bootstrap_scons_gui.py` digenerate dari heredoc di **Bab 5**, kini saatnya membahas **bagian awal dari file Python itu sendiri** – dimulai dari mekanisme self-relaunch di level Python, hingga konstanta-konstanta awal yang menjadi fondasi dari seluruh sistem build.

Pada Bab 6, kita akan membahas:
1. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#2. Blok `if not sys.stdin.isatty() ` - Deteksi Terminal Non-Interaktif di Python|Blok `if not sys.stdin.isatty():` - deteksi terminal non-interaktif di level Python.]]
2. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#3. Path File Absolut `os.path.abspath(__file__)`|`os.path.abspath(__file__)` - mendapatkan path absolut file Python yang sedang berjalan.]]
3. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#4. Perintah Dalam Terminal `python3 "{path_file}"; echo; read -p "Press ENTER..."`|Perintah dalam terminal - `python3 "{path_file}"; echo; read -p "Press ENTER..."` - menjaga terminal tetap terbuka.]]
4. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#5. Daftar Kandidat Terminal di Python|Daftar kandidat terminal di Python - dengan parameter spesifik untuk `gnome-terminal`, `konsole`, `xfce4-terminal`, `x-terminal-emulator`, dan `xterm`.]]
5. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#8. Konstanta `STUB_CONTENT` - Isi File `SConstruct`|Konstanta `STUB_CONTENT` - isi file `SConstruct` yang hanya berisi `exec(open("build_logic.py").read())`.]]
6. [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#9. Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`|Konstanta `LOGIC_CONTENT` - string raksasa yang berisi seluruh logika build SCons (pengantar untuk Bab 13 - 15).]]

Ini adalah bab yang **menjembatani** antara shell script (Bab 1 - 5) dan logika build sebenarnya (Bab 7 - 15). Di sinilah kita melihat bagaimana Python mengambil alih kendali dari Bash dan mempersiapkan seluruh ekosistem build.

> [!quote] **Referensi Silang:**
> - Self-relaunch Python di sini adalah **lapisan kedua** setelah self-relaunch Bash di [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)|Bab 4.]]
> - `STUB_CONTENT` dan `LOGIC_CONTENT` akan digunakan di [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|`generate_files()`.]]
> - `LOGIC_CONTENT` akan dibahas secara mendetail di Bab 13 - 15.

---

## 2. Blok `if not sys.stdin.isatty():` - Deteksi Terminal Non-Interaktif di Python

*(Lokasi Baris 127 - 152)*
```python
if not sys.stdin.isatty():
    path_file = os.path.abspath(__file__)
    perintah_dalam = (
        f'python3 "{path_file}"; echo; read -p "Press ENTER to close this window..."'
    )
    
    kandidat_terminal = [
        ("gnome-terminal", ["gnome-terminal", "--", "bash", "-c", perintah_dalam]),
        ("konsole", ["konsole", "-e", "bash", "-c", perintah_dalam]),
        ("xfce4-terminal", ["xfce4-terminal", "-e", f"bash -c '{perintah_dalam}'"]),
        ("x-terminal-emulator", ["x-terminal-emulator", "-e", f"bash -c '{perintah_dalam}'"]),
        ("xterm", ["xterm", "-e", f"bash -c '{perintah_dalam}'"]),
    ]
    
    for nama, cmd in kandidat_terminal:
        if shutil.which(nama):
            subprocess.Popen(cmd)
            sys.exit(0)
    
    sys.exit(
        "No known terminal emulator found. "
        f"Jalanin manual lewat terminal: python3 {path_file}"
    )
```

### Tujuan
Blok ini adalah **self-relaunch di level Python** - mekanisme yang identik dengan yang ada di level [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)|Bash]], tetapi diimplementasikan di Python. Ini adalah **lapisan kedua** dari sistem self-relaunch:
1. **Lapisan 1 (Bash)** - jika `jalankan_bootstrapper.sh` dijalankan tanpa [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#2. Kondisi `[ ! -t 0 ]` - Deteksi Terminal Non-Interaktif|terminal.]]
2. **Lapisan 2 (Python)** - jika `bootstrap_scons_gui.py` dijalankan tanpa terminal (misal dari cron, IDE, atau dari file manager jika pengguna secara tidak sengaja mengklik file `.py`).

### Deteksi dengan `sys.stdin.isatty()`

*(Lokasi Baris 127)*
```python
if not sys.stdin.isatty():
```

- **`sys.stdin.isatty()`** - mengembalikan `True` jika stdin terhubung ke terminal, `False` jika tidak.
- **`not sys.stdin.isatty()`** - jika stdin **bukan** terminal (non-interaktif), jalankan self-relaunch.

Ini adalah **padanan Python** dari [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#2. Kondisi `[ ! -t 0 ]` - Deteksi Terminal Non-Interaktif|`[ ! -t 0 ]` di Bash.]]

### Mengapa Self-Relaunch Python Diperlukan?

Ada beberapa skenario di mana `bootstrap_scons_gui.py` bisa dijalankan tanpa terminal:

|Skenario|Contoh|Apa yang Terjadi Tanpa Self-Relaunch|
|---|---|---|
|Diklik dari file manager|Pengguna mengklik `bootstrap_scons_gui.py` di Nautilus|File manager mencoba menjalankan Python, tapi tidak ada terminal – script error atau berjalan di background|
|Dijalankan dari IDE|VS Code menjalankan file Python tanpa terminal terintegrasi|Output tidak terlihat, pengguna bingung|
|Dijalankan dari cron/systemd|Script dijadwalkan otomatis|Tidak ada output yang terlihat, sulit debug|
|Dijalankan dari pipeline|`python3 script.py < /dev/null`|stdin bukan terminal, curses gagal|

Dengan self-relaunch, script akan **membuka terminal baru** dan menjalankan ulang dirinya sendiri di dalam terminal tersebut, memastikan pengguna dapat melihat antarmuka curses.

---

## 3. Path File Absolut: `os.path.abspath(__file__)`

*(Lokasi Baris 128)*
```python
path_file = os.path.abspath(__file__)
```

### Tujuan
`path_file` menyimpan **path absolut** dari file `bootstrap_scons_gui.py` yang sedang berjalan. Ini digunakan untuk menjalankan ulang file di terminal baru.

### Komponen

|Komponen|Fungsi|
|---|---|
|`__file__`|Variabel bawaan Python yang berisi path file script yang sedang dieksekusi.|
|`os.path.abspath()`|Mengubah path relatif menjadi absolut, menormalisasi `..` dan `.`.|

### Mengapa Perlu Path Absolut?
Ketika terminal baru dibuka, **direktori kerja** mungkin berbeda dari direktori tempat script berada. Dengan menggunakan path absolut, kita memastikan bahwa terminal baru dapat menemukan dan menjalankan script, terlepas dari di mana terminal dibuka.

### Perbedaan dengan `SCRIPT_PATH` di Bash

|Aspek|Bash (Bab 4)|Python (Bab 6)|
|---|---|---|
|Variabel|`SCRIPT_PATH="$(readlink -f "$0")"`|`path_file = os.path.abspath(__file__)`|
|Perintah|`readlink -f` (external)|`os.path.abspath()` (built-in Python)|
|Portabilitas|Bergantung pada GNU coreutils|Bekerja di semua platform Python|

---

## 4. Perintah Dalam Terminal: `python3 "{path_file}"; echo; read -p "Press ENTER..."`

*(Lokasi Baris 132 - 134)*
```python
perintah_dalam = (
    f'python3 "{path_file}"; echo; read -p "Press ENTER to close this window..."'
)
```

### Tujuan
`perintah_dalam` adalah **string perintah** yang akan dijalankan di dalam terminal baru. Perintah ini terdiri dari tiga bagian:
1. **`python3 "{path_file}"`** - menjalankan `bootstrap_scons_gui.py` di terminal baru.
2. **`; echo`** - setelah script selesai, cetak baris kosong (spasi visual)
3. **`read -p "Press ENTER to close this window..."`** - menunggu pengguna menekan ENTER sebelum menutup terminal.

### Mengapa Perlu `read -p`?
Tanpa `read -p`, terminal akan **langsung tertutup** setelah script selesai (atau crash). Pengguna tidak akan sempat membaca pesan error atau output terakhir. Dengan `read -p`:
- Terminal tetap terbuka sampai pengguna menekan ENTER.
- Pengguna bisa membaca semua output, termasuk error.
- Pengalaman debugging menjadi lebih baik.

### Mengapa Menggunakan `bash -c` sebagai Wrapper?
Perintah `python3 "{path_file}"; echo; read -p "Press ENTER..."` adalah **perintah shell** (bukan perintah tunggal). Untuk menjalankannya di terminal, kita perlu membungkusnya dengan `bash -c`:

```bash
bash -c 'python3 "/path/to/file.py"; echo; read -p "Press ENTER..."'
```

Ini memastikan bahwa:
- Semua perintah dieksekusi secara berurutan di shell yang sama.
- `read -p` berfungsi dengan benar (membutuhkan shell interaktif).

> [!info]- Contoh Perintah Lengkap
> ### Contoh Perintah Lengkap
> 
> Jika `path_file = "/home/user/project/bootstrap_scons_gui.py"`, maka `perintah_dalam` akan menjadi:
> 
> ```bash
> python3 "/home/user/project/bootstrap_scons_gui.py"; echo; read -p "Press ENTER to close this window..."
> ```
> 
> Dan perintah yang dijalankan di terminal adalah:
> 
> ```bash
> bash -c 'python3 "/home/user/project/bootstrap_scons_gui.py"; echo; read -p "Press ENTER to close this window..."'
> ```
> 

---

## 5. Daftar Kandidat Terminal di Python

*(Lokasi Baris 136 - 142)*
```python
kandidat_terminal = [
    ("gnome-terminal", ["gnome-terminal", "--", "bash", "-c", perintah_dalam]),
    ("konsole", ["konsole", "-e", "bash", "-c", perintah_dalam]),
    ("xfce4-terminal", ["xfce4-terminal", "-e", f"bash -c '{perintah_dalam}'"]),
    ("x-terminal-emulator", ["x-terminal-emulator", "-e", f"bash -c '{perintah_dalam}'"]),
    ("xterm", ["xterm", "-e", f"bash -c '{perintah_dalam}'"]),
]
```

### Tujuan
Daftar ini mendefinisikan **kandidat terminal emulator** yang akan dicoba oleh script. Setiap entri adalah tuple `(nama_terminal, list_perintah)`.

### Perbedaan dengan Daftar di Bash

|Aspek|Bash (Bab 4)|Python (Bab 6)|
|---|---|---|
|**Struktur**|`for` loop dengan `case`|`for` loop dengan tuple `(nama, cmd)`|
|**Perintah**|`bash "$SCRIPT_PATH"`|`bash -c "$perintah_dalam"`|
|**Penanganan quote**|Tidak diperlukan (perintah sederhana)|Diperlukan (perintah kompleks dengan `;` dan `read`)|
|**Pengecekan**|`command -v`|`shutil.which()`|

### Perbedaan Parameter Antara Terminal

Seperti di [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#1. Pendahuluan Menjembatani Dunia GUI dan Terminal|Bash]], setiap terminal memiliki **sintaks parameter yang berbeda**:

|Terminal|Parameter|Perintah|Keterangan|
|---|---|---|---|
|`gnome-terminal`|`--`|`gnome-terminal -- bash -c "cmd"`|`--` memisahkan opsi terminal dari perintah|
|`konsole`|`-e`|`konsole -e bash -c "cmd"`|`-e` (execute)|
|`xfce4-terminal`|`-e`|`xfce4-terminal -e "bash -c 'cmd'"`|`-e` dengan string yang di-quote|
|`x-terminal-emulator`|`-e`|`x-terminal-emulator -e "bash -c 'cmd'"`|`-e` dengan string yang di-quote|
|`xterm`|`-e`|`xterm -e "bash -c 'cmd'"`|`-e` dengan string yang di-quote|

### Mengapa `xfce4-terminal` dan Lainnya Menggunakan Format Berbeda?

Perhatikan perbedaan antara:
```python
("konsole", ["konsole", "-e", "bash", "-c", perintah_dalam]),
("xfce4-terminal", ["xfce4-terminal", "-e", f"bash -c '{perintah_dalam}'"]),
```

- **`konsole`** - menerima argumen secara terpisah: `-e bash -c "cmd"`.
- **`xfce4-terminal`** - memerlukan seluruh perintah sebagai **satu argumen string**: `-e "bash -c 'cmd'"`.

Ini adalah **perilaku spesifik** dari masing-masing terminal. `xfce4-terminal` (dan beberapa terminal lain) memerlukan quote tambahan karena mereka mem-parsing argumen `-e` sebagai satu string.

### Mengapa `gnome-terminal` Menggunakan `--`?
`gnome-terminal` memiliki banyak opsi (`--tab`, `--window`, `--geometry`, dll). Untuk mencegah konflik antara opsi terminal dan argumen perintah, `gnome-terminal` menggunakan `--` untuk menandai akhir dari opsi terminal. Setelah `--`, semua argumen dianggap sebagai perintah yang akan dijalankan.

---

## 6. Pengecekan Keberadaan Terminal dengan `shutil.which()`

*(Lokasi Baris 144 -147)*
```python
for nama, cmd in kandidat_terminal:
    if shutil.which(nama):
        subprocess.Popen(cmd)
        sys.exit(0)
```
### Tujuan
Loop ini iterasi melalui semua kandidat terminal, memeriksa apakah terminal tersedia di `PATH`, dan jika ya, menjalankannya.

### `shutil.which()` - Padanan Python dari `command -v`

|Aspek|Bash (Bab 4)|Python (Bab 6)|
|---|---|---|
|Perintah|`command -v "$NAMA_TERM"`|`shutil.which(nama)`|
|Return|Path executable atau empty|Path executable atau `None`|
|Portabilitas|Bergantung pada shell|Bekerja di semua platform Python|

`shutil.which()` mengembalikan path absolut ke executable jika ditemukan, atau `None` jika tidak. Ini adalah cara paling portabel di Python untuk memeriksa ketersediaan command.

### `subprocess.Popen(cmd)` - Menjalankan Terminal di Background

*(Lokasi Baris 146)*
```python
subprocess.Popen(cmd)
```

- **`subprocess.Popen()`** - menjalankan proses baru di **background** (tanpa menunggu).
- Ini memungkinkan script Python untuk **segera keluar** (`sys.exit(0)`) setelah terminal baru terbuka.
- Proses terminal baru berjalan secara independen dari script Python.

### `sys.exit(0)` - Keluar dari Proses Lama
Setelah berhasil membuka terminal baru, script **keluar** dengan kode `0` (sukses). Ini mirip dengan [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#7. `exit 0` - Keluar dari Proses Lama setelah Relaunch Berhasil|`exit 0` di Bash]] - proses lama diakhiri, dan kontrol berpindah ke instance baru di terminal.

---

## 7. Fallback jika Tidak Ada Terminal Ditemukan

**(Lokasi Baris 149 - 152)**
```python
sys.exit(
    "No known terminal emulator found. "
    f"Jalanin manual lewat terminal: python3 {path_file}"
)
```

### Tujuan
Jika loop selesai tanpa menemukan terminal emulator yang terinstall, script akan keluar dengan **pesan error** yang memberitahu pengguna untuk menjalankan script secara manual dari terminal.

### Mengapa Menggunakan `sys.exit()` dengan String?

*(Lokasi Baris  149)*
```python
sys.exit("Pesan error...")
```

- **`sys.exit()`** - mengakhiri script dengan kode exit `1` (error).
- Jika diberikan argumen string, string tersebut akan dicetak ke **stderr** sebelum keluar.
- Ini memberikan umpan balik yang jelas kepada pengguna tentang apa yang salah dan bagaimana memperbaikinya.

### Pesan Error yang Ramah Pengguna

Pesan error:
```text
No known terminal emulator found. Jalanin manual lewat terminal: python3 /path/to/bootstrap_scons_gui.py
```

- **"No known terminal emulator found."** – menjelaskan masalah.
- **"Jalanin manual lewat terminal: ..."** - memberikan solusi yang jelas.

---

## 8. Konstanta `STUB_CONTENT` - Isi File `SConstruct`

*(Lokasi Baris 154  - 161)*
```python
STUB_CONTENT = '''# ============================================================
#  Jangan edit logic di sini!
#  File ini cuma STUB biar `scons` (tanpa flag apapun) tetep
#  nemuin file build. Semua kode ada di build_logic.py --
#  edit di situ, dapet syntax highlighting Python penuh di editor.
# ============================================================
exec(open("build_logic.py").read())
'''
```

### Tujuan
`STUB_CONTENT` adalah **string literal** yang berisi isi dari file `SConstruct`. File ini adalah **entry point** untuk SCons – ketika pengguna menjalankan perintah `scons`, SCons akan mencari file `SConstruct` dan mengeksekusinya.

### Mengapa Hanya Satu Baris `exec()`?

*(Lokasi Baris 160)*
```python
exec(open("build_logic.py").read())
```

- **`open("build_logic.py").read()`** - membaca seluruh isi file `build_logic.py` sebagai string.
- **`exec()`** – mengeksekusi string tersebut sebagai kode Python.

Dengan pendekatan ini, `SConstruct` hanya berfungsi sebagai **stub** (pengarah) yang sangat sederhana. Semua logika build yang kompleks ditempatkan di `build_logic.py`.

### Keuntungan Pendekatan Stub

| Keuntungan              | Penjelasan                                                                      |
| ----------------------- | ------------------------------------------------------------------------------- |
| **Pemisahan logika**    | `SConstruct` tetap bersih dan sederhana.                                        |
| **Syntax highlighting** | `build_logic.py` mendapatkan highlighting penuh di editor (sebagai file `.py`). |
| **Keamanan**            | Pengguna cenderung tidak mengedit `SConstruct` karena tahu itu hanya stub.      |
| **Portabilitas**        | Jika logika build berubah, hanya `build_logic.py` yang perlu diperbarui.        |

### Komentar Peringatan
Komentar di `STUB_CONTENT` dengan tegas memperingatkan pengguna:
- **"Jangan edit logic di sini!"** - instruksi eksplisit.
- **"File ini cuma STUB"** - menjelaskan fungsi sebenarnya.
- **"Semua kode ada di build_logic.py"** - mengarahkan ke file yang benar.
- **"edit di situ, dapet syntax highlighting Python penuh"** - memberikan alasan praktis.

---

## 9. Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`

*(Lokasi Baris 163 - 173)*
```python
LOGIC_CONTENT = r'''import time
import datetime
...
'''
```

### Tujuan
`LOGIC_CONTENT` adalah **string raksasa** (sekitar 250 baris) yang berisi seluruh logika build SCons. Ini adalah **inti dari sistem build**  di sinilah semua konfigurasi compiler, logging, dan pelaporan error terjadi.

### Mengapa Menggunakan Raw String (`r'''...'''`)?

*(Lokasi Baris 163 )*
```python
LOGIC_CONTENT = r'''...'''
```

Penggunaan **raw string** (`r'''...'''`) memastikan bahwa karakter backslash (`\`) di dalam `build_logic.py` tidak diinterpretasikan sebagai escape sequence oleh Python. Ini penting karena:
- `build_logic.py` berisi banyak path dengan backslash (misal `bin/{plat}_{bits}_{BUILD_MODE}`).
- Tanpa raw string, backslash akan dianggap sebagai escape character dan menyebabkan error sintaks.

### Struktur `LOGIC_CONTENT`

Secara garis besar, `LOGIC_CONTENT` terdiri dari:

| Bagian           | Deskripsi                                                  | Dibahas di Bab                                                                             |
| ---------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------ |
| **Prolog**       | Import library, kelas `Terminal`, `ColorMagic`             | [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)\|Bab 13]]          |
| **Konfigurasi**  | `MAX_HISTORY`, `SOURCE_FILES`, `build_options.json`        | [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)\|Bab 13]]          |
| **Logging**      | `write_logs()`, `_archive_old_json()`, `_archive_old_md()` | [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)\|Bab 14]]           |
| **Report Error** | `report_build_failures()`, `atexit.register()`             | [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)\|Bab 14]]           |
| **Build Engine** | `build_with_logging()`, `generate_gdextension()`           | [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)\|Bab 15]] |

### Mengapa `LOGIC_CONTENT` Sangat Panjang?
Ada beberapa alasan:
1. **Self-contained** - `build_logic.py` tidak bergantung pada file eksternal selain `build_options.json` dan library standar Python.
2. **Fitur lengkap** - mendukung multi-platform, multi-arsitektur, debug/release, logging ke JSON dan Markdown, rotasi log, dan pelaporan error.
3. **Komentar dan dokumentasi** - banyak komentar dalam bahasa Indonesia untuk memudahkan pengembang memahami alur kode.

### Kaitan dengan `generate_files()`
`LOGIC_CONTENT` akan ditulis ke `build_logic.py` oleh fungsi [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|`generate_files()`]] ketika pengguna memilih menu `[ Generate! ]`. Setelah itu, pengguna dapat menjalankan `scons` di terminal untuk memulai build.

---

## 10. Perbandingan Self-Relaunch Bash vs Python

|Aspek|Self-Relaunch Bash (Bab 4)|Self-Relaunch Python (Bab 6)|
|---|---|---|
|**Lokasi**|`jalankan_bootstrapper.sh`|`bootstrap_scons_gui.py`|
|**Deteksi**|`[ ! -t 0 ]`|`not sys.stdin.isatty()`|
|**Path script**|`SCRIPT_PATH="$(readlink -f "$0")"`|`path_file = os.path.abspath(__file__)`|
|**Perintah di terminal**|`bash "$SCRIPT_PATH"`|`python3 "{path_file}"; echo; read -p "Press ENTER..."`|
|**Menjaga terminal**|Tidak|`read -p` menjaga terminal tetap terbuka|
|**Kandidat terminal**|5 (sama)|5 (sama)|
|**Pengecekan**|`command -v`|`shutil.which()`|
|**Parameter**|`case` dengan `--`, `-e`, `-x`|Tuple dengan perintah spesifik|
|**Eksekusi**|`"$NAMA_TERM" ...`|`subprocess.Popen(cmd)`|
|**Keluar**|`exit 0`|`sys.exit(0)`|
|**Fallback**|`exit 1`|`sys.exit("Pesan error...")`|

---

## 11. Tabel Rangkuman

| Komponen                                | Lokasi di `bootstrap_scons_gui.py` | Fungsi                                      |
| --------------------------------------- | ---------------------------------- | ------------------------------------------- |
| `if not sys.stdin.isatty():`            | 127                                | Deteksi terminal non-interaktif             |
| `path_file = os.path.abspath(__file__)` | 128                                | Path absolut file Python                    |
| `perintah_dalam`                        | 129                                | Perintah yang dijalankan di terminal baru   |
| `kandidat_terminal`                     | 136 - 142                          | Daftar 5 terminal emulator dengan parameter |
| `shutil.which(nama)`                    | 145                                | Pengecekan ketersediaan terminal di PATH    |
| `subprocess.Popen(cmd)`                 | 146                                | Membuka terminal baru di background         |
| `sys.exit(0)`                           | 147                                | Keluar dari proses lama                     |
| `sys.exit("Pesan error...")`            | 149                                | Fallback jika tidak ada terminal            |
| `STUB_CONTENT`                          | 154  - 161                         | Isi file `SConstruct` (stub)                |
| `LOGIC_CONTENT`                         | 163 - 173                          | Isi file `build_logic.py` (pengantar)       |

---

## 12. Keterkaitan dengan Bab Lain

| Konsep di Bab 6          | Terkait dengan Bab                                           |
| ------------------------ | ------------------------------------------------------------ |
| Self-relaunch Python     | Bab 4 (Self-relaunch Bash) - mekanisme serupa, lapisan kedua |
| `STUB_CONTENT`           | Bab 12 (`generate_files()`) - ditulis ke `SConstruct`        |
| `LOGIC_CONTENT`          | Bab 12 (`generate_files()`) - ditulis ke `build_logic.py`    |
| `LOGIC_CONTENT` (detail) | Bab 13 - 15 (Isi `build_logic.py`)                           |
| `shutil.which()`         | Bab 16 (`cek_command_ada()` di `setup_godot_cpp.py`)         |

---

## 13. Kesimpulan

Pada bab ini, kita telah membahas **bagian awal dari `bootstrap_scons_gui.py`** – dari self-relaunch Python hingga konstanta-konstanta awal yang menjadi fondasi sistem build. Kita mempelajari:
1. **Blok `if not sys.stdin.isatty():`** - deteksi terminal non-interaktif di Python, identik dengan Bab 4 tetapi diimplementasikan di level Python.
2. **`os.path.abspath(__file__)`** - mendapatkan path absolut file Python untuk menjalankan ulang di terminal baru.
3. **Perintah dalam terminal** – `python3 "{path_file}"; echo; read -p "Press ENTER..."` - menjaga terminal tetap terbuka setelah script selesai.
4. **Daftar kandidat terminal** - `gnome-terminal`, `konsole`, `xfce4-terminal`, `x-terminal-emulator`, `xterm` - dengan parameter spesifik untuk setiap terminal.
5. **`shutil.which()` dan `subprocess.Popen()`** - pengecekan ketersediaan terminal dan eksekusi di background.
6. **Fallback** - pesan error yang jelas jika tidak ada terminal ditemukan.
7. **Konstanta `STUB_CONTENT`** - isi file `SConstruct` yang hanya berisi `exec(open("build_logic.py").read())`.
8. **Konstanta `LOGIC_CONTENT`** - string raksasa yang berisi seluruh logika build SCons (akan dibahas di Bab 13 - 15.