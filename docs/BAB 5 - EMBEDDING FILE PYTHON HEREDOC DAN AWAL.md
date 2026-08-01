# BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL
## 1. Pendahuluan: Dari Shell ke Python - Lahirnya Antarmuka

Setelah kita memahami bagaimana script melakukan [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#6. `chmod +x "$SCRIPT_ABS"` - Self-Heal Permission pada Shell|self-heal permission]] dan [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)|self-relaunch di level Bash]], kini tiba saatnya untuk membahas **transisi besar** dari shell script ke Python. Di sinilah `jalankan_bootstrapper.sh` mulai menulis file-file Python yang akan menjadi antarmuka utama dan logika build sistem.

Pada Bab 5, kita akan membahas:
1. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String|Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - mekanisme embedding string raksasa di dalam shell script.]]
2. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#4. Shebang ` !/usr/bin/env python3` - Penanda Interpreter Python|Shebang `#!/usr/bin/env python3` - penanda interpreter Python untuk file yang digenerate.]]
3. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#5. Docstring Awal Sejarah Migrasi dari Tkinter ke Curses|Docstring awal - sejarah migrasi dari Tkinter ke Curses, dan penjelasan tentang mengapa Curses dipilih.]]
4. [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#6. Daftar Import Library - Fondasi Fungsionalitas Python|Daftar import library eksplisit - semua library Python yang digunakan di `bootstrap_scons_gui.py`.]]

Ini adalah **bab pertama dari dua bab** yang membahas embedding file Python. Bab ini fokus pada `bootstrap_scons_gui.py` (antarmuka curses), sementara [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT|`setup_godot_cpp.py` akan dibahas di Bab 16]].

> [!quote] **Referensi Silang:**
> - Heredoc di sini adalah implementasi dari filosofi **self-contained** yang dijelaskan di Bab 1.
> - [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#2. Akhir dari `jalankan_bootstrapper.sh` - Perintah Eksekusi Python|`bootstrap_scons_gui.py` yang digenerate di sini akan dijalankan di Baris 79.]]
> - File `setup_godot_cpp.py` juga digenerate dengan mekanisme heredoc serupa di bagian akhir script (Bab 16).

---

## 2. Blok Komentar tentang Mode Proyek Baru

*(Lokasi Baris 72 - 77*
```bash
# ============================================================
# MODE PROYEK BARU: pertanyaan ini sekarang ditanya DI DALAM sesi
# curses yang sama dengan menu utama (bukan proses python terpisah),
# biar gak ada transisi keluar-masuk curses yang bikin kelip-kelip
# pas pertama dibuka. Logic lengkapnya ada di bootstrap_scons_gui.py.
# ============================================================
```

### Tujuan

Komentar ini menjelaskan **keputusan desain** tentang di mana dialog "Buat folder proyek baru?" akan ditampilkan. Sebelumnya, dialog ini mungkin ditanyakan di level shell (sebelum Python dijalankan), yang menyebabkan transisi keluar-masuk curses dan tampilan yang "kelip-kelip".

Dengan memindahkan dialog ini ke dalam **sesi curses yang sama** dengan menu utama, pengalaman pengguna menjadi lebih mulus:
- Tidak ada jeda atau transisi yang mengganggu.
- Dialog muncul dengan gaya yang konsisten dengan menu utama.
- Semua interaksi terjadi di satu lingkungan yang sama.

### Kaitan dengan Bab 10
Dialog "Buat folder proyek baru?" diimplementasikan di fungsi [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#11. Fungsi `tanya_dan_pindah_folder_proyek()` - Dialog Awal Pembuatan Proyek|`tanya_dan_pindah_folder_proyek()`]], yang dipanggil di awal [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]]. Ini memastikan bahwa dialog muncul **sebelum** menu utama dirender, tetapi **masih dalam sesi curses yang sama**.

---

## 3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String

*(Lokasi Baris 79 - 92)*
```bashbash
cat > bootstrap_scons_gui.py << 'PYEOF_INNER'
#!/usr/bin/env python3
"""

bootstrap_scons_gui.py   <-- VERSI CURSES (UI di terminal, TANPA perlu install apapun)
-----------------------
...
"""
```

### Tujuan
Heredoc ini menulis seluruh konten `bootstrap_scons_gui.py` ke disk. Ini adalah **implementasi inti** dari [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#3. Filosofi Desain Self-Contained, Regeneratif, dan Terminal-First|filosofi self-contained]] - semua kode Python di-_embed_ di dalam shell script sebagai string literal.

### Perbedaan Heredoc dengan dan tanpa Tanda Kutip

*(Lokasi Baris 79)*
```bash
cat > file_name.py << 'PYEOF_INNER'
```

### Isi file (tidak ada ekspansi variabel)

*(Lokasi Baris 79)*
```bash
PYEOF_INNER
```

Penggunaan **tanda kutip** di delimiter (`<< 'PYEOF_INNER'`) sangat penting karena:

- **Dengan tanda kutip** (`'PYEOF_INNER'`) – semua isi heredoc diperlakukan sebagai **literal string**. Variabel shell (seperti `$SCRIPT_ABS`) **tidak** diekspansi. Ini penting karena file Python mengandung banyak `$` (misal dalam string) yang tidak boleh diekspansi oleh shell.
- **Tanpa tanda kutip** (`<< PYEOF_INNER`) – variabel shell akan diekspansi, yang bisa merusak kode Python.

### Mengapa Menggunakan `cat >`?

*(Lokasi Baris 79)*
```bash
cat > bootstrap_scons_gui.py << 'PYEOF_INNER'
```

- **`cat`** - perintah untuk menggabungkan dan menampilkan file.
- **`>`** - redirect output ke file (menimpa jika sudah ada).
- **`bootstrap_scons_gui.py`** - nama file yang akan ditulis.
- **`<< 'PYEOF_INNER'`** - heredoc dengan delimiter `PYEOF_INNER`.

Ini setara dengan "tulis semua teks dari heredoc ke file `bootstrap_scons_gui.py`".

### Ukuran Heredoc
`bootstrap_scons_gui.py` memiliki panjang sekitar **1400 baris** (termasuk semua fungsi, menu, dan logika curses). Ini adalah string literal yang sangat besar yang di-_embed_ di dalam shell script. Meskipun terlihat tidak elegan, ini adalah cara paling sederhana untuk membuat sistem **self-contained** tanpa memerlukan file eksternal.

---

## 4. Shebang `#!/usr/bin/env python3` - Penanda Interpreter Python

*(Lokasi Baris 80)*
```python
#!/usr/bin/env python3
```

### Tujuan
Shebang ini adalah **penanda interpreter** untuk file Python yang digenerate. Ketika pengguna menjalankan `./bootstrap_scons_gui.py` (atau sistem menjalankannya melalui `python3 bootstrap_scons_gui.py`), baris ini memastikan bahwa file dieksekusi dengan Python 3.

### Mengapa `#!/usr/bin/env python3` dan Bukan `#!/usr/bin/python3`?
- **`#!/usr/bin/env python3`** - mencari `python3` di `PATH` pengguna. Ini lebih portabel karena:
    - Di beberapa sistem, `python3` mungkin terinstall di `/usr/local/bin/python3` atau lokasi lain.
    - `env` menemukan lokasi yang tepat berdasarkan `PATH` pengguna.
- **`#!/usr/bin/python3`** - hard-code path ke `/usr/bin/python3`. Ini bisa gagal di sistem di mana Python 3 terinstall di lokasi berbeda.

### Kapan Shebang Ini Digunakan?
Shebang ini digunakan jika pengguna menjalankan `bootstrap_scons_gui.py` secara langsung (misal `./bootstrap_scons_gui.py`). Namun, dalam alur normal, file ini dijalankan oleh shell script dengan [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#2. Akhir dari `jalankan_bootstrapper.sh` - Perintah Eksekusi Python|`python3 bootstrap_scons_gui.py`]], sehingga shebang tidak selalu diperlukan. Namun, tetap disertakan untuk **portabilitas** dan **kemudahan debugging**.

---

## 5. Docstring Awal: Sejarah Migrasi dari Tkinter ke Curses

*(Lokasi Baris 81 - 92)*
```pythonpython
"""
bootstrap_scons_gui.py   <-- VERSI CURSES (UI di terminal, TANPA perlu install apapun)
-----------------------
Awalnya pakai tkinter, tapi diganti ke curses karena tkinter butuh install
tambahan (python3-tk) yang butuh sudo. curses itu BAWAAN Python di Linux,
jadi langsung jalan tanpa install apa-apa lagi.
Jalanin: python3 bootstrap_scons_gui.py
Tampilannya kotak UI di terminal (bukan jendela pop-up beneran), ada tombol
yang dipencet pakai ENTER, bukan klik mouse.
>>> Kalau mau versi command-line polos (tanpa UI sama sekali), pakai bootstrap_scons_TERMINAL.py. <<<
"""
```

### Tujuan
Docstring ini memberikan **penjelasan singkat** tentang:
1. **Apa itu file ini** - versi curses dari bootstrapper GUI.
2. **Mengapa menggunakan curses** - karena tkinter memerlukan install tambahan (`python3-tk`) yang membutuhkan `sudo`.
3. **Bagaimana menjalankannya** - `python3 bootstrap_scons_gui.py`.
4. **Bagaimana interaksinya** - menggunakan keyboard (ENTER), bukan mouse.
5. **Alternatif** - ada versi command-line polos (`bootstrap_scons_TERMINAL.py`) untuk pengguna yang lebih suka tanpa UI.

### Mengapa Tkinter Ditinggalkan?

|Aspek|Tkinter|Curses|
|---|---|---|
|**Instalasi**|Perlu `sudo apt install python3-tk`|Bawaan Python (tidak perlu install)|
|**UI**|Jendela GUI terpisah|Di dalam terminal|
|**Interaksi**|Mouse + keyboard|Keyboard saja (ENTER)|
|**Portabilitas**|Bergantung pada sistem windowing|Bekerja di semua terminal|
|**Kebutuhan**|Pengguna harus memiliki GUI|Hanya perlu terminal|

Keputusan untuk menggunakan **curses** didasarkan pada:
1. **Tidak perlu `sudo`** - pengguna tidak perlu hak administrator untuk menginstall dependensi tambahan.
2. **Bekerja di semua sistem** - selama ada terminal, curses berfungsi (termasuk melalui SSH)
3. **Pengalaman yang konsisten** - antarmuka di terminal terasa lebih "teknis" dan sesuai dengan filosofi sistem.

### Catatan tentang `bootstrap_scons_TERMINAL.py`
Docstring menyebutkan versi command-line polos (`bootstrap_scons_TERMINAL.py`) yang **tidak ada** di dalam heredoc ini. Ini adalah **fitur yang direncanakan** tetapi belum diimplementasikan – atau mungkin hanya disebutkan sebagai ide untuk masa depan. Dalam praktiknya, file ini tidak digenerate oleh bootstrapper.

---

## 6. Daftar Import Library - Fondasi Fungsionalitas Python

*(Lokasi Baris 94 - 102)*
```python
import os
import sys
import shutil
import subprocess
import curses
import json
import glob
import datetime
import time
```

### Tujuan
Blok import ini adalah **fondasi** dari seluruh fungsionalitas `bootstrap_scons_gui.py`. Setiap library memiliki peran spesifik dalam sistem:

### Tabel Peran Library

|Library|Fungsi dalam `bootstrap_scons_gui.py`|Contoh Penggunaan|
|---|---|---|
|`os`|Operasi sistem file dan path|`os.path.exists()`, `os.makedirs()`, `os.chdir()`, `os.environ`|
|`sys`|Manipulasi interpreter Python|`sys.stdin.isatty()`, `sys.exit()`, `sys.executable`|
|`shutil`|Operasi file tingkat tinggi|`shutil.move()`, `shutil.rmtree()`, `shutil.copy2()`|
|`subprocess`|Menjalankan proses eksternal|`subprocess.Popen()`, `subprocess.run()`|
|`curses`|Antarmuka terminal (UI)|`curses.wrapper()`, `stdscr.addstr()`, `stdscr.getch()`|
|`json`|Membaca/menulis file JSON|`json.load()`, `json.dump()` (untuk `build_options.json`)|
|`glob`|Pencarian file dengan pattern|`glob.glob("godot-cpp-*")` (untuk scan versi)|
|`datetime`|Manipulasi tanggal dan waktu|`datetime.datetime.now().strftime()` (untuk timestamp log)|
|`time`|Pengukuran waktu dan sleep|`time.time()`, `time.sleep()` (untuk timer dialog)|

### Mengapa Tidak Ada Library Pihak Ketiga?

Semua library yang digunakan adalah **bagian dari standard library Python**. Ini adalah keputusan desain yang penting karena:
1. **Tidak perlu `pip install`** - pengguna tidak perlu menginstall dependensi tambahan.
2. **Portabilitas** - library standard tersedia di semua instalasi Python 3.
3. **Keamanan** - tidak ada risiko dari library pihak ketiga yang tidak terpercaya.

### Mengapa `curses` Bisa Digunakan Tanpa Install?
`curses` adalah bagian dari **standard library Python di Linux**. Meskipun di Windows, `curses` tidak tersedia secara default, target sistem build KOBI adalah **Linux**, sehingga ini bukan masalah. Pada distribusi Linux minimalis, library `curses` mungkin perlu diinstall dengan `sudo apt install python3-curses`, tetapi ini jarang terjadi.

---

## 7. Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE` - Pengantar

*(Lokasi Baris 104 - 119)*
```python
BOOTSTRAPPER_VERSION = "2.4.0"
STYLE = {
    "title": curses.A_BOLD | curses.A_UNDERLINE,
    "section": curses.A_BOLD,
    "selected": curses.A_REVERSE,
    "active": curses.A_BOLD,
    "inactive": curses.A_DIM,
    "accent": curses.A_BOLD,
    "dim": curses.A_DIM,
    "normal": curses.A_NORMAL,
}
```

### Tujuan
Dua konstanta ini didefinisikan **segera setelah di import**:
1. **`BOOTSTRAPPER_VERSION`** - versi sistem build [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim|(digunakan di `CREDITS_LINES` di Bab 9)]].
2. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2|`STYLE` - dictionary yang mendefinisikan atribut tampilan untuk berbagai elemen UI di curses.]]

### Mengapa `STYLE` Didefinisikan di Awal?
`STYLE` didefinisikan di awal file karena:
1. **Digunakan di banyak fungsi** - `render_menu()`, `show_message_dialog()`, `show_scrollable_dialog()`, dll.
2. **Memudahkan kustomisasi** - semua style terkonsentrasi di satu tempat.
3. **Fallback** - jika terminal tidak mendukung warna, style ini tetap memberikan atribut dasar (bold, dim, reverse).

### Atribut Curses yang Digunakan

|Key|Atribut|Efek Visual|
|---|---|---|
|`title`|`A_BOLD \| A_UNDERLINE`|Tebal + garis bawah|
|`section`|`A_BOLD`|Tebal|
|`selected`|`A_REVERSE`|Reverse video (highlight)|
|`active`|`A_BOLD`|Tebal|
|`inactive`|`A_DIM`|Redup|
|`accent`|`A_BOLD`|Tebal|
|`dim`|`A_DIM`|Redup|
|`normal`|`A_NORMAL`|Normal (default)|

> [!note] **Catatan:** 
> Di ==**Bab 11**==, `STYLE` akan diperbarui dengan warna (`curses.color_pair()`) jika terminal mendukung warna. Namun, nilai default ini memastikan bahwa UI tetap berfungsi bahkan di terminal tanpa warna.

---

## 8. Blok Self-Relaunch Python - Pengantar

*(Lokasi Baris 127 - 142)*
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
    ...
```

### Tujuan
Blok ini adalah **self-relaunch di level Python** – mekanisme yang identik dengan yang ada di level Bash (Bab 4), tetapi diimplementasikan di Python. Ini adalah **lapisan kedua** dari sistem self-relaunch:

1. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#|Lapisan 1 (Bash) - jika script shell dijalankan tanpa terminal.]]
2. **Lapisan 2 (Python)** - jika `bootstrap_scons_gui.py` dijalankan tanpa terminal (misal dari cron atau IDE).

### Perbedaan Utama dengan Self-Relaunch Bash

|Aspek|Self-Relaunch Bash|Self-Relaunch Python|
|---|---|---|
|**Deteksi**|`[ ! -t 0 ]`|`not sys.stdin.isatty()`|
|**Perintah di terminal**|`bash "$SCRIPT_PATH"`|`python3 "{path_file}"; echo; read -p "Press ENTER..."`|
|**Menjaga terminal terbuka**|Tidak (terminal akan tutup setelah script selesai)|`read -p "Press ENTER..."` menjaga terminal tetap terbuka|
|**Parameter terminal**|`--`, `-e`, `-x`|Sama, tetapi dengan `bash -c` sebagai wrapper|

### Mengapa Ada `read -p "Press ENTER..."`?
Di self-relaunch Bash (Bab 4), terminal akan langsung tertutup setelah script selesai (atau crash) karena tidak ada perintah yang menahan terminal. Di Python, kita menambahkan `read -p "Press ENTER..."` untuk:
1. **Menjaga terminal tetap terbuka** - pengguna bisa membaca pesan error jika script gagal.
2. **Memberi kontrol kepada pengguna** - pengguna menekan ENTER untuk menutup terminal secara sadar.

### Perbedaan Parameter di Daftar Kandidat
Perhatikan bahwa di Python, ada **dua gaya** parameter:

```python
("gnome-terminal", ["gnome-terminal", "--", "bash", "-c", perintah_dalam]),
("konsole", ["konsole", "-e", "bash", "-c", perintah_dalam]),
("xfce4-terminal", ["xfce4-terminal", "-e", f"bash -c '{perintah_dalam}'"]),
```

- **`gnome-terminal`** - menggunakan `--` untuk memisahkan opsi.
- **`konsole`** - menggunakan `-e` dengan argumen langsung.
- **`xfce4-terminal`** - menggunakan `-e` tetapi dengan string yang di-quote (`'...'`) karena `xfce4-terminal` memerlukan perintah sebagai satu argumen.

Ini adalah **detail implementasi** yang memastikan kompatibilitas dengan berbagai terminal emulator.

---

## 9. Tabel Rangkuman

| Komponen               | Lokasi di `jalankan_bootstrapper.sh` | Lokasi di `bootstrap_scons_gui.py` | Fungsi                                                                            |
| ---------------------- | ------------------------------------ | ---------------------------------- | --------------------------------------------------------------------------------- |
| Heredoc PYEOF_INNER    | Baris 35 - 44                        | Baris 79                           | Menulis `bootstrap_scons_gui.py` ke disk                                          |
| Shebang                | Baris 1                              | Baris 80                           | `#!/usr/bin/env python3` – interpreter Python                                     |
| Docstring              | N/A                                  | Baris 81 - 92                      | Sejarah migrasi Tkinter → Curses                                                  |
| Import library         | N/A                                  | Baris 94 -102                      | `os`, `sys`, `shutil`, `subprocess`, `curses`, `json`, `glob`, `datetime`, `time` |
| `BOOTSTRAPPER_VERSION` | N/A                                  | Baris 104                          | Versi sistem build (`"2.4.0"`)                                                    |
| `STYLE` dict           | N/A                                  | Baris 105 -119                     | Atribut tampilan UI curses                                                        |
| Self-relaunch Python   | N/A                                  | Baris 127 - 142                    | Deteksi terminal non-interaktif dan relaunch                                      |

---

## 10. Keterkaitan dengan Bab Lain

| Konsep di Bab 5        | Terkait dengan Bab                                                                                                                                                                                |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Heredoc embedding      | [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#3. Filosofi Desain Self-Contained, Regeneratif, dan Terminal-First\|Bab 1 (Filosofi self-contained)]]                                                   |
| Self-relaunch Python   | [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)\|Bab 4 (Self-relaunch Bash) - mekanisme serupa, lapisan kedua]]                                                                          |
| `STYLE` dict           | [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama\|Bab 10 (Render menu) - digunakan di `render_menu()` dan dialog]] |
| `BOOTSTRAPPER_VERSION` | [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim\|Bab 9 (CREDITS_LINES) - ditampilkan di menu Credits]]                 |
| Import `curses`        | Bab 10 - 11 (Semua fungsi UI)                                                                                                                                                                     |
| Import `json`          | [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)\|Bab 8 (Manajemen `build_options.json`)]]                                                                                    |
| Import `glob`          | [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)\|Bab 7 (Scan folder godot-cpp)]]                                                                                           |

---

## 11. Kesimpulan

Pada bab ini, kita telah membahas **awal dari `bootstrap_scons_gui.py`** – bagaimana file ini digenerate dari heredoc di shell script, dan bagaimana ia dimulai dengan shebang, docstring, import library, dan konstanta awal. Kita mempelajari:
1. **Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'`** - mekanisme embedding file Python di dalam shell script.    
2. **Shebang `#!/usr/bin/env python3`** - memastikan file dijalankan dengan Python 3.
3. **Docstring** – sejarah migrasi dari Tkinter ke Curses, dan penjelasan tentang mengapa Curses dipilih (tidak perlu install tambahan).
4. **Daftar import library** - `os`, `sys`, `shutil`, `subprocess`, `curses`, `json`, `glob`, `datetime`, `time`- semua dari standard library Python.
5. **Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE`** - versi sistem dan style UI curses.
6. **Self-relaunch Python** - mekanisme yang identik dengan Bab 4, tetapi diimplementasikan di Python untuk menangani skenario di mana `bootstrap_scons_gui.py` dijalankan tanpa terminal.