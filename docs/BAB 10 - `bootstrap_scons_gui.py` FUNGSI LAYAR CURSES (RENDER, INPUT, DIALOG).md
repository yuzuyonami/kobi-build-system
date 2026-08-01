# BAB 10 – `bootstrap_scons_gui.py`: FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)

---

## 1. Pendahuluan: Antarmuka Pengguna di Dunia Terminal

Setelah memahami struktur [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#^65cd18|menu]] dan bagaimana [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#^cd24e4|opsi]] dikelola, kini saatnya membahas **bagian paling visual** dari sistem build: fungsi-fungsi yang menggambar antarmuka curses itu sendiri. Bab ini adalah yang terpanjang dan paling kompleks karena mencakup seluruh lapisan presentasi dari rendering menu utama hingga dialog interaktif, input teks, dan eksekusi proses eksternal dengan output live.

Pada Bab 10, kita akan membahas **13 fungsi utama** yang menangani:
1. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|`render_menu()` - jantung UI: menggambar seluruh menu dengan style, warna, dan status.]]
2. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#3. Fungsi `curses_input()`- Input Teks di Dalam Curses|`curses_input()` - input teks di dalam mode curses (tanpa keluar dari terminal).]]
3. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#4. Fungsi `show_message_dialog_timed()` - Dialog dengan Hitung Mundur|`show_message_dialog_timed()` - dialog dengan hitung mundur otomatis.]]
4. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#5. Fungsi `show_message_dialog()` - Dialog Pesan Biasa|`show_message_dialog()` - dialog pesan sederhana (tombol apapun lanjut).]]
5. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()` - dialog untuk teks panjang dengan scroll (lisensi).]]
6. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#7. Fungsi `run_subprocess_in_curses()` - Output Live Proses Eksternal|`run_subprocess_in_curses()` - menjalankan proses eksternal dengan output live.]]
7. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#8. Fungsi `kotak_tengah()` - Box di Tengah Layar|`kotak_tengah()` - menggambar box di tengah layar.]]
8. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#9. Fungsi `tanya_ya_tidak()` - Dialog Y/N|`tanya_ya_tidak()` - dialog konfirmasi Y/N.]]
9. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#10. Fungsi `minta_nama_folder_baru()` - Input Nama Folder dengan Validasi|`minta_nama_folder_baru()` - input nama folder dengan validasi.]]
10. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#11. Fungsi `tanya_dan_pindah_folder_proyek()` - Dialog Awal Pembuatan Proyek|`tanya_dan_pindah_folder_proyek()` - dialog awal pembuatan proyek baru.]]
11. [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#12. Fungsi `confirm_generate()` - Konfirmasi Sebelum Generate|`confirm_generate()` - konfirmasi ringkasan opsi sebelum generate.]]

Semua fungsi ini berada di dalam **heredoc `PYEOF_INNER`** dari `jalankan_bootstrapper.sh`, setelah konstanta `MENU` dan [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih|`SELECTABLE`]] dan sebelum fungsi [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]]. Fungsi-fungsi ini menggunakan:

- [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#7. Konstanta `BOOTSTRAPPER_VERSION` dan `STYLE` - Pengantar|`STYLE` dict]] - untuk warna dan atribut teks.
- [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#Struktur Dictionary `opts`|`opts`]] - untuk nilai opsi yang ditampilkan.
- `MENU` dan [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih|`SELECTABLE`]] - untuk struktur menu.
- [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0|`LICENSE_TEXT`]] - untuk dialog lisensi.

>[!quote] **Referensi Silang:**
> - Fungsi-fungsi ini dipanggil oleh [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]].
> - `render_menu()` menggunakan `get_godot_cpp_status()` dan [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#10. Fungsi `get_last_build_info()` - Informasi Build Terakhir|`get_last_build_info()`]].
> - `show_scrollable_dialog()` dirancang khusus untuk [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0|`LICENSE_TEXT`]].

---

## 2. Fungsi `render_menu()` - Menggambar UI Utama

*(Lokasi Baris 778 - 910)*
```python
def render_menu(stdscr, opts, cursor, log_lines, godot_status, last_build):
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    judul = "KOBI Build Bootstrapper"
    try:
        stdscr.addstr(1, max(0, (w - len(judul)) // 2), judul, STYLE["title"])
    except curses.error:
        pass
    sub = f"v{BOOTSTRAPPER_VERSION}  |  UP/DOWN select  |  <-/-> change  |  ENTER/SPACE toggle  |  H help  |  Q quit"
    try:
        stdscr.addstr(2, max(0, (w - len(sub)) // 2), sub[: max(0, w - 2)], STYLE["dim"])
    except curses.error:
        pass
    jobs_label = "auto (all cores)" if opts["jobs"] == 0 else str(opts["jobs"])
    branch_display = f"master (api {opts['godot_cpp_api_version']})" if opts["godot_cpp_branch"] == "master" else opts["godot_cpp_branch"]
    LABELS = {
        "mode": f"Build mode      : {opts['mode'].upper()}",
        "bits": f"Architecture    : {opts['bits']}-bit",
        "linux": f"Linux platform  : {'ACTIVE' if opts['platforms']['linux'] else 'inactive'}",
        "windows": f"Windows platform: {'ACTIVE' if opts['platforms']['windows'] else 'inactive'}",
        "jobs": f"Parallel jobs   : {jobs_label}",
        "branch": f"godot-cpp version : {branch_display}  ({godot_status})",
        "api_version": (
            f"Target api_version : {opts['godot_cpp_api_version']}"
            if opts["godot_cpp_branch"] == "master"
            else "Target api_version : (inactive, switch 'godot-cpp version' to master first)"
        ),
        "cek_versi": "[ Update version list (check GitHub) ]",
        "cek_godot": "[ Check installed Godot version (suggestion) ]",
        "lihat_semua": "[ View all godot-cpp versions ]",
        "setup": "[ Setup godot-cpp (interactive clone/compile) ]",
        "bersihkan_lama": "[ Clean up old godot-cpp (except the active one) ]",
        "hapus": "[ Delete godot-cpp ]",
        "generate": "[ Save options + Generate! ]",
        "credits": "[ Credits ]",
        "export_credits": "[ Export Credits (CREDITS.md) ]",
        "license": "[ View License ]",
        "export_license": "[ Export License (LICENSE) ]",
        "keluar": "[ Quit ]",
    }
    ROW_STYLE = {
        "mode": STYLE["active"] if opts["mode"] == "release" else STYLE["accent"],
        "linux": STYLE["active"] if opts["platforms"]["linux"] else STYLE["inactive"],
        "windows": STYLE["active"] if opts["platforms"]["windows"] else STYLE["inactive"],
        "api_version": STYLE["normal"] if opts["godot_cpp_branch"] == "master" else STYLE["dim"],
    }
    header_texts = [item[2] for item in MENU if item[1] == "header"]
    lebar_konten = max([len(t) for t in LABELS.values()] + [len(t) for t in header_texts]) + 4
    lebar_box = min(lebar_konten + 4, max(20, w - 2))
    kiri_box = max(0, (w - lebar_box) // 2)
    kiri = kiri_box + 2
    box_top = 3
    content_start_y = box_top + 1
    box_bottom = content_start_y + len(MENU)
    try:
        stdscr.addstr(box_top, kiri_box, ("+" + "-" * (lebar_box - 2) + "+")[: max(0, w - kiri_box)], STYLE["accent"])
    except curses.error:
        pass
    try:
        stdscr.addstr(box_bottom, kiri_box, ("+" + "-" * (lebar_box - 2) + "+")[: max(0, w - kiri_box)], STYLE["accent"])
    except curses.error:
        pass
    y = content_start_y
    selectable_idx = 0
    for item in MENU:
        key, kind = item[0], item[1]
        try:
            stdscr.addstr(y, kiri_box, "|", STYLE["accent"])
            stdscr.addstr(y, kiri_box + lebar_box - 1, "|", STYLE["accent"])
        except curses.error:
            pass
        if kind == "header":
            teks = item[2]
            try:
                stdscr.addstr(y, max(kiri, kiri_box + (lebar_box - len(teks)) // 2), teks[: max(0, w - kiri - 2)], STYLE["section"])
            except curses.error:
                pass
            y += 1
        else:
            is_sel = selectable_idx == cursor
            style = STYLE["selected"] if is_sel else ROW_STYLE.get(key, STYLE["normal"])
            prefix = "> " if is_sel else "  "
            try:
                stdscr.addstr(y, kiri, (prefix + LABELS[key])[: max(0, w - kiri - 4)], style)
            except curses.error:
                pass
            y += 1
            selectable_idx += 1
    y = box_bottom + 2
    style_ringkasan = STYLE["dim"]
    if last_build:
        if "SUCCESS" in last_build:
            style_ringkasan = STYLE["active"]
        elif "FAILED" in last_build:
            style_ringkasan = STYLE["inactive"]
    ringkasan = f"Last build: {last_build}" if last_build else "Last build: (never built yet)"
    try:
        stdscr.addstr(y, max(0, (w - len(ringkasan)) // 2), ringkasan[: max(0, w - 4)], style_ringkasan)
    except curses.error:
        pass
    y += 2
    for i, line in enumerate(log_lines[-6:]):
        row = y + i
        if row < h - 1:
            if "FAILED" in line or "GAGAL" in line:
                style_log = STYLE["inactive"]
            elif line.startswith("OK"):
                style_log = STYLE["active"]
            else:
                style_log = STYLE["normal"]
            try:
                stdscr.addstr(row, max(0, (w - len(line)) // 2), line[: max(0, w - 4)], style_log)
            except curses.error:
                pass
    stdscr.refresh()
```

### Tujuan
`render_menu()` adalah **fungsi terpenting** di seluruh lapisan UI. Ia bertanggung jawab untuk menggambar **seluruh antarmuka menu** dari awal setiap kali ada perubahan (pergerakan kursor, perubahan opsi, update log, dll). Fungsi ini dipanggil di setiap iterasi loop utama [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]].

### Parameter

|Parameter|Tipe|Deskripsi|
|---|---|---|
|`stdscr`|`curses.window`|Objek window utama curses.|
|`opts`|`dict`|Opsi build saat ini (dari `load_options()`).|
|`cursor`|`int`|Indeks posisi kursor di `SELECTABLE`.|
|`log_lines`|`list[str]`|Daftar pesan log (hanya 6 baris terakhir ditampilkan).|
|`godot_status`|`str`|Status kompilasi godot-cpp aktif (dari `get_godot_cpp_status()`).|
|`last_build`|`str`|Ringkasan build terakhir (dari `get_last_build_info()`).|

### Struktur Visual
Fungsi ini menggambar layar dengan komponen-komponen berikut (dari atas ke bawah):
1. **Judul** - `"KOBI Build Bootstrapper"` dengan style `STYLE["title"]` (bold + underline).
2. **Subjudul** -Versi dan petunjuk navigasi dengan style `STYLE["dim"]`
3. **Box menu** - Dibungkus dengan border `+---+` dan `|` di sisi kiri/kanan.
4. **Isi menu** - Header (judul bagian) dan option (baris yang bisa dipilih).
5. **Info build terakhir** - Di bawah box menu.
6. **Log** - 6 baris terakhir dari pesan log (di bagian bawah layar).

### Pembuatan Dictionary `LABELS`
Fungsi membuat dictionary `LABELS` yang memetakan setiap ID menu ke **teks yang akan ditampilkan** di layar. Teks ini bersifat **dinamis** – nilainya berubah sesuai dengan nilai `opts` saat ini:
- `mode` - menampilkan `"RELEASE"` atau `"DEBUG"` (huruf besar).
- `bits` - menampilkan `"64-bit"` atau `"32-bit"`.
- `linux` / `windows` - menampilkan `"ACTIVE"` (hijau) atau `"inactive"` (merah).
- `jobs` - menampilkan `"auto (all cores)"` jika `0`, atau angka jika `> 0`.
- `branch` - menampilkan nama branch, dengan tambahan `" (compiled: ...)"` dari `godot_status`.
- `api_version` - menampilkan versi API, atau teks `"(inactive...)"` jika branch bukan `master`.

### Style Per-Baris (`ROW_STYLE`)
Dictionary `ROW_STYLE` menentukan warna/atribut default untuk setiap baris option (sebelum override oleh `STYLE["selected"]` jika baris sedang dipilih kursor):
- `mode` - `STYLE["active"]` (hijau) jika `release`, `STYLE["accent"]` (magenta) jika `debug`.
- `linux` / `windows` - `STYLE["active"]` jika aktif, `STYLE["inactive"]` (merah) jika tidak
- `api_version` - `STYLE["normal"]` jika branch `master`, `STYLE["dim"]` jika tidak (menandakan tidak aktif).

### Perhitungan Lebar Box dan Posisi
Fungsi menghitung lebar box secara dinamis berdasarkan:
- Panjang teks terpanjang di `LABELS` dan header.
- Lebar terminal (`w`).
- Box dibuat **di tengah layar** secara horizontal.

### Border Box
Border dibuat dengan karakter ASCII polos (`+`, `-`, `|`) alih-alih karakter box-drawing (`┌`, `─`, `┐`, dst). Ini dilakukan agar kompatibel dengan **semua terminal**, karena tidak semua terminal merender karakter box-drawing dengan rapi.

### Loop Rendering Menu
Fungsi iterasi melalui `MENU` dan menggambar setiap elemen:
- **Header** - digambar dengan style `STYLE["section"]` dan di-tengah-in di dalam box.
- **Option** - jika sedang dipilih kursor (`is_sel == True`), digambar dengan `STYLE["selected"]` (reverse video) dan prefix `"> "`; jika tidak, menggunakan style dari `ROW_STYLE` dan prefix `" "`.

### Log dan Info Build Terakhir
- **Last build** - ditampilkan di bawah box dengan warna sesuai status (hijau jika sukses, merah jika gagal, abu-abu jika belum pernah).
- **Log** - 6 baris terakhir dari `log_lines` ditampilkan di bagian bawah layar, dengan warna:
    - Merah jika mengandung `"FAILED"` atau `"GAGAL"`.
    - Hijau jika dimulai dengan `"OK"`.
    - Normal untuk lainnya.

---

## 3. Fungsi `curses_input()`- Input Teks di Dalam Curses

*(Lokasi Baris 913 - 939)*
```python
def curses_input(stdscr, prompt_lines):
    if isinstance(prompt_lines, str):
        prompt_lines = [prompt_lines]
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    for i, l in enumerate(prompt_lines):
        try:
            stdscr.addstr(2 + i, 2, l[: max(0, w - 4)])
        except curses.error:
            pass
    baris_input = 2 + len(prompt_lines) + 1
    try:
        stdscr.addstr(baris_input, 2, "> ")
    except curses.error:
        pass
    stdscr.refresh()
    curses.echo()
    curses.curs_set(1)
    try:
        teks = stdscr.getstr(baris_input, 4, 60).decode("utf-8", errors="ignore")
    except Exception:
        teks = ""
    curses.noecho()
    curses.curs_set(0)
    return teks.strip()
```

### Tujuan
`curses_input()` adalah pengganti `print()` + `input()` yang biasanya digunakan di terminal. Fungsi ini memungkinkan pengguna **mengetik teks** tanpa keluar dari mode curses, sehingga tampilan tetap konsisten dan tidak ada "kelip" saat beralih antar mode.

### Parameter
- `stdscr` - objek window curses.
- `prompt_lines` - bisa berupa string tunggal atau list of strings; akan ditampilkan sebagai prompt.

### Alur Eksekusi
1. **Clear layar** - `stdscr.clear()`.
2. **Tampilkan prompt** - setiap baris prompt digambar dengan offset 2 dari kiri dan 2 dari atas.
3. **Tampilkan simbol `"> "`** - di baris berikutnya, sebagai indikator input.
4. **Aktifkan echo** - `curses.echo()` agar karakter yang diketik terlihat.
5. **Tampilkan kursor** - `curses.curs_set(1)`.
6. **Baca input** - `stdscr.getstr(baris_input, 4, 60)` membaca hingga 60 karakter.
7. **Nonaktifkan echo dan kursor** - `curses.noecho()` dan `curses.curs_set(0)`.
8. **Kembalikan teks** - hasil input yang sudah di-`strip()`.

### Penggunaan
Fungsi ini dipanggil saat:
- Pengguna memilih `"custom..."` pada toggle `branch` atau `api_version` (Bab 11).
- Pengguna mengkonfirmasi penghapusan dengan mengetik `"DELETE"`.
- Pengguna memasukkan nama folder baru di dialog awal.

 Batasan
- Maksimal 60 karakter.
- Tidak ada validasi real-time; validasi dilakukan setelah input selesai (di fungsi pemanggil).

---

## 4. Fungsi `show_message_dialog_timed()` - Dialog dengan Hitung Mundur

*(Lokasi Baris 942 - 979)*
```python
def show_message_dialog_timed(stdscr, title, lines, timeout_detik=10):
    stdscr.nodelay(True)
    sisa = timeout_detik
    try:
        while sisa > 0:
            stdscr.clear()
            h, w = stdscr.getmaxyx()
            try:
                stdscr.addstr(1, max(0, (w - len(title)) // 2), title, STYLE["title"])
            except curses.error:
                pass
            for i, l in enumerate(lines):
                try:
                    stdscr.addstr(3 + i, 2, l[: max(0, w - 4)])
                except curses.error:
                    pass
            footer = f"[ENTER] return now   |   auto-return in {sisa}s"
            try:
                stdscr.addstr(3 + len(lines) + 1, max(0, (w - len(footer)) // 2), footer, STYLE["dim"])
            except curses.error:
                pass
            stdscr.refresh()
            waktu_mulai = time.time()
            while time.time() - waktu_mulai < 1.0:
                k = stdscr.getch()
                if k in (curses.KEY_ENTER, 10, 13):
                    return
                time.sleep(0.03)
            sisa -= 1
    finally:
        stdscr.nodelay(False)
```

### Tujuan
Dialog ini dirancang untuk situasi di mana pengguna **mungkin tidak sadar** bahwa ada pesan yang perlu dibaca (misal setelah network call yang berhasil atau gagal). Dialog akan:
1. Menampilkan pesan.
2. Menghitung mundur 10 detik.
3. **Otomatis menutup** jika tidak ada intervensi.
4. **Hanya merespons ENTER** – tombol lain diabaikan, mencegah penutupan tidak sengaja

### Mengapa Hanya ENTER?
Dialog ini digunakan setelah:
- `update_daftar_versi_online()` - network call yang mungkin memakan waktu.
- Jika pengguna tidak sengaja menekan tombol lain (misal spasi, panah), dialog tidak akan tertutup, memberi mereka waktu untuk membaca pesan.

### Implementasi Hitung Mundur
1. `stdscr.nodelay(True)` - `getch()` tidak akan blocking.
2. Loop `sisa` dari `timeout_detik` hingga 0.
3. Di dalam loop, render ulang layar setiap detik dengan nilai `sisa` yang diperbarui.
4. Di dalam sub-loop 1 detik, periksa input dengan `stdscr.getch()`; jika ENTER, return.
5. Setelah selesai, `finally` mengembalikan `nodelay(False)`    

### Penggunaan
Fungsi ini dipanggil setelah `update_daftar_versi_online()` untuk menampilkan hasil update (berhasil atau gagal) dengan otomatis tertutup setelah 10 detik.

---

## 5. Fungsi `show_message_dialog()` - Dialog Pesan Biasa

*(Lokasi Baris 1069 - 1100)*
```python
def show_message_dialog(stdscr, title, lines):
    while True:
        stdscr.clear()
        h, w = stdscr.getmaxyx()
        try:
            stdscr.addstr(1, max(0, (w - len(title)) // 2), title, STYLE["title"])
        except curses.error:
            pass
        for i, l in enumerate(lines):
            try:
                stdscr.addstr(3 + i, 2, l[: max(0, w - 4)])
            except curses.error:
                pass
        footer = "Press any key to return to the menu..."
        try:
            stdscr.addstr(3 + len(lines) + 1, max(0, (w - len(footer)) // 2), footer, STYLE["dim"])
        except curses.error:
            pass
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_MOUSE:
            try:
                curses.getmouse()
            except curses.error:
                pass
            continue
        if key != curses.KEY_RESIZE:
            return
```

### Tujuan
Dialog sederhana untuk menampilkan pesan informasional, dengan **tombol apapun** (kecuali resize dan mouse) akan menutup dialog dan kembali ke menu. ^0438b0

> [!done]- Update  Perbaikan untuk Mouse Event pada Versi 2.4.0
> ### Perbaikan untuk Mouse Event (v2.4.0)
> Fungsi ini dilengkapi dengan penanganan `curses.KEY_MOUSE`:
> - Jika pengguna meng-scroll mouse wheel, event mouse dikonsumsi (`curses.getmouse()`) dan dialog **tetap terbuka**.
> - Sebelum perbaikan ini, scroll wheel di beberapa terminal (misal xterm) akan mengirimkan kode tombol yang dianggap "tombol apapun" dan menutup dialog secara tidak sengaja.

### Penggunaan
Dipanggil oleh banyak menu:
- `[ Credits ]` - menampilkan `CREDITS_LINES`.
- `[ Check installed Godot version ]` - menampilkan hasil deteksi.
- `[ View all godot-cpp versions ]` - menampilkan daftar folder.
- Dan lain-lain.

---

## 6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang

*(Lokasi Baris 982 - 1065)*
```python
def show_scrollable_dialog(stdscr, title, text_lines):
    scroll = 0
    while True:
        stdscr.clear()
        hh, ww = stdscr.getmaxyx()
        margin = 2
        try:
            stdscr.addstr(1, max(0, (ww - len(title)) // 2), title, STYLE["title"])
        except curses.error:
            pass
        sub_help = "UP/DOWN scroll  |  PgUp/PgDn page  |  Home/End jump  |  Q/ESC/ENTER close"
        try:
            stdscr.addstr(2, max(0, (ww - len(sub_help)) // 2), sub_help, STYLE["dim"])
        except curses.error:
            pass
        area_atas = 4
        area_bawah = hh - 1
        visible = max(1, area_bawah - area_atas)
        max_scroll = max(0, len(text_lines) - visible)
        scroll = min(scroll, max_scroll)
        for i, teks in enumerate(text_lines[scroll:scroll + visible]):
            row = area_atas + i
            if row >= area_bawah:
                break
            if teks.strip() and teks == teks.upper() and not teks.startswith(" "):
                kol = max(margin, (ww - len(teks)) // 2)
                style = STYLE["section"]
            else:
                kol = margin
                style = STYLE["normal"]
            try:
                stdscr.addstr(row, kol, teks[: max(0, ww - kol - 1)], style)
            except curses.error:
                pass
        if max_scroll > 0:
            persen = int(100 * scroll / max_scroll) if max_scroll else 0
            info_scroll = f"-- {persen}% --"
            try:
                stdscr.addstr(area_bawah, max(0, (ww - len(info_scroll)) // 2), info_scroll, STYLE["dim"])
            except curses.error:
                pass
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_MOUSE:
            try:
                curses.getmouse()
            except curses.error:
                pass
            continue
        elif key == curses.KEY_RESIZE:
            continue
        elif key == curses.KEY_UP:
            scroll = max(0, scroll - 1)
        elif key == curses.KEY_DOWN:
            scroll = min(max_scroll, scroll + 1)
        elif key == curses.KEY_PPAGE:
            scroll = max(0, scroll - visible)
        elif key == curses.KEY_NPAGE:
            scroll = min(max_scroll, scroll + visible)
        elif key == curses.KEY_HOME:
            scroll = 0
        elif key == curses.KEY_END:
            scroll = max_scroll
        elif key in (ord('q'), ord('Q'), 27, curses.KEY_ENTER, 10, 13):
            break
```

### Tujuan
`show_scrollable_dialog()` dirancang khusus untuk menampilkan **teks yang sangat panjang**, seperti lisensi GPL-3.0 (~700 baris). Fitur-fitur utamanya: ^b70e93
- **Scroll** dengan UP/DOWN, PgUp/PgDn, Home/End.
- **Deteksi judul bab** - baris yang huruf besar semua dan tidak diawali spasi akan di-tengah-in secara otomatis.
- **Indikator scroll** - menampilkan persentase posisi scroll (misal `-- 45% --`).
- **Resistensi mouse** – event mouse dikonsumsi, tidak menutup dialog.

### Deteksi Judul Bab

*(Lokasi Baris 1019 - 1024)*
```python
if teks.strip() and teks == teks.upper() and not teks.startswith(" "):
    kol = max(margin, (ww - len(teks)) // 2)
    style = STYLE["section"]
else:
    kol = margin
    style = STYLE["normal"]
```

Logika ini mendeteksi baris yang:

1. Tidak kosong (`teks.strip()`).
2. Semua huruf besar (`teks == teks.upper()`).
3. Tidak diawali spasi (bukan paragraf yang di-indent).

Jika ketiga kondisi terpenuhi, baris dianggap judul bab dan di-tengah-in dengan style `STYLE["section"]`.

### Navigasi Keyboard

| Tombol          | Fungsi                     |
| --------------- | -------------------------- |
| UP              | Scroll 1 baris ke atas     |
| DOWN            | Scroll 1 baris ke bawah    |
| Page Up         | Scroll satu layar ke atas  |
| Page Down       | Scroll satu layar ke bawah |
| Home            | Lompat ke awal             |
| End             | Lompat ke akhir            |
| Q / ESC / ENTER | Tutup dialog               |

### Penggunaan
Fungsi ini dipanggil oleh menu `[ View License ]` (Bab 11) dengan argumen `LICENSE_TEXT.splitlines()`.

---

## 7. Fungsi `run_subprocess_in_curses()` - Output Live Proses Eksternal

*(Lokasi Baris 1013 - 1159)*
```python
def run_subprocess_in_curses(stdscr, cmd, title, env=None):
    import subprocess as _sp
    proc = _sp.Popen(cmd, stdout=_sp.PIPE, stderr=_sp.STDOUT, text=True, bufsize=1, env=env)
    log = []
    while True:
        h, w = stdscr.getmaxyx()
        max_lines = max(3, h - 5)
        line = proc.stdout.readline()
        if line == "" and proc.poll() is not None:
            break
        if line:
            log.append(line.rstrip("\n"))
            log = log[-max_lines:]
            stdscr.clear()
            try:
                stdscr.addstr(1, max(0, (w - len(title)) // 2), title, STYLE["title"])
            except curses.error:
                pass
            for i, l in enumerate(log):
                try:
                    stdscr.addstr(3 + i, 2, l[: max(0, w - 4)])
                except curses.error:
                    pass
            stdscr.refresh()
    rc = proc.wait()
    h, w = stdscr.getmaxyx()
    max_lines = max(3, h - 5)
    log.append("")
    log.append(f"Done (exit code: {rc}). Press any key to return to the menu...")
    while True:
        stdscr.clear()
        try:
            stdscr.addstr(1, max(0, (w - len(title)) // 2), title, STYLE["title"])
        except curses.error:
            pass
        for i, l in enumerate(log[-max_lines:]):
            try:
                stdscr.addstr(3 + i, 2, l[: max(0, w - 4)])
            except curses.error:
                pass
        stdscr.refresh()
        key = stdscr.getch()
        if key == curses.KEY_MOUSE:
            try:
                curses.getmouse()
            except curses.error:
                pass
            continue
        if key != curses.KEY_RESIZE:
            break
    return rc
```

### Tujuan
Fungsi ini menjalankan **proses eksternal** (seperti `setup_godot_cpp.py`) dan menampilkan **output live-nya** di layar curses, baris per baris. Ini memberikan pengalaman yang mulus tanpa harus keluar dari mode curses.

### Parameter
- `cmd` - list perintah (misal `[sys.executable, "setup_godot_cpp.py"]`).
- `title` - judul yang ditampilkan di atas output.
- `env` - environment variables tambahan (opsional).

### Alur Eksekusi
1. **Jalankan proses** dengan `Popen`, redirect `stdout` dan `stderr` ke pipe yang sama (`stderr=_sp.STDOUT`).
2. **Loop baca output** - baca `stdout` baris per baris dengan `readline()`.
3. **Update layar** - setiap kali ada baris baru, tambahkan ke `log`, potong ke `max_lines` terakhir, lalu render ulang.
4. **Tunggu proses selesai** - setelah `proc.poll() is not None` dan tidak ada lagi output, tunggu return code.
5. **Tampilkan exit code** - tambahkan `Done (exit code: X). Press any key...`.
6. **Tunggu input** - pengguna menekan tombol apapun (kecuali resize/mouse) untuk kembali.

### Penggunaan
Fungsi ini dipanggil oleh:
- Menu `[ Setup godot-cpp ]` - menjalankan `setup_godot_cpp.py` dengan environment `KOBI_NONINTERAKTIF=1`.
- Menu `[ Delete godot-cpp ]` - menjalankan `setup_godot_cpp.py --hapus`.

---

## 8. Fungsi `kotak_tengah()` - Box di Tengah Layar

*(Lokasi Baris 1159 – 1186)*
```python
def kotak_tengah(stdscr, baris_teks, judul=None):
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    semua_baris = ([judul, ""] if judul else []) + baris_teks
    tinggi_box = len(semua_baris) + 4
    lebar_box = max([len(b) for b in semua_baris] + [20]) + 8
    tinggi_box = min(tinggi_box, h - 2) if h > 4 else tinggi_box
    lebar_box = min(lebar_box, w - 2) if w > 4 else lebar_box
    atas = max(0, (h - tinggi_box) // 2)
    kiri = max(0, (w - lebar_box) // 2)
    try:
        win = curses.newwin(tinggi_box, lebar_box, atas, kiri)
        win.box()
        for i, b in enumerate(semua_baris):
            style = curses.A_BOLD if (judul and i == 0) else curses.A_NORMAL
            try:
                win.addstr(2 + i, max(1, (lebar_box - len(b)) // 2), b[: max(0, lebar_box - 2)], style)
            except curses.error:
                pass
        stdscr.noutrefresh()
        win.noutrefresh()
        curses.doupdate()
    except curses.error:
        pass
    return atas, kiri, tinggi_box, lebar_box
```

### Tujuan
Fungsi ini menggambar sebuah **box** (kotak) yang diposisikan **di tengah layar** (baik horizontal maupun vertikal). Box ini digunakan untuk dialog-dialog awal yang membutuhkan fokus pengguna.

### Parameter
- `stdscr` - window utama.
- `baris_teks` - list of strings yang akan ditampilkan di dalam box.
- `judul` - (opsional) baris judul yang akan di-bold.

### Perhitungan Dimensi
1. **Tinggi box** = `len(semua_baris) + 4` (2 baris padding di atas, 2 di bawah).
2. **Lebar box** = `max(panjang semua baris, 20) + 8` (padding 4 di kiri, 4 di kanan).
3. **Posisi tengah** - `atas = (h - tinggi_box) // 2`, `kiri = (w - lebar_box) // 2`.

### Return Value
Fungsi mengembalikan tuple `(atas, kiri, tinggi_box, lebar_box)` yang bisa digunakan oleh pemanggil untuk menentukan posisi input (misal di `minta_nama_folder_baru()`).

### Penggunaan
Fungsi ini dipanggil oleh:
- `tanya_ya_tidak()` - untuk menampilkan box pertanyaan Y/N.
- `minta_nama_folder_baru()` - untuk menampilkan box input nama folder.

---

## 9. Fungsi `tanya_ya_tidak()` - Dialog Y/N

*(Lokasi Baris 1189 - 1199)*
```python
def tanya_ya_tidak(stdscr, judul, pertanyaan):
    curses.curs_set(0)
    while True:
        kotak_tengah(stdscr, [pertanyaan, "", "[ Y ] Yes          [ N ] No"], judul=judul)
        k = stdscr.getch()
        if k in (ord('y'), ord('Y')):
            return True
        elif k in (ord('n'), ord('N')):
            return False
```

### Tujuan
Dialog sederhana yang **hanya menerima Y atau N**. Tombol lain diabaikan (loop terus), memaksa pengguna untuk memilih salah satu.

### Penggunaan
Fungsi ini dipanggil di `tanya_dan_pindah_folder_proyek()` untuk menanyakan "Buat folder proyek baru?". ^04c775

---

## 10. Fungsi `minta_nama_folder_baru()` - Input Nama Folder dengan Validasi

*(Lokasi Baris 1203 - 1240)*
```python
def minta_nama_folder_baru(stdscr):
    while True:
        atas, kiri, tinggi_box, lebar_box = kotak_tengah(
            stdscr,
            ["Project folder name (leave blank = cancel):", ""],
            judul="INIT NEW PROJECT",
        )
        baris_input = atas + 4
        kolom_input = kiri + 4
        curses.echo()
        curses.curs_set(1)
        try:
            stdscr.addstr(baris_input, kolom_input, "> ")
            stdscr.refresh()
            nama = stdscr.getstr(baris_input, kolom_input + 2, 40).decode("utf-8", errors="ignore").strip()
        except Exception:
            nama = ""
        curses.noecho()
        curses.curs_set(0)
        if not nama:
            return None
        import re
        if not re.match(r'^[a-zA-Z0-9_-]+$', nama):
            kotak_tengah(stdscr, [
                "Folder name contains unsupported characters.",
                "Use only letters, numbers, hyphens (-), or underscores (_).",
                "",
                "Press any key to try again...",
            ], judul="INVALID NAME")
            stdscr.getch()
            continue
        return nama
```

### Tujuan
Meminta pengguna memasukkan nama folder untuk proyek baru, dengan **validasi karakter**:
- Hanya huruf (`a-zA-Z`), angka (`0-9`), hyphen (`-`), dan underscore (`_`) yang diperbolehkan.
- Jika input kosong, dianggap "batal" dan mengembalikan `None`.
- Jika input tidak valid, tampilkan pesan error dan minta input ulang.

### Validasi Regex

*(Lokasi Baris 1230)*
```python
if not re.match(r'^[a-zA-Z0-9_-]+$', nama)
```

Regex ini memastikan nama folder aman untuk digunakan di filesystem dan tidak mengandung karakter khusus yang bisa menyebabkan masalah (spasi, tanda kutip, dll).

### Penggunaan
Fungsi ini dipanggil oleh `tanya_dan_pindah_folder_proyek()`.

---

## 11. Fungsi `tanya_dan_pindah_folder_proyek()` - Dialog Awal Pembuatan Proyek

*(Lokasi Baris 1243 - 1296)*
```python
def tanya_dan_pindah_folder_proyek(stdscr):
    mau_baru = tanya_ya_tidak(stdscr, "KOBI BUILD BOOTSTRAPPER", "Create a new project folder?")
    if not mau_baru:
        return
    while True:
        nama = minta_nama_folder_baru(stdscr)
        if nama is None:
            return
        if os.path.isdir(nama):
            pakai_yang_ada = tanya_ya_tidak(stdscr, "FOLDER ALREADY EXISTS", f"Folder '{nama}' already exists. Just go into that folder?")
            if not pakai_yang_ada:
                continue
        else:
            os.mkdir(nama)
        for f in ("bootstrap_scons_gui.py", "setup_godot_cpp.py"):
            tujuan = os.path.join(nama, f)
            if os.path.exists(f) and not os.path.exists(tujuan):
                shutil.move(f, tujuan)
        os.chdir(nama)
        return
```

### Tujuan
Fungsi ini adalah **dialog pertama** yang muncul saat bootstrapper dijalankan. Ia menanyakan apakah pengguna ingin:
1. **Membuat folder proyek baru** - jika ya, minta nama folder dan pindah ke sana.
2. **Tetap di folder saat ini** - jika tidak, langsung lanjut ke menu.

> [!info]- Logika
> ### Logika
> 1. Tanya Y/N: "Create a new project folder?"
> 2. Jika "Tidak", maka return (tetap di folder saat ini).
> 3. Jika "Ya", maka minta nama folder (loop sampai valid).
> 4. Jika folder sudah ada, maka tanya "Just go into that folder?":
>     - Ya, maka pindah ke folder tersebut.
>     - Tidak, maka minta nama lagi.
> 5. Jika folder belum ada, maka buat folder dengan `os.mkdir(nama)`.
> 6. **Pindahkan file Python** - jika `bootstrap_scons_gui.py` dan `setup_godot_cpp.py` ada di folder saat ini, pindahkan ke folder baru.
> 7. `os.chdir(nama)` - pindah direktori kerja ke folder baru.

### Mengapa File Python Dipindahkan?
Karena bootstrapper membuat file-file ini di folder tempat `jalankan_bootstrapper.sh` dieksekusi. Jika pengguna membuat folder proyek baru, file-file ini harus **ikut pindah** agar proyek baru tetap memiliki semua komponen yang diperlukan (tanpa harus menjalankan bootstrapper ulang).

---

## 12. Fungsi `confirm_generate()` - Konfirmasi Sebelum Generate

*(Lokasi Baris 1272 - 1311)*
```python
def confirm_generate(stdscr, opts):
    stdscr.clear()
    h, w = stdscr.getmaxyx()
    judul = "CONFIRM GENERATE"
    try:
        stdscr.addstr(1, max(0, (w - len(judul)) // 2), judul, STYLE["title"])
    except curses.error:
        pass
    platform_aktif = ", ".join([p for p, on in opts["platforms"].items() if on]) or "(none!)"
    branch_display = f"master (api {opts['godot_cpp_api_version']})" if opts["godot_cpp_branch"] == "master" else opts["godot_cpp_branch"]
    baris_opsi = [
        f"Build mode       : {opts['mode'].upper()}",
        f"Architecture     : {opts['bits']}-bit",
        f"Active platforms : {platform_aktif}",
        f"Parallel jobs    : {'auto' if opts['jobs'] == 0 else opts['jobs']}",
        f"godot-cpp version: {branch_display}",
        "",
        "Proceed to generate SConstruct + build_logic.py with the options above?",
        "[ENTER] Yes, generate      [ESC/Q] Cancel",
    ]
    lebar_konten = max(len(t) for t in baris_opsi)
    kiri = max(2, (w - lebar_konten) // 2)
    for i, teks in enumerate(baris_opsi):
        try:
            stdscr.addstr(3 + i, kiri, teks[: max(0, w - kiri - 2)])
        except curses.error:
            pass
    stdscr.refresh()
    while True:
        key = stdscr.getch()
        if key in (curses.KEY_ENTER, 10, 13):
            return True
        elif key in (27, ord('q'), ord('Q')):
            return False
        elif key == curses.KEY_RESIZE:
            continue
```

### Tujuan
Menampilkan **ringkasan semua opsi** sebelum benar-benar menjalankan [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py|`generate_files()`]]. Ini mencegah pengguna tidak sengaja mengganti opsi dan langsung generate tanpa melihat konsekuensinya.

### Isi Ringkasan
- Build mode (`RELEASE` / `DEBUG`).
- Architecture (`64-bit` / `32-bit`).
- Active platforms (daftar platform yang aktif).
- Parallel jobs (angka atau `"auto"`).
- godot-cpp version (branch + api_version jika master).

### Navigasi
- **ENTER** - lanjutkan generate.
- **ESC** / **Q** - batalkan.
- **Resize** - diabaikan (redraw).

---

## 13. Tabel Rangkuman Fungsi Layar Curses

| Fungsi                             | Lokasi Baris | Tujuan                               | Dipanggil Oleh                                                                                                                               |
| ---------------------------------- | ------------ | ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------- |
| `render_menu()`                    | 778 - 910    | Menggambar UI utama                  | [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi\|`main()`]] |
| `curses_input()`                   | 913 - 939    | Input teks di dalam curses           | Menu `custom...`, konfirmasi DELETE                                                                                                          |
| `show_message_dialog_timed()`      | 942 - 979    | Dialog dengan hitung mundur 10 detik | `update_daftar_versi_online()`                                                                                                               |
| `show_message_dialog()`            | 1069 - 1100  | Dialog pesan biasa                   | Credits, Godot version, view all, dll                                                                                                        |
| `show_scrollable_dialog()`         | 982 - 1065   | Dialog teks panjang dengan scroll    | Menu `[ View License ]`                                                                                                                      |
| `run_subprocess_in_curses()`       | 1013 - 1159  | Output live proses eksternal         | Menu `[ Setup godot-cpp ]`, `[ Delete godot-cpp ]`                                                                                           |
| `kotak_tengah()`                   | 1159 – 1186  | Box di tengah layar                  | `tanya_ya_tidak()`, `minta_nama_folder_baru()`                                                                                               |
| `tanya_ya_tidak()`                 | 1189 - 1199  | Dialog Y/N                           | `tanya_dan_pindah_folder_proyek()`                                                                                                           |
| `minta_nama_folder_baru()`         | 1203 - 1240  | Input nama folder dengan validasi    | `tanya_dan_pindah_folder_proyek()`                                                                                                           |
| `tanya_dan_pindah_folder_proyek()` | 1243 - 1296  | Dialog awal pembuatan proyek         | [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi\|`main()`]] |
| `confirm_generate()`               | 1272 - 1311  | Konfirmasi opsi sebelum generate     | Menu `[ Generate! ]`                                                                                                                         |

---

## 14. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Event Mouse
> ### Event Mouse (v2.4.0)
> - **`show_message_dialog()`** - sekarang menangani `curses.KEY_MOUSE` agar scroll wheel tidak menutup dialog.
> - **`show_scrollable_dialog()`** - juga menangani `KEY_MOUSE` dengan cara yang sama.
> - **`run_subprocess_in_curses()`** - menangani `KEY_MOUSE` dan `KEY_RESIZE` dengan benar.
> 
> Ini adalah perbaikan kualitas hidup yang signifikan - pengguna tidak akan frustrasi karena scroll wheel yang tidak sengaja menutup dialog.

> [!done]- Tampilan Lisensi
> ### show_scrollable_dialog()` untuk Lisensi
> Fungsi ini baru di v2.4.0 dan dirancang khusus untuk:
> - Menampilkan `LICENSE_TEXT` yang panjang.
> - Mendeteksi judul bab (huruf besar) untuk perataan tengah otomatis.
> - Mendukung navigasi yang lengkap (UP/DOWN, PgUp/PgDn, Home/End).

> [!done]- Pemambahan Opsi Pilihan Arsitektur Bit
> ### Opsi `bits` di `render_menu()`
> `render_menu()` menampilkan opsi `bits` sebagai baris:
> 
> ```text
> Architecture    : 64-bit
> ```
> 
> Nilai ini berubah saat pengguna menekan RIGHT/LEFT atau ENTER/SPACE pada baris tersebut.

> [!done]- Perbaruan Style
> ### `STYLE` Dict yang Diperbarui
> Semua fungsi di bab ini menggunakan `STYLE` dict yang sudah diinisialisasi dengan warna di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]]. Jika terminal tidak mendukung warna, fallback ke atribut bold/dim/reverse.

^8c5e54

---

## 15. Kesimpulan
Pada bab ini, kita telah membahas **11 fungsi utama** yang membentuk seluruh lapisan presentasi antarmuka curses. Kita mempelajari:
1. **`render_menu()`** - jantung UI yang menggambar menu dengan border, style, dan status dinamis.
2. **`curses_input()`** - input teks tanpa keluar dari mode curses.
3. **Tiga jenis dialog** - `show_message_dialog()` (biasa), `show_message_dialog_timed()` (dengan timer), dan `show_scrollable_dialog()` (untuk teks panjang).
4. **`run_subprocess_in_curses()`** - menjalankan proses eksternal dengan output live.
5. **Dialog awal** – `kotak_tengah()`, `tanya_ya_tidak()`, `minta_nama_folder_baru()`, dan `tanya_dan_pindah_folder_proyek()`.
6. **`confirm_generate()`** - konfirmasi opsi sebelum generate.