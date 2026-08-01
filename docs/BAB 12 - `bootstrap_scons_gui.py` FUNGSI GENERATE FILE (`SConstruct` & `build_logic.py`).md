# BAB 12 - "bootstrap_scons_gui.py" FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)

---

## 1. Pendahuluan: Menghidupkan Sistem Build

Setelah kita memahami seluruh antarmuka pengguna, navigasi keyboard, dan eksekusi aksi (Bab 10 - 11), kini tiba saatnya untuk membahas **tujuan akhir** dari seluruh sistem bootstrapper: menghasilkan file-file yang akan menjalankan proses build sebenarnya. Di Bab 12 ini, kita akan melihat bagaimana `generate_files()` menulis dua file kunci:
1. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#3. Konstanta `STUB_CONTENT` - Isi File `SConstruct`|`SConstruct` - file utama yang dibaca oleh SCons saat perintah `scons` dijalankan.]]
2. [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#4 .Konstanta `LOGIC_CONTENT` - Isi File `build_logic.py`|`build_logic.py` - file yang berisi seluruh logika build (di-_import_ oleh `SConstruct`).]]

Filosofi di balik pemisahan ini adalah:
1. **`SConstruct`** - bertindak sebagai **stub** (pengarah) yang sangat sederhana, hanya berisi satu baris `exec()`.
2. **`build_logic.py`** - berisi **seluruh logika build** yang kompleks, termasuk manajemen kompilasi, logging, dan pelaporan error.

Dengan pemisahan ini, pengguna dapat mengedit `build_logic.py` dengan **syntax highlighting penuh** di editor favorit mereka, tanpa harus menyentuh `SConstruct` yang rawan error jika diedit secara tidak sengaja.

Semua kode dalam bab ini berada di dalam **heredoc `PYEOF_INNER`** dari `jalankan_bootstrapper.sh`, setelah fungsi [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD.md#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]] dan sebelum blok `if __name__ == "__main__":`.

>[!quote] **Referensi Silang:**
> - `generate_files()` dipanggil oleh menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `generate` - Save Options + Generate!|`[ Generate! ]`.]]
> - [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#8. Konstanta `STUB_CONTENT` - Isi File `SConstruct`|`STUB_CONTENT` didefinisikan di Baris 154 - 161.]]
> - [[BAB 6 - bootstrap_scons_gui.py SELF-RELAUNCH PYTHON DAN KONSTANTA AWAL#9. Konstanta `LOGIC_CONTENT` - String Raksasa Isi `build_logic.py`|`LOGIC_CONTENT` didefinisikan di aris 163 - 500]], dan akan dibahas secara detail di Bab 13 - 15.


---

## 2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py

*(Lokasi Baris 661 - 674)*
```python
def generate_files(stdscr, log_lines):
    sudah_ada = [f for f in ("SConstruct", "build_logic.py") if os.path.exists(f)]
    if sudah_ada:
        log_lines.append(f"WARNING: File already exists: {', '.join(sudah_ada)}. Overwritten.")
    with open("SConstruct", "w", encoding="utf-8") as f:
        f.write(STUB_CONTENT)
    log_lines.append("OK: SConstruct created!")
    with open("build_logic.py", "w", encoding="utf-8") as f:
        f.write(LOGIC_CONTENT)
    log_lines.append("OK: build_logic.py created!")
    log_lines.append("")
    log_lines.append("Done! Just type `scons` in the terminal.")
```

### Tujuan
Fungsi ini **menulis ulang** (overwrite) dua file build utama di folder proyek:
- **`SConstruct`** - ditulis dengan isi `STUB_CONTENT`.
- **`build_logic.py`** - ditulis dengan isi `LOGIC_CONTENT`.

### Parameter

|Parameter|Tipe|Deskripsi|
|---|---|---|
|`stdscr`|`curses.window`|Objek window curses (tidak digunakan secara langsung, hanya untuk konsistensi parameter).|
|`log_lines`|`list[str]`|Daftar pesan log yang akan ditambahi dengan status generate.|

### Peringatan Jika File Sudah Ada

```python
sudah_ada = [f for f in ("SConstruct", "build_logic.py") if os.path.exists(f)]
if sudah_ada:
    log_lines.append(f"WARNING: File already exists: {', '.join(sudah_ada)}. Overwritten.")
```

Fungsi ini **selalu menimpa** (overwrite) file yang sudah ada, tanpa meminta konfirmasi tambahan (karena konfirmasi sudah dilakukan di `confirm_generate()` sebelum fungsi ini dipanggil). Namun, log tetap mencatat peringatan bahwa file tersebut ditimpa, sehingga pengguna tahu bahwa perubahan mereka di `build_logic.py` (jika ada) akan hilang.

>[!warning] **Peringatan Penting:**
>Jika pengguna telah mengedit `build_logic.py` secara manual, menjalankan `[ Generate! ]` akan **menimpa** file tersebut dengan versi default dari bootstrapper. Ini adalah alasan mengapa ==Bab 19== (Rangkuman Status Edit) menekankan bahwa `build_logic.py` **tidak boleh diedit** - semua kustomisasi sebaiknya dilakukan di tempat lain.

### Menulis File

```python
with open("SConstruct", "w", encoding="utf-8") as f:
    f.write(STUB_CONTENT)
```

Kedua file ditulis dengan **encoding UTF-8** untuk memastikan kompatibilitas dengan karakter non-ASCII (misal komentar dalam bahasa Indonesia).

### Log Hasil
Setelah menulis, fungsi menambahkan pesan ke `log_lines`:
- `"OK: SConstruct created!"`
- `"OK: build_logic.py created!"`
- `""` (baris kosong untuk spasi visual)
- `"Done! Just type` scons `in the terminal."`

Pesan terakhir ini adalah **instruksi** kepada pengguna tentang langkah selanjutnya setelah keluar dari menu curses.

---

## 3. Konstanta `STUB_CONTENT` - Isi File `SConstruct`

*(Lokasi Baris 154 - 161)*
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
`STUB_CONTENT` adalah **file SConstruct yang sangat sederhana**. SCons, ketika dijalankan, akan mencari file bernama `SConstruct` atau `Sconstruct` di direktori saat ini. File ini adalah **entry point** yang akan dieksekusi oleh SCons.

### Mengapa Hanya `exec()`?
Alih-alih menulis semua logika build langsung di `SConstruct`, kita menggunakan **indirection** melalui `exec(open("build_logic.py").read())`. Ini memiliki beberapa keuntungan:
1. **Pemisahan logika** - `SConstruct` tetap bersih dan sederhana, semua logika kompleks ada di `build_logic.py`.
2. **Syntax highlighting** - Editor modern (VS Code, Sublime, dll) akan memberikan syntax highlighting penuh untuk `build_logic.py`, karena ekstensi `.py` dikenali sebagai file Python. `SConstruct` juga sebenarnya file Python, tapi beberapa editor tidak memberikan highlighting yang sama.
3. **Keamanan** - Pengguna cenderung tidak mengedit `SConstruct` karena tahu itu hanya stub. Jika mereka ingin mengubah perilaku build, mereka akan mengedit `build_logic.py`.
4. **Portabilitas** - Jika di masa depan sistem build berubah, `SConstruct` tetap sama, hanya `build_logic.py` yang perlu diperbarui.

### Komentar Peringatan
Komentar di `STUB_CONTENT` dengan tegas memperingatkan pengguna:
- **"Jangan edit logic di sini!"** - ini adalah instruksi eksplisit.
- **"File ini cuma STUB"** - menjelaskan fungsi sebenarnya.
- **"Semua kode ada di build_logic.py"** - mengarahkan pengguna ke file yang benar.
- **"edit di situ, dapet syntax highlighting Python penuh"** - memberikan alasan praktis mengapa mereka harus mengedit `build_logic.py` dan bukan `SConstruct`.

### Bagaimana SCons Menjalankan Ini?
Ketika pengguna menjalankan perintah `scons` di terminal:
1. SCons membaca `SConstruct`.
2. SCons mengeksekusi kode di dalamnya sebagai Python.
3. `exec(open("build_logic.py").read())` membuka `build_logic.py`, membaca seluruh isinya, dan menjalankannya sebagai kode Python.
4. Semua fungsi, variabel, dan logika di `build_logic.py` dieksekusi.
5. Hasilnya adalah proses build yang lengkap.

---

## 4 .Konstanta `LOGIC_CONTENT` - Isi File `build_logic.py`

*(Lokasi Baris 163 - 173)*
```python
LOGIC_CONTENT = r'''import time
import datetime
import os
import subprocess
import json
import sys
import glob
import atexit
from SCons.Script import GetBuildFailures
Start = time.time()

# ... (sekitar 250 baris kode build logic)
'''
```


### Tujuan
`LOGIC_CONTENT` adalah **string raksasa** yang berisi seluruh logika build SCons. File ini akan dibahas secara mendalam di Bab 13, 14, dan 15. Namun, di sini kita akan memberikan gambaran umum tentang strukturnya.

### Mengapa Menggunakan `r'''...'''` (Raw String)?

```python
LOGIC_CONTENT = r'''...'''
```

Penggunaan **raw string** (`r'''...'''`) memastikan bahwa karakter backslash (`\`) di dalam `build_logic.py` tidak diinterpretasikan sebagai escape sequence oleh Python. Ini penting karena:
- `build_logic.py` berisi banyak path dengan backslash (misal `bin/{plat}_{bits}_{BUILD_MODE}`).
- Tanpa raw string, backslash akan dianggap sebagai escape character dan menyebabkan error.

### Struktur `LOGIC_CONTENT`
Secara garis besar, `LOGIC_CONTENT` terdiri dari:

|Bagian|Lokasi di `LOGIC_CONTENT`|Deskripsi|
|---|---|---|
|**Prolog**|Awal–sekitar baris 50|Import, kelas `Terminal`, `ColorMagic`, konfigurasi awal|
|**Logging**|Sekitar baris 50–150|Fungsi `write_logs()`, `_archive_old_json()`, `_archive_old_md()`, `report_build_failures()`|
|**Build Engine**|Sekitar baris 150–akhir|Fungsi `build_with_logging()`, `generate_gdextension()`, eksekusi build|

### Mengapa `LOGIC_CONTENT` Sangat Panjang?
Ada beberapa alasan:
1. **Self-contained** - `build_logic.py` tidak bergantung pada file eksternal selain `build_options.json` dan library standar Python. Semua fungsi logging, reporting, dan build ada di dalam satu file.
2. **Fitur lengkap** - Sistem build mendukung:
    - Multi-platform (Linux dan Windows).
    - Multi-arsitektur (64-bit dan 32-bit).
    - Debug dan Release mode.
    - Logging ke JSON, Markdown, dan file error terpisah.
    - Rotasi log otomatis.
    - Pelaporan error compile via `atexit`.
    - Generate file `.gdextension` secara otomatis.
3. **Komentar dan dokumentasi** - `build_logic.py` memiliki banyak komentar (dalam bahasa Indonesia) untuk memudahkan pengembang memahami alur kode.

### Hubungan dengan `build_options.json`
`build_logic.py` **membaca** `build_options.json` di awal eksekusi untuk menentukan:
- Mode build (`debug`/`release`).
- Platform aktif (`linux`/`windows`).
- Jumlah pekerja paralel (`jobs`).
- Versi godot-cpp (`godot_cpp_branch` dan `godot_cpp_api_version`).

Ini memastikan bahwa build selalu menggunakan opsi terakhir yang dipilih pengguna di menu curses.

---

## 5. Alur Lengkap: Dari Menu hingga Build

Berikut adalah alur lengkap dari saat pengguna menekan `[ Generate! ]` hingga build benar-benar berjalan:

> [!info]- Alur Lengkap dari Menu hingga Build
> ```text
> 1. Pengguna memilih [ Generate! ] di menu
> 	|
> 2. confirm_generate() menampilkan ringkasan opsi
> 	|
> 3. Pengguna menekan ENTER untuk konfirmasi
> 	|
> 4. save_options(opts) → build_options.json diperbarui
> 	|
> 5. generate_files(stdscr, log_lines) dipanggil
> 	|
> 6. SConstruct ditulis dengan STUB_CONTENT
> 	|
> 7. build_logic.py ditulis dengan LOGIC_CONTENT
> 	|
> 8. Log "OK: SConstruct created!" dan "OK: build_logic.py created!"
> 	|
> 9. Kembali ke menu utama
> 	|
> 10. Pengguna keluar dari menu (Q atau [ Quit ])
>     |
> 11. Pengguna menjalankan `scons` di terminal
> 	|
> 12. SCons membaca SConstruct
>     |
> 13. exec(open("build_logic.py").read()) menjalankan build_logic.py
>     |
> 14. build_logic.py membaca build_options.json
>     |
> 15. build_logic.py mengompilasi semua source di src/**/*.cpp
>     |
> 16. Hasil compile disimpan di bin/{plat}_{bits}_{mode}/
>     |
> 17. build_logic.py generate compile.gdextension
>     |
> 18. Build selesai, log ditulis ke logs/
> ```

---

## 6. Mengapa Pengguna Tidak Boleh Mengedit `build_logic.py`?

Meskipun `build_logic.py` adalah file Python biasa yang bisa diedit dengan editor apa pun, **sangat tidak disarankan** untuk mengeditnya secara manual. Alasannya:
1. **Akan ditimpa** - Setiap kali pengguna menjalankan `[ Generate! ]` di menu, `build_logic.py` akan ditimpa dengan versi default dari bootstrapper. Semua perubahan manual akan hilang.
2. **Kompleksitas** - `build_logic.py` adalah kode yang sangat kompleks dengan banyak interaksi antar fungsi. Satu kesalahan kecil bisa menyebabkan build gagal total.
3. **Dependensi** - `build_logic.py` bergantung pada struktur tertentu di `build_options.json` dan folder proyek. Mengubah kode tanpa memahami dependensi ini bisa merusak sistem.

### Alternatif yang Lebih Aman
Jika pengguna ingin mengkustomisasi perilaku build, ada beberapa pendekatan yang lebih aman:
1. **Fork bootstrapper** - Duplikat `jalankan_bootstrapper.sh`, ubah `LOGIC_CONTENT` di dalamnya sesuai kebutuhan, lalu jalankan bootstrapper versi sendiri. Ini adalah pendekatan yang paling aman karena semua perubahan tersimpan di shell script, bukan di file yang akan ditimpa.
2. **Hook/Plugin** - Meskipun tidak diimplementasikan saat ini, sistem bisa diperluas dengan mekanisme hook di masa depan.
3. **Environment variables** - Beberapa perilaku build bisa dikontrol melalui environment variables tanpa mengubah kode.

---

## 7. Tabel Perbandingan: SConstruct vs build_logic.py

| Aspek                     | `SConstruct`                          | `build_logic.py`              |
| ------------------------- | ------------------------------------- | ----------------------------- |
| **Fungsi**                | Entry point SCons                     | Logika build lengkap          |
| **Panjang**               | ~10 baris                             | ~250 baris                    |
| **Isi**                   | `exec(open("build_logic.py").read())` | Import, logging, build engine |
| **Diedit oleh pengguna?** | Tidak                                 | Tidak (akan ditimpa)          |
| **Syntax highlighting**   | Terbatas (beberapa editor)            | Penuh (sebagai file `.py`)    |
| **Bergantung pada**       | Tidak ada                             | `build_options.json`          |
| **Dihasilkan oleh**       | `generate_files()`                    | `generate_files()`            |

---

## 8. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Opsi bits di build_options.json
> ### Opsi `bits` di `build_options.json`
> `LOGIC_CONTENT` (yang akan dibahas di Bab 13 - 15) sekarang membaca opsi `bits` dari `build_options.json` dan menggunakannya untuk:
> - Menentukan nama folder output: `bin/{plat}_{bits}_{mode}/`.
> - Menentukan argumen `arch` untuk SCons: `"x86_64"` atau `"x86_32"`.
> - Menentukan flag compiler: `-m64` atau `-m32` untuk Linux.

> [!done]- LICENSE_TEXT dan Menu Lisensi
> ### `LICENSE_TEXT` dan Menu Lisensi
> Fungsi `generate_files()` **tidak** terlibat dengan lisensi. Lisensi ditangani sepenuhnya oleh menu `[ View License ]` dan `[ Export License ]` di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]].

> [!done]- STYLE dan Event Mouse
> ### `STYLE` dan Event Mouse
> `generate_files()` tidak menggunakan `STYLE` atau event mouse – ini adalah fungsi non-visual yang hanya menulis file.

---

## 9. Kesimpulan

Pada bab ini, kita telah membahas **fungsi `generate_files()`** dan dua konstanta yang mendasarinya: `STUB_CONTENT` dan `LOGIC_CONTENT`. Kita mempelajari:
1. **`generate_files()`** - menulis ulang `SConstruct` dan `build_logic.py` di folder proyek.
2. **`STUB_CONTENT`** – file `SConstruct` yang sangat sederhana, hanya berisi `exec(open("build_logic.py").read())`.
3. **`LOGIC_CONTENT`** - string raksasa yang berisi seluruh logika build SCons (akan dibahas di Bab 13–15).
4. **Alur lengkap** - dari menu curses hingga eksekusi build oleh SCons.
5. **Peringatan** - pengguna tidak boleh mengedit `build_logic.py` secara manual karena akan ditimpa oleh bootstrapper.