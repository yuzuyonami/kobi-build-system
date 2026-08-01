# BAB 14 - ISI "build_logic.py" (FUNGSI LOGGING DAN REPORT)

---

## 1. Pendahuluan: Merekam Jejak Build

Setelah kita memahami prolog, kelas utility, dan konfigurasi awal [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)|`build_logic.py`]], kini saatnya membahas **sistem logging** yang menjadi tulang punggung pelacakan dan debugging. Sistem logging di `build_logic.py` dirancang untuk:
1. **Merekam setiap build** - sukses maupun gagal - ke dalam tiga format berbeda
    1. **Markdown** (`build_report.md`) - untuk dibaca manusia.
    2. **JSON** (`build_history.json`) - untuk dibaca mesin.
    3. **Error log** (`build_errors.log`) - untuk detail error lengkap.
2. **Mengarsipkan entri lama** - mencegah file log membengkak tanpa batas.
3. **Menangkap error compile** - melalui `atexit` dan `GetBuildFailures()` dari SCons.

Pada Bab 14, kita akan membahas:
1. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#2. Fungsi `_archive_old_json()` - Mengarsipkan Entri JSON Lama|`_archive_old_json()` - mengarsipkan entri JSON lama ke file arsip.]]
2. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#3. Fungsi `_archive_old_md()` - Merotasi `build_report.md`|`_archive_old_md()` - merotasi `build_report.md` jika sudah mencapai `MAX_HISTORY`.]]
3. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#4. Fungsi `write_logs()` - Fungsi Utama Logging|`write_logs()` - fungsi utama logging yang menulis ke semua format.]]
4. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#5. Fungsi `report_build_failures()` - Menangkap Error Compile|`report_build_failures()` - menangkap error compile melalui `atexit`.]]
5. [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#`atexit.register(report_build_failures)`|`atexit.register()` - mendaftarkan fungsi untuk dipanggil saat build selesai.]]

Semua kode dalam bab ini adalah bagian dari konstanta `LOGIC_CONTENT` yang didefinisikan di **Baris 163 - 500** dari `bootstrap_scons_gui.py`.

> [!quote] **Referensi Silang:**
> - Fungsi-fungsi logging ini dipanggil oleh [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()`]].
> - `write_logs()` menulis ke file yang dibaca oleh [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#10. Fungsi `get_last_build_info()` - Informasi Build Terakhir|`get_last_build_info()` di Bab 7.]]
> - [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#`MAX_HISTORY`|`MAX_HISTORY` didefinisikan di Bab 13.]]

---

## 2. Fungsi `_archive_old_json()` - Mengarsipkan Entri JSON Lama

*(Lokasi Baris 267 - 275)*
```python
def _archive_old_json(old_entries):
    """Simpan entri lama ke file arsip JSON sebelum di-trim dari history utama."""
    archive = []
    if os.path.exists(JSON_ARCHIVE):
        try:
            with open(JSON_ARCHIVE, "r") as f: archive = json.load(f)
        except: pass
    archive.extend(old_entries)
    with open(JSON_ARCHIVE, "w") as f: json.dump(archive, f, indent=4)
```

### Tujuan
Fungsi ini **memindahkan** entri-entri lama dari `build_history.json` ke file arsip `build_history_archive.json`. Ini dilakukan ketika `build_history.json` melebihi `MAX_HISTORY = 50` entri.

### Parameter
- **`old_entries`** - list of dictionary entri yang akan diarsipkan (biasanya entri yang paling lama).

### Alur Eksekusi
1. **Baca arsip yang sudah ada** - jika `build_history_archive.json` sudah ada, baca isinya ke `archive`.
2. **Tambahkan entri lama** - `archive.extend(old_entries)` menambahkan entri baru ke akhir arsip.
3. **Tulis kembali** - seluruh arsip ditulis ke `build_history_archive.json`.

### Mengapa Arsip Tidak Pernah Dibatasi?
`build_history_archive.json` **tidak** memiliki batasan ukuran. Ini karena:
- Arsip jarang dibaca, hanya untuk referensi historis.
- Membatasi arsip akan menambah kompleksitas tanpa manfaat besar.
- File JSON dengan ribuan entri masih relatif kecil (beberapa MB).

### Format Arsip
Arsip adalah **array JSON** dari entri-entri build, dengan format yang sama seperti `build_history.json`:

```json
[
  {
    "time": "2026-07-20 14:30:22",
    "plat": "linux",
    "arch": "64",
    "status": "SUCCESS",
    "msg": "bin/compile.linux.64.so (2m 15s)",
    "dur": "135s"
  },
  ...
]
```

---

## 3. Fungsi `_archive_old_md()` - Merotasi `build_report.md`

*(Lokasi Baris 278 - 290)*
```python
def _archive_old_md():
    """Kalau build_report.md sudah kepanjangan (>= MAX_HISTORY entri), pindahkan ke file arsip
    bertimestamp dan mulai file baru yang bersih."""
    if not os.path.exists(LOG_FILE):
        return
    with open(LOG_FILE, "r") as f:
        content = f.read()
    jumlah_entri = content.count("### ")
    if jumlah_entri >= MAX_HISTORY:
        stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        arsip_name = f"logs/build_report_archive_{stamp}.md"
        os.rename(LOG_FILE, arsip_name)
        sys.stdout.log_only(f"build_report.md di-rotate ke {arsip_name}")
```

### Tujuan
Fungsi ini merotasi `build_report.md` jika sudah mencapai `MAX_HISTORY` entri (50). Rotasi dilakukan dengan:
1. Memberi nama baru dengan timestamp.
2. Memulai file `build_report.md` baru yang kosong.

### Alur Eksekusi
1. **Cek apakah file ada** - jika tidak ada, return.
2. **Baca seluruh isi file** - `content = f.read()`.
3. **Hitung jumlah entri** - `content.count("### ")` menghitung berapa kali header entri muncul (setiap entri dimulai dengan `###`).
4. **Jika `jumlah_entri >= MAX_HISTORY`**:
    - Buat timestamp: `20260725_143022`.
    - Buat nama file arsip: `logs/build_report_archive_20260725_143022.md`.
    - **Pindahkan** (rename) file lama ke nama arsip.
    - Catat ke log (hanya di file log, tidak ke terminal).

### Mengapa Menggunakan `os.rename()`
`os.rename()` adalah operasi **atomik** - file langsung dipindahkan tanpa menyalin konten. Ini lebih efisien daripada:
- Membaca seluruh konten.
- Menulis ke file baru.
- Menghapus file lama.

### Mengapa Tidak Ada Kompresi?
File Markdown relatif kecil (~50 entri × ~10 baris = ~500 baris, ~20 KB). Kompresi tidak diperlukan dan akan menambah kompleksitas.

---

## 4. Fungsi `write_logs()` - Fungsi Utama Logging

*(Lokasi Baris 293 - 336)*
```python
def write_logs(plat, bits, status, details="", full_error=""):
    timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    durasi = f"{int(time.time() - Start)}s"
    # Update JSON (dengan rotasi + arsip) -- entri BARU selalu disisipkan di paling depan (index 0)
    history = []
    if os.path.exists(JSON_LOG):
        try:
            with open(JSON_LOG, "r") as f:
                history = json.load(f)
        except: pass
    history.insert(0, {"time": timestamp, "plat": plat, "arch": bits, "status": status, "msg": details, "dur": durasi})
    if len(history) > MAX_HISTORY:
        lama = history[MAX_HISTORY:]
        _archive_old_json(lama)
        history = history[:MAX_HISTORY]
    with open(JSON_LOG, "w") as f:
        json.dump(history, f, indent=4)
    # Update MD (entri baru disisipkan tepat di bawah judul, di ATAS entri-entri lama)
    _archive_old_md()
    entry_md = f"### {'✅' if status == 'SUCCESS' else '❌'} [{timestamp}] Build {status}\n- **Platform**: `{plat} {bits}`\n- **Durasi**: `{durasi}`\n- **File**: `{details}`\n\n---\n"
    if os.path.exists(LOG_FILE):
        with open(LOG_FILE, "r") as f:
            isi_lama = f.read()
        header = "# 🛠️ Build History Log\n\n"
        sisa = isi_lama[len(header):] if isi_lama.startswith(header) else isi_lama
        with open(LOG_FILE, "w") as f:
            f.write(header + entry_md + sisa)
    else:
        with open(LOG_FILE, "w") as f:
            f.write("# 🛠️ Build History Log\n\n" + entry_md)
    # Kalau gagal & ada detail lengkap, catat di file error terpisah
    if status == "FAILED" and full_error:
        entry_err = f"\n===== [{timestamp}] {plat} {bits}-bit =====\n{full_error}\n"
        isi_lama_err = ""
        if os.path.exists(ERROR_LOG_FILE):
            with open(ERROR_LOG_FILE, "r", encoding="utf-8") as f:
                isi_lama_err = f.read()
        with open(ERROR_LOG_FILE, "w", encoding="utf-8") as f:
            f.write(entry_err + isi_lama_err)
```

### Tujuan
Fungsi `write_logs()` adalah **fungsi utama logging** - dipanggil setiap kali build selesai (sukses atau gagal) untuk mencatat hasilnya ke:
1. **JSON** (`build_history.json`) - dengan rotasi dan arsip.
2. **Markdown** (`build_report.md`) - dengan rotasi dan insert di awal.
3. **Error log** (`build_errors.log`) - khusus untuk build gagal, dengan detail lengkap.

### Parameter

|Parameter|Tipe|Deskripsi|
|---|---|---|
|`plat`|`str`|Platform: `"linux"` atau `"windows"`|
|`bits`|`str`|Arsitektur: `"64"` atau `"32"`|
|`status`|`str`|`"SUCCESS"` atau `"FAILED"`|
|`details`|`str`|Ringkasan (misal nama file output)|
|`full_error`|`str`|Detail error lengkap (hanya untuk `"FAILED"`)|

### Timestamp dan Durasi
```python
timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
durasi = f"{int(time.time() - Start)}s"
```

- **Timestamp** - format `2026-07-25 14:30:22`.
- **Durasi** - total detik sejak `Start` (didefinisikan di prolog). Contoh: `"135s"`.

### Update JSON - Entri Baru di Depan

*(Lokasi Baris 298 - 309)*
```python
history = []
if os.path.exists(JSON_LOG):
    try:
        with open(JSON_LOG, "r") as f:
            history = json.load(f)
    except: pass
history.insert(0, {"time": timestamp, "plat": plat, "arch": bits, "status": status, "msg": details, "dur": durasi})
if len(history) > MAX_HISTORY:
    lama = history[MAX_HISTORY:]
    _archive_old_json(lama)
    history = history[:MAX_HISTORY]
```

**Logika:**
1. Baca `history` yang sudah ada (jika ada).
2. **Insert di index 0** - entri baru di paling depan (newest-first).
3. Jika `len(history) > MAX_HISTORY`:
    - Pisahkan entri lama (`history[MAX_HISTORY:]`).
    - Arsipkan dengan `_archive_old_json()`.
    - Potong `history` menjadi `MAX_HISTORY` entri pertama.
4. Tulis kembali ke `build_history.json`.

### Update Markdown - Entri Baru di Atas

*(Lokasi Baris 314 - 325)*
```python
_archive_old_md()
entry_md = f"### {'✅' if status == 'SUCCESS' else '❌'} [{timestamp}] Build {status}\n- **Platform**: `{plat} {bits}`\n- **Durasi**: `{durasi}`\n- **File**: `{details}`\n\n---\n"
if os.path.exists(LOG_FILE):
    with open(LOG_FILE, "r") as f:
        isi_lama = f.read()
    header = "# 🛠️ Build History Log\n\n"
    sisa = isi_lama[len(header):] if isi_lama.startswith(header) else isi_lama
    with open(LOG_FILE, "w") as f:
        f.write(header + entry_md + sisa)
else:
    with open(LOG_FILE, "w") as f:
        f.write("# 🛠️ Build History Log\n\n" + entry_md)
```

**Logika:**
1. **Panggil `_archive_old_md()`** - rotasi jika sudah mencapai 50 entri.
2. **Buat entri Markdown**:
    - `✅` jika sukses, `❌` jika gagal.
    - Timestamp, platform, durasi, dan detail file.
3. **Jika file sudah ada**:
    - Baca isi lama.
    - Ekstrak `header` dan `sisa` (konten tanpa header).
    - Tulis ulang dengan `header + entry_md + sisa` → entri baru di paling atas.
4. **Jika file belum ada** - tulis header + entri baru.

### Update Error Log - Khusus Build Gagal

*(Lokasi Baris 329 - 363*
```python
if status == "FAILED" and full_error:
    entry_err = f"\n===== [{timestamp}] {plat} {bits}-bit =====\n{full_error}\n"
    isi_lama_err = ""
    if os.path.exists(ERROR_LOG_FILE):
        with open(ERROR_LOG_FILE, "r", encoding="utf-8") as f:
            isi_lama_err = f.read()
    with open(ERROR_LOG_FILE, "w", encoding="utf-8") as f:
        f.write(entry_err + isi_lama_err)
```

**Logika:**
1. Hanya jika ada status `"FAILED"` dan ada `full_error` (tidak kosong).
2. Buat entri error dengan timestamp dan separator.
3. Baca isi lama (jika ada).
4. Tulis **entri baru di paling atas** (newest-first).

### Format Error Log

*(Contoh isi build_errors.log)*
```text
===== [2026-07-25 14:30:22] linux 64-bit =====
Target : build/linux_64/main.cpp.o
Error  : main.cpp:10:5: error: 'undefined_function' was not declared in this scope
Command: g++ -c -o build/linux_64/main.cpp.o src/main.cpp

===== [2026-07-25 14:25:10] windows 64-bit =====
Target : build/windows_64/main.cpp.o
Error  : main.cpp:15:10: fatal error: 'missing_header.h' file not found
Command: x86_64-w64-mingw32-g++ -c -o build/windows_64/main.cpp.o src/main.cpp
```

### Mengapa Entri Baru di Atas (Newest-First)?

Baik JSON, Markdown, maupun error log menempatkan entri **terbaru di paling atas**. Ini karena:
- Pengguna biasanya ingin melihat build **terakhir** terlebih dahulu.
- Untuk Markdown dan error log, scrolling ke bawah untuk melihat entri lama tidak masalah.
- Untuk JSON, `get_last_build_info()` di Bab 7 langsung mengambil `history[0]`.

---

## 5. Fungsi `report_build_failures()` - Menangkap Error Compile

*(Lokasi Baris 339 - 365)*
```python
def report_build_failures():
    """Dipanggil otomatis setelah proses build SCons selesai (via atexit).
    Ini satu-satunya cara yang benar untuk menangkap kegagalan compile,
    karena env.SharedLibrary() cuma MENDAFTARKAN target -- compile beneran
    baru jalan setelah SConstruct ini selesai diparse, jauh setelah try/except manapun."""
    failures = GetBuildFailures()
    if not failures:
        return
    for bf in failures:
        node_name = str(bf.node)
        errstr = bf.errstr or "Unknown error"
        plat_guess, bits_guess = "unknown", "?"
        for p, b in targets:
            if f".{p}.{b}" in node_name:
                plat_guess, bits_guess = p, b
                break
        ringkas = f"{node_name}: {errstr}"
        detail = f"Target : {node_name}\nError  : {errstr}\nCommand: {getattr(bf, 'command', 'N/A')}"
        print(f"{C.RIW}>>> Build {plat_guess} {bits_guess} FAILED -- {errstr}{C.N}")
        write_logs(plat_guess, bits_guess, "FAILED", ringkas, full_error=detail)
atexit.register(report_build_failures)
```

### Tujuan
`report_build_failures()` adalah **satu-satunya cara yang benar** untuk menangkap error compile di SCons. Ini karena:
- `env.SharedLibrary()` **hanya mendaftarkan target** - compile beneran terjadi **setelah** `SConstruct` selesai diparse.
- `try/except` di sekitar `env.SharedLibrary()` hanya menangkap error **konfigurasi** (misal argumen salah), **bukan** error compile.
- `GetBuildFailures()` dari SCons memberikan akses ke semua error yang terjadi selama build.

### `GetBuildFailures()` - API SCons
`GetBuildFailures()` mengembalikan list of `BuildFailure` objects, masing-masing memiliki atribut:
- **`node`** - target yang gagal (objek `Node` SCons).
- **`errstr`** - pesan error (string).
- **`command`** - command yang dijalankan (string) – tersedia jika diatur.

### Menebak Platform dan Bit dari Nama Node

*(Lokasi Baris 353 - 357)*
```python
plat_guess, bits_guess = "unknown", "?"
for p, b in targets:
    if f".{p}.{b}" in node_name:
        plat_guess, bits_guess = p, b
        break
```

Fungsi mencoba menebak platform dan bit dari nama node target. Contoh:
- `node_name = "build/linux_64/main.cpp.o"` mengandung `".linux.64"` akan menjadi `plat_guess = "linux"`, `bits_guess = "64"`.
- `node_name = "build/windows_32/main.cpp.o"` mengandung `".windows.32"` akan menjadi `plat_guess = "windows"`, `bits_guess = "32"`.

**Fallback:** Jika tidak ada kecocokan, gunakan `"unknown"` dan `"?"`.

### Menulis Error ke Log

*(Lokasi Baris 359 - 363)*
```python
ringkas = f"{node_name}: {errstr}"
detail = f"Target : {node_name}\nError  : {errstr}\nCommand: {getattr(bf, 'command', 'N/A')}"
print(f"{C.RIW}>>> Build {plat_guess} {bits_guess} FAILED -- {errstr}{C.N}")
write_logs(plat_guess, bits_guess, "FAILED", ringkas, full_error=detail)
```

- **`ringkas`** - satu baris ringkasan (disimpan di `JSON_LOG` dan `build_report.md`).
- **`detail`** - multi-line dengan target, error, dan command (disimpan di `build_errors.log`).
- **`print()`** - menampilkan error di terminal dengan warna merah.
- **`write_logs()`** - mencatat ke semua log.

### `atexit.register(report_build_failures)`

*(Lokasi Baris 365)*
```python
atexit.register(report_build_failures)
```

`atexit` adalah modul Python yang memungkinkan pendaftaran fungsi yang akan dipanggil **saat interpreter Python keluar**. Karena SCons adalah aplikasi Python, ini berarti:
- `report_build_failures()` dipanggil **setelah** seluruh proses build selesai.
- Ini **menjamin** bahwa semua error compile, bahkan yang terjadi di tahap akhir build, akan tercatat.

### Mengapa Tidak Bisa Menggunakan `try/except`?

*(Contoh Kode)*
```python
try:
    result = env.SharedLibrary(target=current_target, source=CURRENT_SOURCES)
except Exception as e:
    # Ini hanya menangkap error KONFIGURASI, BUKAN error compile!
    print(f"Config error: {e}")
```

**Penjelasan:**
1. `env.SharedLibrary()` **mendaftarkan** target build ke SCons, tetapi **tidak mengeksekusi** compile saat itu juga.
2. Compile dieksekusi **setelah** seluruh `SConstruct` selesai diparse.
3. Jika ada error compile (misal syntax error di C++), itu terjadi **di luar** blok `try/except`.
4. `GetBuildFailures()` adalah satu-satunya cara untuk menangkap error tersebut.

---

## 6. Alur Logging Lengkap

Berikut adalah alur lengkap dari saat build selesai hingga log ditulis:

> [!info]- Alur Logging
> ```text
> 1. Build selesai (sukses atau gagal)
> 	|
> 2. Jika sukses → Post-action di `build_with_logging()` memanggil `write_logs()`
> 	|
> 3. Jika gagal → `atexit` memanggil `report_build_failures()`
> 	|
> 4. `report_build_failures()` memanggil `write_logs()` untuk setiap error
> 	|
> 5. `write_logs()`:
>    a. Buat timestamp dan durasi
>    b. Tulis ke JSON (`build_history.json`) dengan insert di depan + arsip
>    c. Tulis ke Markdown (`build_report.md`) dengan insert di depan + rotasi
>    d. Jika gagal → tulis ke error log (`build_errors.log`) dengan insert di depan
> 	|
> 6. Selesai. Log tersedia untuk dibaca oleh pengguna atau `get_last_build_info()`.
> ```

---

## 7. Tabel Rangkuman Fungsi Logging

| Fungsi                    | Lokasi    | Tujuan                                       | Dipanggil Oleh                                                 |
| ------------------------- | --------- | -------------------------------------------- | -------------------------------------------------------------- |
| `_archive_old_json()`     | 267 - 275 | Mengarsipkan entri JSON lama                 | `write_logs()` (jika len > MAX_HISTORY)                        |
| `_archive_old_md()`       | 278 - 290 | Merotasi `build_report.md`                   | `write_logs()` (setiap kali)                                   |
| `write_logs()`            | 293 - 336 | Menulis log ke JSON, Markdown, dan error log | Post-action build (sukses) / `report_build_failures()` (gagal) |
| `report_build_failures()` | 339 - 365 | Menangkap error compile via `atexit`         | `atexit` (saat interpreter keluar)                             |
| `atexit.register()`       | 365       | Mendaftarkan `report_build_failures()`       | Saat `build_logic.py` di-load                                  |

---

## 8. Keterkaitan dengan Fitur Baru v2.4.0

### Opsi `bits` dalam Log
Fitur `bits` (64/32-bit) muncul di semua log:
- **JSON**
- **Markdown**
- **Error log**

### Deteksi Platform dan Bit di `report_build_failures()`
Fungsi `report_build_failures()` menebak platform dan bit dari nama node target dengan mencari pola `.{plat}.{bits}`. Ini memungkinkan logging error dengan informasi arsitektur yang akurat.

### `MAX_HISTORY` dan Rotasi Log
`MAX_HISTORY = 50` adalah nilai yang sama untuk semua log. Jika pengguna sering melakukan build (misal 100 kali sehari), log akan di-rotate secara otomatis, mencegah file membengkak.

### Icon Unicode di Markdown
`build_report.md` menggunakan icon Unicode:
- `✅` untuk build sukses.
- `❌` untuk build gagal.

Ini membuat log Markdown lebih mudah dibaca secara visual.

---

## 9. Contoh Output Log

### `build_history.json`
*(Contoh Output Log dari build_history.json)*
```json
[
  {
    "time": "2026-07-25 14:30:22",
    "plat": "linux",
    "arch": "64",
    "status": "SUCCESS",
    "msg": "bin/linux_64_release/compile.linux.64.so (2m 15s)",
    "dur": "135s"
  },
  {
    "time": "2026-07-25 14:25:10",
    "plat": "windows",
    "arch": "64",
    "status": "FAILED",
    "msg": "build/windows_64/main.cpp.o: undefined reference to 'some_function'",
    "dur": "45s"
  }
]
```

### `build_report.md`
*(Contoh Output Log dari build.md)*
```markdown
# 🛠️ Build History Log
### ✅ [2026-07-25 14:30:22] Build SUCCESS
- **Platform**: `linux 64`
- **Durasi**: `135s`
- **File**: `bin/linux_64_release/compile.linux.64.so (2m 15s)`
  
---

### ❌ [2026-07-25 14:25:10] Build FAILED
- **Platform**: `windows 64`
- **Durasi**: `45s`
- **File**: `build/windows_64/main.cpp.o: undefined reference to 'some_function'`
  
---
```

###  `build_errors.log`
*(Contoh Output Log dari build_errors.log)*
```log
'===== [2026-07-25 14:25:10] windows 64-bit ====='
Target : build/windows_64/main.cpp.o
Error  : undefined reference to 'some_function'
Command: x86_64-w64-mingw32-g++ -c -o build/windows_64/main.cpp.o src/main.cpp
```

### `terminal_cctv.log`
File ini berisi **semua** output terminal, termasuk:
- Pesan `print()` dari `build_logic.py`.
- Output dari SCons (termasuk command yang dijalankan).
- Pesan error dari compiler.

Ini adalah file paling komprehensif untuk debugging.

---

## 10. Kesimpulan

Pada bab ini, kita telah membahas **sistem logging** dari `build_logic.py` secara mendalam. Kita mempelajari:
1. **`_archive_old_json()`** - mengarsipkan entri JSON lama ke `build_history_archive.json`.
2. **`_archive_old_md()`** - merotasi `build_report.md` dengan timestamp.
3. **`write_logs()`** - fungsi utama logging yang menulis ke JSON, Markdown, dan error log.
4. **`report_build_failures()`** - menangkap error compile melalui `atexit` dan `GetBuildFailures()`.
5. **`atexit.register()`** - mendaftarkan `report_build_failures()` untuk dipanggil saat build selesai.
6. **Dampak `bits`** - arsitektur dicatat di semua log.
7. **Format log** - JSON, Markdown, error log, dan terminal log.