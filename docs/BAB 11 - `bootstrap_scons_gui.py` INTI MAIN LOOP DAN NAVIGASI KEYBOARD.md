# BAB 11 - `bootstrap_scons_gui.py`: INTI MAIN LOOP DAN NAVIGASI KEYBOARD

---

## 1. Pendahuluan: Pusat Kendali Aplikasi

Setelah kita memahami fungsi-fungsi [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#1. Pendahuluan Mengapa Utility Functions Penting?|utility]], [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#1. Pendahuluan Inti Konfigurasi Build|manajemen opsi]],[[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#1. Pendahuluan Data Statis sebagai Tulang Punggung UI| konstanta data statis]], dan seluruh [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#1. Pendahuluan Antarmuka Pengguna di Dunia Terminal|lapisan render/dialog]], kini tiba saatnya untuk menyatukan semuanya dalam **fungsi utama** `main(stdscr)` – jantung dari seluruh aplikasi curses. Di sinilah semua komponen berinteraksi, navigasi keyboard diproses, dan aksi-aksi menu dieksekusi.

Pada Bab 11, kita akan membahas:
1. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|Fungsi `main(stdscr)` - entry point yang dipanggil oleh `curses.wrapper()`.]]
2.  [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Inisialisasi Warna (v2.4.0)|Inisialisasi warna - `curses.start_color()`, `curses.init_pair()`, dan update `STYLE` dict.]]
3. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Event Mouse (v2.4.0)|Event mouse - `curses.mousemask()` untuk menangani scroll wheel.]]
4. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Stabilisasi Terminal (v2.4.0)|Stabilisasi terminal - `curses.napms(150)` untuk memastikan ukuran terminal sudah stabil.]]
5. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Dialog Awal|Dialog awal - pemanggilan `tanya_dan_pindah_folder_proyek()`.]]
6. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#^ec41d2|Loop utama - infinite loop yang merender menu dan memproses input keyboard.]]
7. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#4. Navigasi Kursor - KEY_UP dan KEY_DOWN|Navigasi kursor - penanganan `KEY_UP` dan `KEY_DOWN`.]]
8. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#5. Perubahan Nilai Opsi - KEY_LEFT dan KEY_RIGHT|Perubahan nilai opsi - penanganan `KEY_LEFT` dan `KEY_RIGHT` untuk toggle `mode`, `bits`, `jobs`, `branch`, `api_version`, dan platform.]]
9. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#6. Eksekusi Aksi - ENTER dan SPACE|Eksekusi aksi - penanganan `ENTER`/`SPACE` untuk semua menu aksi.]]
10. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#3. Help Window - Dokumentasi Interaktif|Help window - menampilkan dokumentasi interaktif dengan scroll.]]
11. [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#7. Penanganan Keluar - Q/q|Penanganan `Q`/`q` - keluar dari aplikasi.]]

Semua kode dalam bab ini berada di dalam **heredoc `PYEOF_INNER`** dari `jalankan_bootstrapper.sh`, setelah fungsi-fungsi render dan dialog (Bab 10) dan sebelum blok `if __name__ == "__main__":`.

> [!quote] **Referensi Silang:**
> - `main()` dipanggil oleh `curses.wrapper(main)` di blok akhir file.
> - `main()` memanggil hampir semua fungsi yang telah kita bahas di Bab 7 - 10.
> - `main()` menggunakan `opts` dari [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#2. Fungsi `load_options()` - Memuat Opsi dengan Nilai Default|`load_options()`]].
> - `main()` menggunakan `MENU` dan [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih|`SELECTABLE`]].

---

## 2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi

*(Lokasi Baris 1314 - 1853)*
```python
def main(stdscr):
    curses.curs_set(0)
    
    try:
        curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
    except curses.error:
        pass
    stdscr.clear()
    stdscr.refresh()
    
    try:
        curses.start_color()
        curses.use_default_colors()
        if curses.has_colors():
            curses.init_pair(1, curses.COLOR_CYAN, -1)
            curses.init_pair(2, curses.COLOR_YELLOW, -1)
            curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_CYAN)
            curses.init_pair(4, curses.COLOR_GREEN, -1)
            curses.init_pair(5, curses.COLOR_RED, -1)
            curses.init_pair(6, curses.COLOR_MAGENTA, -1)
            STYLE["title"] = curses.color_pair(1) | curses.A_BOLD
            STYLE["section"] = curses.color_pair(2) | curses.A_BOLD
            STYLE["selected"] = curses.color_pair(3) | curses.A_BOLD
            STYLE["active"] = curses.color_pair(4) | curses.A_BOLD
            STYLE["inactive"] = curses.color_pair(5)
            STYLE["accent"] = curses.color_pair(6) | curses.A_BOLD
    except curses.error:
        pass
    
    curses.napms(150)
    stdscr.clear()
    stdscr.refresh()
    tanya_dan_pindah_folder_proyek(stdscr)
    log_lines = []
    opts = load_options()
    cursor = 0
    show_help = False
    HELP_ITEMS = [ ... ]  # Data help yang sangat panjang (Bab 18)
    while True:
        if show_help:
            # ... (help window logic)
            continue
        godot_status = get_godot_cpp_status(opts["godot_cpp_branch"], opts["godot_cpp_api_version"])
        last_build = get_last_build_info()
        render_menu(stdscr, opts, cursor, log_lines, godot_status, last_build)
        key = stdscr.getch()
        if key == curses.KEY_UP:
            cursor = (cursor - 1) % len(SELECTABLE)
        elif key == curses.KEY_DOWN:
            cursor = (cursor + 1) % len(SELECTABLE)
        elif key in (ord('h'), ord('H')):
            show_help = True
        elif key in (curses.KEY_LEFT, curses.KEY_RIGHT):
            # ... (handle value changes)
        elif key in (curses.KEY_ENTER, 10, 13, ord(' ')):
            # ... (handle action execution)
        elif key in (ord('q'), ord('Q')):
            break
```

### Tujuan
`main(stdscr)` adalah **pusat kendali** seluruh aplikasi. Ia melakukan inisialisasi, menjalankan dialog awal, lalu memasuki **loop utama** yang terus menerus ^ec41d2
1. Merender menu dengan status terkini.
2. Menunggu input keyboard.
3. Memproses input dan memperbarui state.
4. Kembali ke langkah 1.


### Inisialisasi Cursor

*(Lokasi Baris 1315)*
```python
curses.curs_set(0)
```

Menyembunyikan kursor teks (blinking underscore) di terminal. Kursor hanya akan muncul saat input teks (di `curses_input()` atau `minta_nama_folder_baru()`), dan akan disembunyikan kembali setelah selesai.

### Event Mouse (v2.4.0)

*(Lokasi Baris 1324 - 1327)*
```python
try:
    curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
except curses.error:
    pass
```

Fungsi ini mengaktifkan pelacakan event mouse di level curses. Ini penting untuk:
- [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#^0438b0|Menangkap scroll wheel agar tidak bocor menjadi "tombol ditekan" yang menutup dialog.]]
- Mendukung event mouse lainnya (klik, gerakan) jika diperlukan di masa depan.

`curses.ALL_MOUSE_EVENTS` mencakup semua jenis event mouse, dan `REPORT_MOUSE_POSITION` memungkinkan pelacakan posisi kursor mouse.

### Inisialisasi Warna (v2.4.0)

*(Lokasi Baris 1337 - 1354)*
```python
try:
    curses.start_color()
    curses.use_default_colors()
    if curses.has_colors():
        curses.init_pair(1, curses.COLOR_CYAN, -1)
        curses.init_pair(2, curses.COLOR_YELLOW, -1)
        curses.init_pair(3, curses.COLOR_BLACK, curses.COLOR_CYAN)
        curses.init_pair(4, curses.COLOR_GREEN, -1)
        curses.init_pair(5, curses.COLOR_RED, -1)
        curses.init_pair(6, curses.COLOR_MAGENTA, -1)
        STYLE["title"] = curses.color_pair(1) | curses.A_BOLD
        STYLE["section"] = curses.color_pair(2) | curses.A_BOLD
        STYLE["selected"] = curses.color_pair(3) | curses.A_BOLD
        STYLE["active"] = curses.color_pair(4) | curses.A_BOLD
        STYLE["inactive"] = curses.color_pair(5)
        STYLE["accent"] = curses.color_pair(6) | curses.A_BOLD
except curses.error:
    pass
```

Ini adalah **bagian krusial** dari v2.4.0 yang memberikan warna pada antarmuka curses. Mari kita bedah:
- **`curses.start_color()`** - mengaktifkan dukungan warna di curses.
- **`curses.use_default_colors()`** - memungkinkan penggunaan warna default terminal (termasuk transparan, dengan `-1`).
- **`curses.has_colors()`** - memeriksa apakah terminal benar-benar mendukung warna.
- **`curses.init_pair(n, fg, bg)`** - mendefinisikan pasangan warna:
    - Pair 1: Cyan (foreground) dengan background default untuk title.
    - Pair 2: Yellow untuk section header.
    - Pair 3: Black on Cyan untuk selected item (reverse video).
    - Pair 4: Green untuk active status.
    - Pair 5: Red untuk inactive/error.
    - Pair 6: Magenta untuk accent (debug mode).
- **Update `STYLE` dict** - semua key di `STYLE` yang sebelumnya hanya berisi atribut bold/dim sekarang digabung dengan `curses.color_pair()`.

Jika inisialisasi gagal (misal terminal tidak support warna), `except curses.error: pass` akan mengabaikan error dan `STYLE` tetap menggunakan fallback bold/dim/reverse polos.

> [!note] **Catatan Penting:**
> [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#7. Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE` - Pengantar|`STYLE` dict didefinisikan di Baris 104 - 119]] dengan nilai fallback. Fungsi `main()` **memodifikasi dict yang sama** secara in-place, sehingga semua fungsi yang menggunakan [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#^8c5e54|`STYLE`]] langsung mendapatkan warna tanpa perubahan kode.

### Stabilisasi Terminal (v2.4.0)

*(Lokasi Baris 1364 - 1366)*
```python
curses.napms(150)
stdscr.clear()
stdscr.refresh()
```

**`curses.napms(150)`** - jeda 150 milidetik. Ini penting karena:

- Terminal yang baru dibuka (melalui self-relaunch di Bab 4) mungkin belum selesai merender ukuran window-nya.
- Tanpa jeda ini, dialog pertama (`tanya_dan_pindah_folder_proyek()`) bisa tampil dengan ukuran yang salah atau tidak terlihat sama sekali.
- Jeda singkat ini memastikan terminal sudah stabil sebelum rendering dimulai.

### Dialog Awal

*(Lokasi Baris 1368)*
```python
tanya_dan_pindah_folder_proyek(stdscr)
```

[[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#^04c775|Fungsi ini menanyakan apakah pengguna ingin membuat folder proyek baru. Jika ya, dia akan meminta nama folder, membuatnya, memindahkan file Python yang diperlukan, dan melakukan `os.chdir()` ke folder tersebut.]]

### Inisialisasi State

*(Lokasi Baris 1370 - 1373)*
```python
log_lines = []
opts = load_options()
cursor = 0
show_help = False
```

- **`log_lines`** - daftar pesan log yang akan ditampilkan di bawah menu (hanya 6 baris terakhir).
- **`opts`** - opsi build yang dimuat dari `build_options.json` ==(Bab 8)==.
- **`cursor`** - indeks posisi kursor di `SELECTABLE` (dimulai dari 0 = `mode`).
- **`show_help`** - flag untuk menampilkan window help.

### Data `HELP_ITEMS`

*(Lokasi Baris 1375)*
```python
HELP_ITEMS = [ ... ]
```

Data ini sangat panjang (sekitar 80 baris) dan berisi dokumentasi interaktif yang ditampilkan saat pengguna menekan `H`. Karena panjangnya, data ini akan dibahas secara terpisah di ==**Bab 18**==.

### Loop Utama

**(Lokasi Baris 1044–1076)**

Loop utama adalah infinite `while True` yang:
1. Jika `show_help` aktif, tampilkan help window.
2. Render menu dengan status terkini.
3. Tunggu input keyboard.
4. Proses input.

---

## 3. Help Window - Dokumentasi Interaktif

*(Lokasi Baris 1454  - 1542)*
> [!NOTE]+ Pembukaan Kode
> ```python
> if show_help:
>     help_scroll = 0
>     while True:
>         stdscr.clear()
>         hh, ww = stdscr.getmaxyx()
>         
>         lebar_konten = max(36, min(ww - 6, 72))
>         kiri = max(2, (ww - lebar_konten) // 2)
>         
>         import textwrap as _textwrap
>         baris_wrap = []
>         for kind, teks in HELP_ITEMS:
>             if kind == "blank" or teks == "":
>                 baris_wrap.append(("blank", ""))
>                 continue
>             indent = "  " if teks.startswith("  ") else ""
>             untuk_wrap = teks.strip()
>             lebar_wrap = max(10, lebar_konten - len(indent))
>             potongan = _textwrap.wrap(untuk_wrap, lebar_wrap) or [""]
>             for p in potongan:
>                 baris_wrap.append((kind, f"{indent}{p}"))
>         
>         judul_help = "HELP"
>         sub_help = "UP/DOWN scroll  |  PgUp/PgDn page  |  Home/End jump  |  H/Q/ESC/ENTER close"
>         try:
>             stdscr.addstr(1, max(0, (ww - len(judul_help)) // 2), judul_help, STYLE["title"])
>             stdscr.addstr(2, max(0, (ww - len(sub_help)) // 2), sub_help, STYLE["dim"])
>         except curses.error:
>             pass
>    ```
>   
>         
> > [!NOTE]- Lanjutan Code
> > ```python
> >         area_atas = 4
> >         area_bawah = hh - 1
> >         visible = max(1, area_bawah - area_atas)
> >         max_scroll = max(0, len(baris_wrap) - visible)
> >         help_scroll = min(help_scroll, max_scroll)
> >         
> >         for i, (kind, teks) in enumerate(baris_wrap[help_scroll:help_scroll + visible]):
> >             row = area_atas + i
> >             if row >= area_bawah:
> >                 break
> >             style = STYLE["normal"]
> >             if kind == "title":
> >                 style = STYLE["title"]
> >             elif kind == "section":
> >                 style = STYLE["section"]
> >             try:
> >                 stdscr.addstr(row, kiri, teks[: max(0, ww - kiri - 2)], style)
> >             except curses.error:
> >                 pass
> >         
> >         if max_scroll > 0:
> >             persen = int(100 * help_scroll / max_scroll) if max_scroll else 0
> >             info_scroll = f"-- {persen}% --"
> >             try:
> >                 stdscr.addstr(area_bawah, max(0, (ww - len(info_scroll)) // 2), info_scroll, STYLE["dim"])
> >             except curses.error:
> >                 pass
> >         
> >         stdscr.refresh()
> >         key_help = stdscr.getch()
> >         
> >         if key_help == curses.KEY_RESIZE:
> >             continue
> >         elif key_help == curses.KEY_UP:
> >             help_scroll = max(0, help_scroll - 1)
> >         elif key_help == curses.KEY_DOWN:
> >             help_scroll = min(max_scroll, help_scroll + 1)
> >         elif key_help == curses.KEY_PPAGE:
> >             help_scroll = max(0, help_scroll - visible)
> >         elif key_help == curses.KEY_NPAGE:
> >             help_scroll = min(max_scroll, help_scroll + visible)
> >         elif key_help == curses.KEY_HOME:
> >             help_scroll = 0
> >         elif key_help == curses.KEY_END:
> >             help_scroll = max_scroll
> >         elif key_help in (ord('h'), ord('H'), ord('q'), ord('Q'), 27, curses.KEY_ENTER, 10, 13):
> >             break
> >     show_help = False
> >     continue
> > ```

### Tujuan
Help window adalah **dokumentasi interaktif** yang menjelaskan setiap bagian menu dan fungsinya. Pengguna dapat mengaksesnya kapan saja dengan menekan `H`, dan menavigasinya dengan tombol yang sama seperti `show_scrollable_dialog()` ==(Bab 10)==.

### Word Wrapping
Help window melakukan **word wrapping** otomatis agar teks pas dengan lebar terminal. Ini menggunakan `textwrap.wrap()` dari library standar Python.

### Data `HELP_ITEMS`
Struktur data `HELP_ITEMS` ==(akan dibahas di Bab 18)== adalah list of tuples `(kind, teks)`:
- `"section"` - judul bagian, ditampilkan dengan style `STYLE["section"]`.
- `"body"` - teks penjelasan, ditampilkan dengan style normal.
- `"blank"` - baris kosong untuk spasi.

### Navigasi
Sama seperti `show_scrollable_dialog()`, help window mendukung:
- UP/DOWN - scroll 1 baris.
- PgUp/PgDn - scroll satu layar penuh.
- Home/End - lompat ke awal/akhir.
- H / Q / ESC / ENTER - tutup help.

### Kembali ke Menu
Setelah help ditutup, `show_help = False` dan `continue` mengembalikan loop ke awal, di mana menu utama akan di-render ulang.

---

## 4. Navigasi Kursor - KEY_UP dan KEY_DOWN

*(Lokasi Baris 1550 - 1553)*
```python
if key == curses.KEY_UP:
    cursor = (cursor - 1) % len(SELECTABLE)
elif key == curses.KEY_DOWN:
    cursor = (cursor + 1) % len(SELECTABLE)
```

### Logika
- **UP** - kurangi indeks kursor dengan 1, dengan wrap-around (`% len(SELECTABLE)`).
- **DOWN** - tambah indeks kursor dengan 1, dengan wrap-around.

> [!NOTE]- Contoh
> ### Contoh
> Jika `SELECTABLE` memiliki 19 item (indeks 0 - 18):
> - Dari indeks 0, tekan UP maka indeks 18 (wrap ke paling bawah).
> - Dari indeks 18, tekan DOWN make indeks 0 (wrap ke paling atas).

### Efek Visual
Setelah kursor bergerak, loop berikutnya memanggil `render_menu()`, yang akan menggambar ulang menu dengan baris yang dipilih memiliki prefix `"> "` dan style `STYLE["selected"]` (reverse video + warna cyan).

---

## 5. Perubahan Nilai Opsi - KEY_LEFT dan KEY_RIGHT

*(Lokasi Baris 1556 - 1622)*
```python
elif key in (curses.KEY_LEFT, curses.KEY_RIGHT):
    pilihan = SELECTABLE[cursor]
    arah = -1 if key == curses.KEY_LEFT else 1
    if pilihan == "branch":
        DAFTAR_VERSI = load_daftar_versi()
        sekarang = opts["godot_cpp_branch"]
        idx_now = DAFTAR_VERSI.index(sekarang) if sekarang in DAFTAR_VERSI else 0
        berikutnya = DAFTAR_VERSI[(idx_now + arah) % len(DAFTAR_VERSI)]
        if berikutnya == "custom...":
            while True:
                baru = curses_input(stdscr, [f"Current godot-cpp version: {sekarang}", "Type a custom version/branch (e.g. 4.5, 3.5), leave blank to cancel:"])
                if not baru:
                    log_lines.append("Cancelled, version unchanged.")
                    break
                if any(c in baru for c in (" ", "'", '"')):
                    show_message_dialog(stdscr, "INVALID INPUT", ["Branch name can't contain spaces or quotes.", "Try again."])
                    continue
                opts["godot_cpp_branch"] = baru
                save_options(opts)
                log_lines.append(f"OK, version changed to {baru}.")
                break
        else:
            opts["godot_cpp_branch"] = berikutnya
            save_options(opts)
    elif pilihan == "api_version":
        if opts["godot_cpp_branch"] != "master":
            log_lines.append("Target api_version only applies when godot-cpp version = master.")
        else:
            DAFTAR_API = get_daftar_api_version()
            sekarang_api = opts["godot_cpp_api_version"]
            idx_now_api = DAFTAR_API.index(sekarang_api) if sekarang_api in DAFTAR_API else 0
            berikutnya_api = DAFTAR_API[(idx_now_api + arah) % len(DAFTAR_API)]
            if berikutnya_api == "custom...":
                while True:
                    baru = curses_input(stdscr, [f"Current api_version: {sekarang_api}", "Type the target Godot version (e.g. 4.7, 4.8), leave blank to cancel:"])
                    if not baru:
                        log_lines.append("Cancelled, api_version unchanged.")
                        break
                    if not validasi_format_versi(baru):
                        show_message_dialog(stdscr, "INVALID FORMAT", [f"'{baru}' is not a valid version format.", "Use number.number format, e.g. 4.7 or 4.7.1."])
                        continue
                    opts["godot_cpp_api_version"] = baru
                    save_options(opts)
                    log_lines.append(f"OK, api_version changed to {baru}.")
                    break
            else:
                opts["godot_cpp_api_version"] = berikutnya_api
                save_options(opts)
    elif pilihan == "jobs":
        urutan = [0, 2, 4, 8]
        idx_now = urutan.index(opts["jobs"]) if opts["jobs"] in urutan else 0
        opts["jobs"] = urutan[(idx_now + arah) % len(urutan)]
    elif pilihan == "mode":
        opts["mode"] = "debug" if opts["mode"] == "release" else "release"
    elif pilihan == "bits":
        opts["bits"] = "32" if opts["bits"] == "64" else "64"
    elif pilihan == "linux":
        opts["platforms"]["linux"] = not opts["platforms"]["linux"]
    elif pilihan == "windows":
        opts["platforms"]["windows"] = not opts["platforms"]["windows"]
```

### Tujuan
Menangani perubahan nilai opsi saat pengguna menekan **LEFT** (kurangi/prev) atau **RIGHT** (tambah/next) pada baris yang dipilih.

### Opsi `branch` - Toggle Versi godot-cpp

*(Lokasi Baris 507, 1561 - 1645)*
1. **Muat daftar versi** dari cache atau fallback (`load_daftar_versi()`).
2. **Cari indeks sekarang** - jika versi sekarang tidak ada di daftar (misal custom), gunakan indeks 0.
3. **Hitung indeks berikutnya** dengan wrap-around.
4. **Jika `"custom..."`** - minta input custom dari pengguna:
    - Validasi karakter (spasi, kutip tidak diperbolehkan).
    - Jika valid, simpan dan log.
    - Jika batal atau invalid, log pesan dan tidak mengubah opsi.
5. **Jika bukan `"custom..."`** - langsung gunakan versi berikutnya dan simpan.

### Opsi `api_version` - Toggle Target API

*(Lokasi Baris 1586 – 1674)*

- **Hanya berlaku jika branch `"master"`** - jika tidak, log pesan peringatan.
- **Muat daftar API** (`get_daftar_api_version()`).
- **Logika toggle sama seperti `branch`** - dengan validasi format menggunakan `validasi_format_versi()`.

### Opsi `jobs` - Cycle Jumlah Pekerja Paralel

*(Lokasi Baris 1608 - 1610)*
```python
urutan = [0, 2, 4, 8]
idx_now = urutan.index(opts["jobs"]) if opts["jobs"] in urutan else 0
opts["jobs"] = urutan[(idx_now + arah) % len(urutan)]
```

Cycle melalui nilai `0` (auto semua core), `2`,  `4`,  `8`, kembali ke `0`.

### Opsi `mode` - Toggle Debug/Release

**(Lokasi Baris 1613 - 1628)**
```python
opts["mode"] = "debug" if opts["mode"] == "release" else "release"
```

Toggle sederhana antara `"release"` dan `"debug"`.

### Opsi `bits` - Toggle 64/32-bit (v2.4.0)

*(Lokasi Baris 1616 -1631)*
```python
opts["bits"] = "32" if opts["bits"] == "64" else "64"
```

Toggle antara `"64"` dan `"32"`.

### Opsi `linux` dan `windows` - Toggle Platform

*(Lokasi Baris 1619 - 1622 atau 1634 - 1637)*
```python
opts["platforms"]["linux"] = not opts["platforms"]["linux"]
opts["platforms"]["windows"] = not opts["platforms"]["windows"]
```

Toggle boolean untuk masing-masing platform.

### Simpan Opsi

**Setiap perubahan** langsung memanggil `save_options(opts)` (kecuali jika gagal validasi), sehingga `build_options.json` selalu up-to-date.

---

## 6. Eksekusi Aksi - ENTER dan SPACE

*(Lokasi Baris 1624 -1851)*
```python
elif key in (curses.KEY_ENTER, 10, 13, ord(' ')):
    pilihan = SELECTABLE[cursor]
    if pilihan == "mode":
        opts["mode"] = "debug" if opts["mode"] == "release" else "release"
    elif pilihan == "bits":
        opts["bits"] = "32" if opts["bits"] == "64" else "64"
    elif pilihan == "linux":
        opts["platforms"]["linux"] = not opts["platforms"]["linux"]
    elif pilihan == "windows":
        opts["platforms"]["windows"] = not opts["platforms"]["windows"]
    elif pilihan == "jobs":
        urutan = [0, 2, 4, 8]
        idx_now = urutan.index(opts["jobs"]) if opts["jobs"] in urutan else 0
        opts["jobs"] = urutan[(idx_now + 1) % len(urutan)]
    elif pilihan == "branch":
        DAFTAR_VERSI = load_daftar_versi()
        sekarang = opts["godot_cpp_branch"]
        if sekarang in DAFTAR_VERSI:
            idx_now = DAFTAR_VERSI.index(sekarang)
            berikutnya = DAFTAR_VERSI[(idx_now + 1) % len(DAFTAR_VERSI)]
        else:
            berikutnya = DAFTAR_VERSI[0]
        if berikutnya == "custom...":
            # ... (custom input logic, sama seperti KEY_LEFT/RIGHT)
        else:
            opts["godot_cpp_branch"] = berikutnya
            save_options(opts)
    elif pilihan == "api_version":
        # ... (logic sama seperti KEY_LEFT/RIGHT)
    elif pilihan == "cek_versi":
        # ... (update version list from GitHub)
    elif pilihan == "cek_godot":
        # ... (check installed Godot)
    elif pilihan == "lihat_semua":
        # ... (view all godot-cpp versions)
    elif pilihan == "setup":
        # ... (run setup_godot_cpp.py)
    elif pilihan == "bersihkan_lama":
        # ... (clean up old godot-cpp)
    elif pilihan == "hapus":
        # ... (delete active godot-cpp)
    elif pilihan == "generate":
        # ... (confirm and generate files)
    elif pilihan == "credits":
        # ... (show credits)
    elif pilihan == "export_credits":
        # ... (export CREDITS.md)
    elif pilihan == "license":
        # ... (show license)
    elif pilihan == "export_license":
        # ... (export LICENSE)
    elif pilihan == "keluar":
        break
```

### Tujuan
Menangani **eksekusi aksi** saat pengguna menekan **ENTER** atau **SPACE** pada baris yang dipilih. Untuk opsi yang bersifat toggle (mode, bits, platform, jobs, branch, api_version), ENTER/SPACE berfungsi sama seperti LEFT/RIGHT (maju satu langkah). Untuk menu aksi (cek_versi, setup, generate, credits, dll), ENTER/SPACE menjalankan fungsi yang sesuai.

### Opsi Toggle (mode, bits, platform, jobs, branch, api_version)
Logika untuk toggle dengan ENTER/SPACE **identik** dengan logika LEFT/RIGHT, hanya saja arahnya selalu **maju** (arah = +1). Ini memberikan dua cara untuk mengubah opsi:
- LEFT/RIGHT untuk navigasi maju/mundur.
- ENTER/SPACE untuk maju cepat.

### Menu `cek_versi` - Update Version List

*(Lokasi Baris 1700 - 1720)*
```python
h, w = stdscr.getmaxyx()
stdscr.clear()
msg = "Contacting GitHub, please wait..."
try:
    stdscr.addstr(h // 2, max(0, (w - len(msg)) // 2), msg)
except curses.error:
    pass
stdscr.refresh()
hasil_versi = update_daftar_versi_online()
if hasil_versi:
    show_message_dialog_timed(stdscr, "UPDATE VERSION LIST", [
        f"OK! Found {len(hasil_versi)} versions, from {hasil_versi[0]} to {hasil_versi[-1]}.",
        "This list will be used in the 'godot-cpp version' toggle from now on.",
    ])
    log_lines.append(f"OK: version list updated ({hasil_versi[0]} to {hasil_versi[-1]}).")
else:
    show_message_dialog_timed(stdscr, "UPDATE VERSION LIST", [
        "Failed to fetch the list from GitHub (check your internet connection).",
        "The old version list is still used, nothing changed.",
    ])
    log_lines.append("FAILED: update version list (check internet connection).")
```

**Alur:**
1. Tampilkan pesan "Contacting GitHub, please wait...".
2. Panggil [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#8. Fungsi `update_daftar_versi_online()` - Tarik Versi dari GitHub|`update_daftar_versi_online()`]] yang melakukan `git ls-remote` ke GitHub.
3. Jika berhasil – tampilkan dialog dengan timer 10 detik, log sukses.
4. Jika gagal – tampilkan dialog dengan timer 10 detik, log gagal.

### Menu `cek_godot` - Check Installed Godot

*(Lokasi Baris 1723 - 1736)*
```python
terpasang = cek_godot_terinstall()
if terpasang:
    show_message_dialog(stdscr, "INSTALLED GODOT", [
        f"Found: {terpasang}",
        "",
        "To target this version: set 'godot-cpp version' = master,",
        "then set 'Target api_version' to match the version above (e.g. 4.7).",
        "(This is just a suggestion -- no option changes automatically.)",
    ])
else:
    show_message_dialog(stdscr, "INSTALLED GODOT", [
        "godot/godot4 not found in this system's PATH.",
        "No problem -- you can still set Target api_version manually.",
    ])
```

Panggil [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#7. Fungsi `cek_godot_terinstall()` - Deteksi Godot Editor di Sistem|`cek_godot_terinstall()`]] dan tampilkan hasilnya.

### Menu `lihat_semua` - View All godot-cpp Versions

*(Lokasi Baris 1739 - 1744)*
```python
daftar = cek_semua_godot_cpp()
if not daftar:
    show_message_dialog(stdscr, "ALL GODOT-CPP VERSIONS", ["There's no godot-cpp- folder here yet."])
else:
    baris = [f"{d}  --  {status}  (~{ukuran} MB)" for d, status, ukuran in daftar]
    show_message_dialog(stdscr, "ALL GODOT-CPP VERSIONS", baris)
```

Panggil [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding|`cek_semua_godot_cpp()`]] dan tampilkan daftar folder dengan status dan ukuran.

### Menu `setup` - Setup godot-cpp

*(Lokasi Baris 1747 - 1771)*
```python
if not os.path.exists("setup_godot_cpp.py"):
    log_lines.append("FAILED: setup_godot_cpp.py not found in this folder.")
else:
    save_options(opts)
    godot_dir = f"godot-cpp-master-api{opts['godot_cpp_api_version']}" if opts["godot_cpp_branch"] == "master" else f"godot-cpp-{opts['godot_cpp_branch']}"
    redownload = "0"
    if os.path.isdir(godot_dir):
        stdscr.clear()
        h, w = stdscr.getmaxyx()
        teks = [f"Folder '{godot_dir}' already exists.", "[ENTER] Re-download      [ESC/Q] Use existing"]
        for i, l in enumerate(teks):
            try: stdscr.addstr(2 + i, 2, l)
            except curses.error: pass
        stdscr.refresh()
        while True:
            k2 = stdscr.getch()
            if k2 in (curses.KEY_ENTER, 10, 13):
                redownload = "1"
                break
            elif k2 in (27, ord('q'), ord('Q')):
                redownload = "0"
                break
    env = dict(os.environ, KOBI_NONINTERAKTIF="1", KOBI_REDOWNLOAD=redownload)
    run_subprocess_in_curses(stdscr, [sys.executable, "setup_godot_cpp.py"], "SETUP GODOT-CPP", env=env)
    log_lines.append("OK: setup_godot_cpp.py finished running.")
```

**Alur:**

1. Cek apakah `setup_godot_cpp.py` ada.
2. Simpan opsi (`save_options()`) agar `setup_godot_cpp.py` membaca mode dan arsitektur terbaru.
3. Tentukan nama folder godot-cpp berdasarkan branch dan api_version.
4. Jika folder sudah ada, tanya pengguna: "Re-download atau Use existing?".
5. Jalankan `setup_godot_cpp.py` dengan:
    - `KOBI_NONINTERAKTIF=1` - agar script tidak meminta input (karena kita sudah tanya di curses).
    - `KOBI_REDOWNLOAD=0/1` - memberi tahu script apakah harus menghapus folder lama.
6. Tampilkan output live dengan `run_subprocess_in_curses()`.

### Menu `bersihkan_lama` - Clean Up Old godot-cpp

*(Lokasi Baris 1774 - 1793)*
```python
aktif_dir = f"godot-cpp-master-api{opts['godot_cpp_api_version']}" if opts["godot_cpp_branch"] == "master" else f"godot-cpp-{opts['godot_cpp_branch']}"
daftar = cek_semua_godot_cpp()
lama = [d for d, _, _ in daftar if d != aktif_dir]
if not lama:
    show_message_dialog(stdscr, "CLEAN UP OLD GODOT-CPP", ["There's no other godot-cpp folder besides the active one.", f"(Currently active: {aktif_dir})"])
else:
    konfirmasi = curses_input(stdscr, [f"About to delete {len(lama)} folder(s): {', '.join(lama)}", f"(The active one '{aktif_dir}' will NOT be deleted)", "Type DELETE to confirm, leave blank to cancel:"])
    if konfirmasi == "DELETE":
        gagal = []
        for d in lama:
            try:
                shutil.rmtree(d)
            except Exception as e:
                gagal.append(f"{d} ({e})")
        if gagal:
            log_lines.append(f"PARTIALLY FAILED to delete: {', '.join(gagal)}")
        else:
            log_lines.append(f"OK: {len(lama)} old godot-cpp folder(s) deleted ({', '.join(lama)}).")
    else:
        log_lines.append("Cancelled, old folders were not deleted.")
```

**Alur:**
1. Tentukan folder aktif berdasarkan opsi saat ini.
2. Dapatkan semua folder `godot-cpp-*` dengan `cek_semua_godot_cpp()`.
3. Filter folder yang tidak aktif (`lama`).
4. Jika tidak ada folder lama, tampilkan pesan.
5. Jika ada, minta pengguna mengetik `"DELETE"` untuk konfirmasi.
6. Jika konfirmasi benar, hapus semua folder lama dengan `shutil.rmtree()`.
7. Log hasil (sukses atau gagal).

### Menu `hapus` - Delete Active godot-cpp

*(Lokasi Baris 17474 - 1820)*
```python
if not os.path.exists("setup_godot_cpp.py"):
    log_lines.append("FAILED: setup_godot_cpp.py not found in this folder.")
else:
    save_options(opts)
    godot_dir = f"godot-cpp-master-api{opts['godot_cpp_api_version']}" if opts["godot_cpp_branch"] == "master" else f"godot-cpp-{opts['godot_cpp_branch']}"
    if not os.path.isdir(godot_dir):
        show_message_dialog(stdscr, "DELETE GODOT-CPP", [f"Folder '{godot_dir}' doesn't exist yet, nothing to delete."])
    else:
        konfirmasi = curses_input(stdscr, [f"Type DELETE (all caps) to confirm deleting '{godot_dir}':", "(leave blank to cancel)"])
        if konfirmasi == "DELETE":
            env = dict(os.environ, KOBI_NONINTERAKTIF="1", KOBI_HAPUS_KONFIRMASI="DELETE")
            run_subprocess_in_curses(stdscr, [sys.executable, "setup_godot_cpp.py", "--hapus"], "DELETE GODOT-CPP", env=env)
            log_lines.append("OK: godot-cpp deletion finished.")
        else:
            log_lines.append("Cancelled, folder was not deleted.")
```

**Alur:**
1. Cek `setup_godot_cpp.py` ada.
2. Simpan opsi.
3. Tentukan nama folder aktif.
4. Jika folder tidak ada, tampilkan pesan.
5. Jika ada, minta pengguna mengetik `"DELETE"`.
6. Jika benar, jalankan `setup_godot_cpp.py --hapus` dengan `KOBI_HAPUS_KONFIRMASI="DELETE"`.

### Menu `generate` - Save Options + Generate!

*(Lokasi Baris 1813 - 1821)*
```python
if not any(opts["platforms"].values()):
    log_lines.append("FAILED: at least one platform must be active!")
else:
    if confirm_generate(stdscr, opts):
        save_options(opts)
        log_lines.append("OK: options saved.")
        generate_files(stdscr, log_lines)
    else:
        log_lines.append("Cancelled, generate was not run.")
```

**Alur:**
1. Cek apakah setidaknya satu platform aktif – jika tidak, tolak.
2. Tampilkan konfirmasi dengan [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#12. Fungsi `confirm_generate()` - Konfirmasi Sebelum Generate|`confirm_generate()`]].
3. Jika disetujui, simpan opsi dan panggil [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|`generate_files()`]].
4. Jika dibatalkan, log "Cancelled".

### Menu `credits` - Show Credits

*(Lokasi Baris 1824)*
```python
show_message_dialog(stdscr, "CREDITS", CREDITS_LINES)
```

Tampilkan [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim|`CREDITS_LINES`]] dengan dialog biasa.

### Menu `export_credits` - Export CREDITS.md

*(Lokasi Baris 1827 - 1837)*
```python
try:
    with open("CREDITS.md", "w", encoding="utf-8") as f:
        f.write("# Credits\n\n")
        for baris in CREDITS_LINES:
            if baris == "":
                f.write("\n")
            else:
                f.write(baris + "\n")
    log_lines.append("OK: CREDITS.md exported successfully.")
except Exception as e:
    log_lines.append(f"FAILED to export CREDITS.md: {e}")
```

Tulis `CREDITS_LINES` ke file `CREDITS.md` di folder proyek.

### Menu `license` - View License (v2.4.0)

*(Lokasi Baris 1840)*
```python
show_scrollable_dialog(stdscr, "LICENSE (GPL-3.0-or-later)", LICENSE_TEXT.splitlines())
```

Tampilkan [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0|`LICENSE_TEXT`]] dengan [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]].

### Menu `export_license` - Export LICENSE (v2.4.0)

*(Lokasi Baris 1843 - 1848)*
```python
try:
    with open("LICENSE", "w", encoding="utf-8") as f:
        f.write(LICENSE_TEXT.strip("\n") + "\n")
    log_lines.append("OK: LICENSE exported successfully.")
except Exception as e:
    log_lines.append(f"FAILED to export LICENSE: {e}")
```

Tulis `LICENSE_TEXT` ke file `LICENSE` di folder proyek.

### Menu `keluar` - Quit

*(Lokasi Baris 1850 - 1851)*
```python
elif pilihan == "keluar":
	break
```

Keluar dari loop utama, yang akan mengakhiri `main()` dan kembali ke `curses.wrapper()`.

---

## 7. Penanganan Keluar - Q/q

*(Lokasi Baris 1852 - 1853)*
```python
elif key in (ord('q'), ord('Q')):
    break
```
Pengguna juga bisa keluar dengan menekan **Q** di menu utama (tanpa harus memilih `[ Quit ]`).

---

## 8. Tabel Rangkuman Navigasi Keyboard

| Tombol          | Fungsi                                |
| --------------- | ------------------------------------- |
| UP              | Pindah kursor ke atas (wrap)          |
| DOWN            | Pindah kursor ke bawah (wrap)         |
| LEFT            | Ubah nilai opsi ke kiri (prev)        |
| RIGHT           | Ubah nilai opsi ke kanan (next)       |
| ENTER / SPACE   | Toggle opsi (maju) atau eksekusi aksi |
| H               | Tampilkan help window                 |
| Q               | Keluar dari aplikasi                  |
| ESC (di dialog) | Batal / tutup dialog                  |

---

## 9. Tabel Rangkuman Aksi Menu

|ID Menu|Fungsi|Output|
|---|---|---|
|`mode`|Toggle `release`/`debug`|Update `build_options.json`|
|`bits`|Toggle `64`/`32`|Update `build_options.json`|
|`linux`|Toggle aktif/nonaktif|Update `build_options.json`|
|`windows`|Toggle aktif/nonaktif|Update `build_options.json`|
|`jobs`|Cycle `0→2→4→8`|Update `build_options.json`|
|`branch`|Toggle versi|Update `build_options.json`|
|`api_version`|Toggle API (master only)|Update `build_options.json`|
|`cek_versi`|Pull dari GitHub|Dialog timed + log|
|`cek_godot`|Deteksi editor|Dialog info|
|`lihat_semua`|Scan folder|Dialog daftar|
|`setup`|Clone & compile godot-cpp|Output live + log|
|`bersihkan_lama`|Hapus folder lama|Konfirmasi DELETE + log|
|`hapus`|Hapus folder aktif|Konfirmasi DELETE + log|
|`generate`|Generate SConstruct + build_logic.py|Konfirmasi + log|
|`credits`|Tampilkan kredit|Dialog|
|`export_credits`|Ekspor CREDITS.md|Log|
|`license`|Tampilkan lisensi|Scrollable dialog|
|`export_license`|Ekspor LICENSE|Log|
|`keluar`|Keluar|Break loop|

---

## 10. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Toggle Opsi Bits
> ### Opsi `bits` - Toggle di Main Loop
> Fitur baru `bits` ditangani di:
> - **`KEY_LEFT`/`KEY_RIGHT`** - toggle dengan arah.
> - **`ENTER`/`SPACE`** - toggle maju.

> [!done]- Menu Lisensi dan Export Lisensi
> ### Menu `license` dan `export_license`
> Dua menu baru ini ditambahkan di v2.4.0 dan dieksekusi dengan:
> - `show_scrollable_dialog()` - untuk menampilkan lisensi panjang.
> - `open("LICENSE", "w")` - untuk mengekspor lisensi.

> [!done]- Event Mouse di 'main()'
> ### Event Mouse di `main()`
> `curses.mousemask()` diaktifkan di awal `main()`, memungkinkan semua [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#^b70e93|dialog]] menangani scroll wheel dengan benar.

> [!done]- Inisialisasi Warna Style
> ### Inisialisasi Warna
> `main()` sekarang menginisialisasi warna dan memperbarui `STYLE` dict, memberikan pengalaman visual yang lebih kaya di terminal yang mendukung warna.

---

## 11. Kesimpulan

Pada bab ini, kita telah membahas secara mendalam **fungsi `main(stdscr)`** - pusat kendali seluruh aplikasi curses. Kita mempelajari:
1. **Inisialisasi** - cursor, mouse event, warna, dan stabilisasi terminal.
2. **Dialog awal** - `tanya_dan_pindah_folder_proyek()` untuk membuat/memilih folder proyek.
3. **Loop utama** - infinite loop yang merender menu dan memproses input.
4. **Help window** - dokumentasi interaktif dengan scroll.
5. **Navigasi kursor** - penanganan UP/DOWN dengan wrap-around.
6. **Perubahan opsi** - penanganan LEFT/RIGHT dan ENTER/SPACE untuk semua opsi toggle.
7. **Eksekusi aksi** - penanganan ENTER/SPACE untuk semua menu aksi.
8. **Fitur v2.4.0** - bits, license, export_license, mouse event, dan warna.