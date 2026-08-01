# BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN

---

## 1. Pendahuluan: Titik Akhir Perjalanan

Setelah kita membahas seluruh komponen sistem - dari shell script bootstrapper (Bab 2 - 5), antarmuka curses (Bab 6 -12), logika build (Bab 13 -15), hingga manajemen binding godot-cpp (Bab 16) - kini tiba saatnya untuk melihat **bagaimana semua komponen ini disatukan** dan bagaimana eksekusi berakhir.

Pada Bab 17, kita akan membahas **bagian paling akhir** dari setiap komponen:
1. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#2. Akhir dari `jalankan_bootstrapper.sh` - Perintah Eksekusi Python|Akhir dari `jalankan_bootstrapper.sh` - perintah `python3 bootstrap_scons_gui.py` yang memicu seluruh antarmuka curses.]]
2. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#3. Blok `if __name__ == "__main__" ` di `bootstrap_scons_gui.py`|Blok `if __name__ == "__main__":` di `bootstrap_scons_gui.py` - entry point yang dipanggil oleh `curses.wrapper()`.]]
3. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#4. Blok `if __name__ == "__main__" ` di `setup_godot_cpp.py`|Blok `if __name__ == "__main__":` di `setup_godot_cpp.py` - entry point untuk script manajemen binding.]]
4. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#5. Penanganan Exception di `curses.wrapper()`|Penanganan Exception di `curses.wrapper()` - bagaimana error ditangani dan ditampilkan ke pengguna.]]
5. [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#6. Pesan "Press ENTER to close this window..." – Self-Relaunch Terminal|Pesan "Press ENTER to close this window..." - bagaimana terminal tetap terbuka setelah script selesai (self-relaunch dari Bab 4).]]

> [!quote] **Referensi Silang:**
> - Bab 17 adalah **penutup** dari seluruh alur eksekusi.
> - Komponen-komponen di bab ini merujuk ke [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch|Bab 4 (self-relaunch)]], [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|Bab 1 (`main()`]], dan [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT|Bab 16  (`setup_godot_cpp.py`)]].

---

## 2. Akhir dari `jalankan_bootstrapper.sh` - Perintah Eksekusi Python

*(Lokasi Baris 2154)*
```bash
python3 bootstrap_scons_gui.py
```

### Tujuan
Ini adalah **baris terakhir** dari shell script `jalankan_bootstrapper.sh`. Setelah script melakukan:
1. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION|Self-heal permission dan pembuatan `.desktop`.]]
2. [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch|Self-relaunch jika diperlukan.]]
3. Generate [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String|`bootstrap_scons_gui.py`]] dan [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#1. Pendahuluan Mengelola Binding Godot-CPP|`setup_godot_cpp.py`]].

Baris ini **menjalankan** file `bootstrap_scons_gui.py` yang baru saja digenerate. Ini adalah titik di mana:
- Kontrol berpindah dari **shell Bash** ke **Python**.
- Antarmuka curses dimulai.
- Pengguna berinteraksi dengan menu utama.

### Mengapa Menggunakan `python3`?
- **`python3`** adalah perintah standar untuk Python versi 3 di sebagian besar sistem Linux
- Beberapa sistem memiliki `python` yang merujuk ke Python 2 (sudah usang) atau Python 3 (tergantung distribusi). Dengan menggunakan `python3` secara eksplisit, kita memastikan Python 3 digunakan.
- Jika sistem tidak memiliki `python3`, perintah akan gagal - tetapi ini adalah prasyarat sistem (Bab 1).

### Apa yang Terjadi Jika `bootstrap_scons_gui.py` Tidak Ada?
Dalam kondisi normal, file ini **selalu ada** karena [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String|digenerate di awal script]]. Namun, jika terjadi error (misal `cat > bootstrap_scons_gui.py` gagal karena permission), perintah akan gagal dengan `No such file or directory`.

### Alur Lengkap dari Shell

> [!NOTE]- Alur Shell
> ```text
> jalankan_bootstrapper.sh dimulai
> 	|
> Self-heal permission & buat .desktop
> 	|
> Self-relaunch (jika diperlukan)
> 	|
> Generate bootstrap_scons_gui.py (heredoc PYEOF_INNER)
> 	|
> Generate setup_godot_cpp.py (heredoc PYEOF_SETUP)
> 	|
> python3 bootstrap_scons_gui.py ←--- KITA ADA DI SINI
> 	 |
> bootstrap_scons_gui.py berjalan (curses wrapper)
> 	|
> Menu ditampilkan, pengguna berinteraksi
> 	|
> Jika pengguna memilih Generate! → build_logic.py dan SConstruct dibuat
> 	|
> Jika pengguna memilih Setup godot-cpp → setup_godot_cpp.py dijalankan
> 	|
> Pengguna keluar dari menu (Q atau [ Quit ])
> 	|
> bootstrap_scons_gui.py selesai
> 	|
> Kembali ke shell
> 	|
> jalankan_bootstrapper.sh selesai
> ```

---

## 3. Blok `if __name__ == "__main__":` di `bootstrap_scons_gui.py`

**(Lokasi di `bootstrap_scons_gui.py`: Baris 1400–1409)**
```python
if __name__ == "__main__":
    try:
        curses.wrapper(main)
    except Exception as e:
        print(f"An error occurred: {e}")
        print("Try enlarging the terminal window then run it again.")
        raise
```

### Tujuan
Blok ini adalah **entry point** standar Python - kode di dalamnya hanya akan dijalankan jika file dieksekusi sebagai script (bukan di-import sebagai module).

###  `curses.wrapper(main)` - Menjalankan Aplikasi Curses
`curses.wrapper()` adalah fungsi utilitas dari library curses yang:
1. **Menginisialisasi** mode curses.
2. **Menangani error** - jika terjadi exception di dalam `main()`, wrapper akan mengembalikan terminal ke mode normal sebelum me-_re-raise_ exception.
3. **Membersihkan** - memastikan terminal kembali ke mode normal bahkan jika terjadi error.

```python
curses.wrapper(main)
```

Ini setara dengan:

```python
stdscr = curses.initscr()
try:
    curses.noecho()
    curses.cbreak()
    stdscr.keypad(True)
    curses.curs_set(0)
    main(stdscr)
finally:
    curses.endwin()
```

### Penanganan Exception di Luar `curses.wrapper()`

```python
try:
    curses.wrapper(main)
except Exception as e:
    print(f"An error occurred: {e}")
    print("Try enlarging the terminal window then run it again.")
    raise
```

Jika terjadi error **di dalam** `curses.wrapper()` (misal `main()` crash), wrapper akan mengembalikan terminal ke mode normal, lalu exception di-_re-raise_. Blok `try/except` di sini menangkapnya dan:
1. Mencetak pesan error yang ramah pengguna.
2. Memberikan saran: "Try enlarging the terminal window then run it again."
3. **`raise`** – me-_re-raise_ exception sehingga traceback lengkap tetap muncul (berguna untuk debugging).

### Mengapa Ada Pesan "Try enlarging the terminal window"?
Beberapa error di curses terjadi karena terminal **terlalu kecil** untuk menampilkan UI. Misal:
- `curses.error` - jika layar tidak cukup besar untuk box menu.
- `curses.newwin()` - jika dimensi window tidak valid.

Pesan ini memberikan petunjuk kepada pengguna tentang cara mengatasi error tersebut.

### Contoh Output Error

Jika terjadi error (misal terminal terlalu kecil):

```text
An error occurred: (curses.error) addstr() returned ERR
Try enlarging the terminal window then run it again.
Traceback (most recent call last):
  File "bootstrap_scons_gui.py", line 1405, in <module>
    curses.wrapper(main)
  File "/usr/lib/python3.10/curses/__init__.py", line 94, in wrapper
    return func(stdscr, *args, **kwds)
  ...
curses.error: addstr() returned ERR
```

---

## 4. Blok `if __name__ == "__main__":` di `setup_godot_cpp.py`

**(Lokasi di `PYEOF_SETUP`: Baris 220–222)**
```python
if __name__ == "__main__":
    main()
```

### Tujuan
Sama seperti di `bootstrap_scons_gui.py`, blok ini adalah entry point untuk `setup_godot_cpp.py`. Ketika script dijalankan (`python3 setup_godot_cpp.py` atau melalui menu curses), fungsi `main()` akan dipanggil.

### Perbedaan dengan `bootstrap_scons_gui.py`
Berbeda dengan `bootstrap_scons_gui.py` yang menggunakan `curses.wrapper()`, `setup_godot_cpp.py` adalah **script terminal biasa** (non-curses). Karena itu:
- Tidak ada inisialisasi curses.
- Output langsung ke `stdout` (yang akan tertangkap oleh `run_subprocess_in_curses()` di Bab 10).
- Error ditangani dengan `sys.exit(1)` di `jalankan()`.

### Bagaimana `setup_godot_cpp.py` Dipanggil dari Menu Curses?

*(Lokasi Bariss 1770)*
```python
run_subprocess_in_curses(stdscr, [sys.executable, "setup_godot_cpp.py"], "SETUP GODOT-CPP", env=env)
```

Di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `setup` - Setup godot-cpp|menu curses]], `setup_godot_cpp.py` dijalankan sebagai **subprocess** dengan:
- `stdout` dan `stderr` ditangkap dan ditampilkan live di layar curses.
- Environment variable `KOBI_NONINTERAKTIF=1` dan `KOBI_REDOWNLOAD=0/1` diatur untuk mode non-interaktif.

---

## 5. Penanganan Exception di `curses.wrapper()`

### Bagaimana `curses.wrapper()` Bekerja?

`curses.wrapper()` adalah **fungsi yang sangat robust**. Ia melakukan:
```python
def wrapper(func, *args, **kwds):
    try:
        stdscr = curses.initscr()
        curses.noecho()
        curses.cbreak()
        stdscr.keypad(True)
        curses.curs_set(0)
        try:
            return func(stdscr, *args, **kwds)
        finally:
            stdscr.keypad(False)
            curses.nocbreak()
            curses.echo()
            curses.endwin()
    except Exception:
        try:
            curses.endwin()
        except:
            pass
        raise
```

### Lapisan Perlindungan

|Lapisan|Fungsi|
|---|---|
|**Inisialisasi**|`initscr()`, `noecho()`, `cbreak()`, `keypad()`, `curs_set()`|
|**Eksekusi**|Panggil `func(stdscr, *args, **kwds)`|
|**Cleanup normal**|`keypad(False)`, `nocbreak()`, `echo()`, `endwin()`|
|**Cleanup error**|Jika exception, tetap panggil `endwin()` untuk mengembalikan terminal normal|

### Mengapa Ini Penting?
Tanpa `curses.wrapper()`, jika terjadi error di dalam `main()`:
- Terminal akan tetap dalam **mode raw** (tanpa echo, tanpa buffering).
- Pengguna mungkin tidak bisa melihat apa yang mereka ketik.
- Tombol seperti Enter dan Backspace mungkin tidak berfungsi normal.

Dengan `curses.wrapper()`, terminal selalu dikembalikan ke mode normal, bahkan jika terjadi error.

### Exception yang Mungkin Terjadi

|Exception|Penyebab|Solusi|
|---|---|---|
|`curses.error`|Terminal terlalu kecil, atau operasi curses gagal|Perbesar terminal|
|`ImportError`|Library curses tidak tersedia|Install package `python3-curses`|
|`AttributeError`|Fungsi tidak ditemukan di modul|Periksa versi Python|
|`KeyboardInterrupt`|Pengguna menekan Ctrl+C|Tidak ada (keluar normal)|

---

## 6. Pesan "Press ENTER to close this window..." - Self-Relaunch Terminal

**(Lokasi di `bootstrap_scons_gui.py`: Baris 131–136, di dalam self-relaunch Python)**
```python
perintah_dalam = (
    f'python3 "{path_file}"; echo; read -p "Press ENTER to close this window..."'
)
```

### Tujuan
Pesan ini muncul ketika `bootstrap_scons_gui.py` dijalankan **tanpa terminal** (misal diklik dari file manager) dan self-relaunch Python ==(Bab 6)== membuka terminal baru.

### Mengapa Perlu "Press ENTER to close"?
Jika terminal dibuka untuk menjalankan script dan script selesai, terminal akan **langsung tertutup** - pengguna tidak sempat membaca output atau pesan error. Dengan menambahkan `read -p "Press ENTER..."` di akhir perintah, terminal tetap terbuka sampai pengguna menekan ENTER.

### Cara Kerja

```bash
python3 "path_file"; echo; read -p "Press ENTER to close this window..."
```

- **`python3 "path_file"`** - jalankan `bootstrap_scons_gui.py`.
- **`;`** - setelah script selesai (atau crash), lanjutkan ke perintah berikutnya.
- **`echo`** - cetak baris kosong (spasi visual).
- **`read -p "Press ENTER to close this window..."`** - tunggu input ENTER dari pengguna.

### Kaitan dengan BAB 4
Di Bab 4, shell script `jalankan_bootstrapper.sh` melakukan self-relaunch dengan mekanisme yang serupa:

```bash
perintah_dalam = (
    f'python3 "{path_file}"; echo; read -p "Press ENTER to close this window..."'
)
```

Namun, di [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch|Bab 4]], self-relaunch terjadi di **level Bash**, sedangkan di ==Bab 6==, self-relaunch terjadi di **level Python**. Keduanya menggunakan mekanisme `read -p` yang sama untuk menjaga terminal tetap terbuka.

### Kandidat Terminal dan Parameter
Berbagai terminal emulator memiliki parameter berbeda untuk menjalankan perintah:

|Terminal|Parameter|Contoh|
|---|---|---|
|`gnome-terminal`|`-- bash -c "cmd"`|`gnome-terminal -- bash -c "python3 script.py; read"`|
|`konsole`|`-e bash -c "cmd"`|`konsole -e bash -c "python3 script.py; read"`|
|`xfce4-terminal`|`-e "bash -c 'cmd'"`|`xfce4-terminal -e "bash -c 'python3 script.py; read'"`|
|`xterm`|`-e "bash -c 'cmd'"`|`xterm -e "bash -c 'python3 script.py; read'"`|

---

## 7. Alur Lengkap dari Awal hingga Akhir
Berikut adalah alur lengkap seluruh sistem, dari pengguna mengklik `jalankan_bootstrapper.sh` hingga build selesai:

### Tahap 1: Shell Bootstrapper

> [!Info]- Shell Bootstrapper
> ```text
> 1. Pengguna mengklik jalankan_bootstrapper.sh (atau menjalankannya di terminal)
>    |
> 2. Shebang #!/bin/bash → dieksekusi oleh Bash
>    |
> 3. cd "$(dirname "$0")" → pindah ke folder script
>    |
> 4. Self-heal permission dan buat .desktop (Bab 3)
>    |
> 5. Self-relaunch Bash (Bab 4) – jika tidak ada terminal interaktif, buka terminal baru
>    |
> 6. Generate bootstrap_scons_gui.py (Bab 5) dan setup_godot_cpp.py (Bab 16)
>    |
> 7. python3 bootstrap_scons_gui.py → pindah ke Python
> ```

### Tahap 2: Bootstrap GUI (Curses)

> [!info]- Bootstrap GUI (Curses)
> ```text
> 1. bootstrap_scons_gui.py dimulai
> 	|
> 2. Self-relaunch Python (Bab 6) – jika tidak ada terminal interaktif, buka terminal baru
> 	|
> 3. curses.wrapper(main) → inisialisasi curses
> 	|
> 4. Inisialisasi warna dan mouse event (Bab 11)
> 	|
> 5. Dialog awal: tanya_dan_pindah_folder_proyek() (Bab 10)
> 	|
> 6. Load opsi dari build_options.json (Bab 8)
> 	|
> 7. Loop utama menu (Bab 11):
>     a. Render menu dengan render_menu() (Bab 10)
>     b. Tunggu input keyboard
>     c. Proses navigasi (↑/↓, ←/→, ENTER/SPACE)
>     d. Eksekusi aksi (setup, generate, dll)
> 	|
> 8. Pengguna memilih [ Generate! ]:
>     a. confirm_generate() (Bab 10)
>     b. save_options() (Bab 8)
>     c. generate_files() → buat SConstruct dan build_logic.py (Bab 12)
> 	|
> 9. Pengguna memilih [ Setup godot-cpp ]:
>     a. save_options() (Bab 8)
>     b. run_subprocess_in_curses() → jalankan setup_godot_cpp.py (Bab 10)
>     |
>     setup_godot_cpp.py (Bab 16):
>     - Baca build_options.json
>     - Clone godot-cpp (jika perlu)
>     - Compile godot-cpp untuk Linux dan Windows
>     |
> 10. Pengguna keluar dengan Q atau [ Quit ]
> 	|
> 11. curses.endwin() → keluar dari mode curses
> 	|
> 12. Kembali ke shell
> ```

### Tahap 3: Build dengan SCons

> [!info]- Build dengan SCons
> ```text
> 1. Pengguna menjalankan perintah scons di terminal
> 	|
> 2. SCons membaca SConstruct (Bab 12)
> 	|
> 3. SConstruct menjalankan exec(open("build_logic.py").read())
> 	|
> 4. build_logic.py dimulai (Bab 13–15):
>      a. Prolog: import, Terminal wrapper, ColorMagic (Bab 13)
>      b. Baca build_options.json (Bab 13)
>      c. Definisikan fungsi logging (Bab 14)
>      d. build_with_logging() (Bab 15):
>         - Auto-create folder
>         - Untuk setiap platform:
>           - Konfigurasi environment
>           - Mapping sumber
>           - env.SharedLibrary()
>           - AddPostAction()
>      e. Default(libs) dan generate_gdextension()
> 	|
> 5. SCons mengeksekusi build
> 	|
> 6. Jika sukses > post-action memanggil write_logs() > log ditulis (Bab 14)
> 	|
> 7. Jika gagal > atexit memanggil report_build_failures() > log ditulis (Bab 14)
> 	|
> 8. Selesai. File output di bin/ dan log di logs/
> ```

---

## 8. Tabel Rangkuman Entry Points

|Komponen|Entry Point|Lokasi|Dipanggil Oleh|
|---|---|---|---|
|`jalankan_bootstrapper.sh`|Shebang `#!/bin/bash`|Baris 1|User (klik/terminal)|
|`bootstrap_scons_gui.py`|`if __name__ == "__main__"`|Baris 1400|`jalankan_bootstrapper.sh` (baris 143)|
|`main(stdscr)`|`curses.wrapper(main)`|Baris 1405|`if __name__ == "__main__"`|
|`setup_godot_cpp.py`|`if __name__ == "__main__"`|Baris 220|`run_subprocess_in_curses()` (menu) atau manual|
|`SConstruct`|`exec(open("build_logic.py").read())`|`STUB_CONTENT`|SCons (perintah `scons`)|
|`build_logic.py`|(Top-level code)|`LOGIC_CONTENT`|`SConstruct` (via `exec()`)|

---

## 9. Keterkaitan dengan Fitur Baru v2.4.0

### Penanganan Exception dengan Pesan yang Lebih Baik
Di v2.4.0, pesan error di `curses.wrapper()` memberikan saran yang lebih spesifik: "Try enlarging the terminal window then run it again." Ini membantu pengguna yang mungkin bingung dengan error `curses.error` yang tidak informatif.

### `BOOTSTRAPPER_VERSION` di CREDITS
Meskipun tidak langsung terkait dengan eksekusi akhir, `BOOTSTRAPPER_VERSION = "2.4.0"` (Bab 9) muncul di `CREDITS_LINES`, memberikan informasi versi kepada pengguna.

### Self-Relaunch dengan `read -p`
Mekanisme `read -p "Press ENTER..."` tetap sama di v2.4.0, tetapi sekarang **konsisten** antara Bash (Bab 4) dan Python (Bab 6) – keduanya menggunakan mekanisme yang sama untuk menjaga terminal tetap terbuka.

---

## 10. Troubleshooting Umum

|Masalah|Penyebab|Solusi|
|---|---|---|
|`python3: command not found`|Python 3 tidak terinstall|`sudo apt install python3`|
|`curses.error: addstr() returned ERR`|Terminal terlalu kecil|Perbesar terminal (minimal 80x24)|
|`ImportError: No module named curses`|Library curses tidak terinstall|`sudo apt install python3-curses`|
|`git: command not found`|Git tidak terinstall|`sudo apt install git`|
|`scons: command not found`|SCons tidak terinstall|`sudo apt install scons` atau `pip install scons`|
|`x86_64-w64-mingw32-g++: command not found`|Mingw tidak terinstall|`sudo apt install mingw-w64`|
|`i686-w64-mingw32-g++: command not found`|Mingw 32-bit tidak terinstall|`sudo apt install mingw-w64-i686-dev g++-mingw-w64-i686`|
|Permission denied saat menjalankan `.sh`|File tidak executable|`chmod +x jalankan_bootstrapper.sh`|

---

## 11. Kesimpulan

Pada bab terakhir ini, kita telah membahas **bagian penutup** dari seluruh sistem - bagaimana eksekusi dimulai dari shell, berpindah ke Python, dan berakhir dengan build yang dijalankan oleh SCons. Kita mempelajari:
1. **Akhir dari `jalankan_bootstrapper.sh`** - perintah `python3 bootstrap_scons_gui.py` yang mengalihkan kontrol ke Python.
2. **Blok `if __name__ == "__main__":` di `bootstrap_scons_gui.py`** - entry point yang menggunakan `curses.wrapper(main)` untuk menjalankan aplikasi curses.
3. **Blok `if __name__ == "__main__":` di `setup_godot_cpp.py`** - entry point sederhana untuk script manajemen binding.
4. **Penanganan exception di `curses.wrapper()`** - bagaimana terminal dikembalikan ke mode normal bahkan jika terjadi error.
5. **Pesan "Press ENTER to close this window..."** - mekanisme self-relaunch yang menjaga terminal tetap terbuka setelah script selesai.
6. **Alur lengkap** - dari klik `jalankan_bootstrapper.sh` hingga build selesai.
7. **Troubleshooting umum** - solusi untuk masalah yang paling sering terjadi.