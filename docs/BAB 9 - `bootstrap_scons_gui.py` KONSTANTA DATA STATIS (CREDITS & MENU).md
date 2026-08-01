# BAB 9 - `bootstrap_scons_gui.py`: KONSTANTA DATA STATIS (CREDITS & MENU)

---

## 1. Pendahuluan: Data Statis sebagai Tulang Punggung UI

Setelah memahami bagaimana opsi pengguna dikelola melalui [[BAB 8 - bootstrap_scons_gui.py MANAJEMEN OPSI (build_options.json)#^237532| `build_options.json`]], kini kita beralih ke **data statis** yang menjadi fondasi antarmuka menu curses. Data-data ini bersifat tetap (hard-coded) dan memberikan struktur serta konten untuk seluruh elemen UI yang terlihat oleh pengguna.

Pada Bab 9, kita akan membahas
1. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim|CREDITS_LINES - daftar kredit yang ditampilkan saat pengguna memilih menu Credits.]]
2. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#3. Konstanta `MENU` - Struktur Hierarki Menu Utama|`MENU` - struktur hierarki menu utama, yang menentukan urutan dan jenis setiap baris.]]
3. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih|`SELECTABLE` - daftar ID menu yang bisa dipilih oleh kursor (turunan dari `MENU`).]]
4. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0|`LICENSE_TEXT` - placeholder untuk teks lisensi GPL-3.0 yang harus diisi oleh pengguna.]]
5. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#6. Fitur-Fitur Baru di v2.4.0 yang Relevan dengan Bab Ini|Menu baru `license` dan `export_license` - diperkenalkan di v2.4.0 untuk manajemen lisensi.]]
6. [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#^47c189|Pembaruan `CREDITS_LINES` - penambahan kontributor AI dan versi build system.]]

Semua konstanta ini berada di dalam **heredoc `PYEOF_INNER`**, setelah fungsi `save_options()` dan sebelum fungsi-fungsi [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|render menu]]. Data statis ini dibaca langsung oleh:
- [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|`render_menu()`]]  untuk menggambar menu.
- [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]] - untuk menangani navigasi dan eksekusi aksi.
- [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#4. Fungsi `show_message_dialog_timed()` - Dialog dengan Hitung Mundur|`show_message_dialog()`]] - untuk menampilkan credits.
- [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]] - untuk menampilkan lisensi.

>[!quote] **Referensi Silang:**
> - `MENU` dan `SELECTABLE` menjadi panduan bagi `render_menu()` dalam menggambar setiap baris.
> - `CREDITS_LINES` ditampilkan oleh menu `[ Credits ]`.
> - `LICENSE_TEXT` ditampilkan oleh menu `[ View License ]` dan diekspor oleh `[ Export License ]`.

---

## 2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim

*(Lokasi Baris 739 - 748)*
```python
CREDITS_LINES = [
    "KOBI Studio",
    "",
    "Yohanes Alan Jasper (Koha) -- Creator",
    "Sabil / Billy -- Helper",
    "Claude (Anthropic) -- Merged the code and testing",
    "DeepSeek -- Wrote the documentation",
    "",
    f"Build System v{BOOTSTRAPPER_VERSION}",
]
```

### Tujuan
`CREDITS_LINES` adalah list of strings yang berisi informasi kredit untuk tim pengembang dan kontributor sistem build KOBI GDExtension. Daftar ini ditampilkan ketika pengguna memilih menu `[ Credits ]` di antarmuka curses.

### Struktur dan Isi

|Indeks|Teks|Deskripsi|
|---|---|---|
|0|`"KOBI Studio"`|Nama studio pengembang utama.|
|1|`""`|Baris kosong untuk spasi visual.|
|2|`"Yohanes Alan Jasper (Koha) -- Creator"`|Pendiri dan pencipta sistem.|
|3|`"Sabil / Billy -- Helper"`|Kontributor pendukung.|
|4|`"Claude (Anthropic) -- Merged the code and testing"`|AI dari Anthropic yang membantu menggabungkan dan menguji kode.|
|5|`"DeepSeek -- Wrote the documentation"`|AI yang menulis dokumentasi teknis (termasuk buku panduan ini).|
|6|`""`|Baris kosong sebelum versi.|
|7|`f"Build System v{BOOTSTRAPPER_VERSION}"`|Menampilkan versi build system (diambil dari konstanta `BOOTSTRAPPER_VERSION = "2.4.0"` di **Baris 48**).|

### Penggunaan di Menu
Ketika pengguna memilih `[ Credits ]` (ID `"credits"` di `MENU`), fungsi `show_message_dialog()` dipanggil dengan `CREDITS_LINES` sebagai argumen. Hasilnya adalah dialog sederhana yang menampilkan daftar kredit di tengah layar.

### Ekspor ke `CREDITS.md`
Pengguna juga dapat memilih `[ Export Credits ]` (ID `"export_credits"`) untuk mengekspor daftar kredit ke file `CREDITS.md` di folder proyek. Ini berguna untuk dokumentasi proyek atau jika pengguna ingin menyertakan kredit dalam distribusi kode.

>[!info] **Catatan:**
>`CREDITS_LINES` adalah data statis yang **tidak** dapat diedit melalui menu. Jika ingin mengubah kredit, pengguna harus mengedit file `jalankan_bootstrapper.sh` (di dalam heredoc `PYEOF_INNER`) dan menjalankan ulang bootstrapper.

---

## 3. Konstanta `MENU` - Struktur Hierarki Menu Utama

*(Lokasi Baris 751 - 774)*
```python
MENU = [
    ("head_build", "header", "BUILD OPTIONS"),
    ("mode", "option"),
    ("bits", "option"),
    ("linux", "option"),
    ("windows", "option"),
    ("jobs", "option"),
    ("head_godot", "header", "GODOT-CPP"),
    ("branch", "option"),
    ("api_version", "option"),
    ("cek_versi", "option"),
    ("cek_godot", "option"),
    ("lihat_semua", "option"),
    ("setup", "option"),
    ("bersihkan_lama", "option"),
    ("hapus", "option"),
    ("head_aksi", "header", "ACTIONS"),
    ("generate", "option"),
    ("credits", "option"),
    ("export_credits", "option"),
    ("license", "option"),
    ("export_license", "option"),
    ("keluar", "option"),
]
```

### Tujuan
`MENU` mendefinisikan **urutan** dan **jenis** setiap elemen yang ditampilkan di menu utama. Setiap elemen adalah tuple dengan format: ^65cd18
- Untuk **header** (judul bagian): `(id, "header", teks_header)`
- Untuk **option** (baris yang bisa dipilih): `(id, "option")`

### Struktur Menu
Menu terdiri dari 3 bagian utama yang dipisahkan oleh header:

#### Bagian 1: `BUILD OPTIONS` (Baris 1 - 6)

| ID           | Jenis  | Teks di Layar                 | Fungsi                   |
| ------------ | ------ | ----------------------------- | ------------------------ |
| `head_build` | header | `"BUILD OPTIONS"`             | Judul bagian             |
| `mode`       | option | `"Build mode : RELEASE"`      | Toggle `debug`/`release` |
| `bits`       | option | `"Architecture : 64-bit"`     | Toggle `64`/`32`         |
| `linux`      | option | `"Linux platform : ACTIVE"`   | Toggle aktif/nonaktif    |
| `windows`    | option | `"Windows platform : ACTIVE"` | Toggle aktif/nonaktif    |
| `jobs`       | option | `"Parallel jobs : auto"`      | Cycle `0`,`2`,`4`,`8`    |

#### Bagian 2: `GODOT-CPP` (Baris 7 - 15)

|ID|Jenis|Teks di Layar|Fungsi|
|---|---|---|---|
|`head_godot`|header|`"GODOT-CPP"`|Judul bagian|
|`branch`|option|`"godot-cpp version : 4.2"`|Toggle daftar versi|
|`api_version`|option|`"Target api_version : 4.7"`|Toggle daftar API (master only)|
|`cek_versi`|option|`"[ Update version list ]"`|Pull dari GitHub|
|`cek_godot`|option|`"[ Check installed Godot ]"`|Deteksi editor|
|`lihat_semua`|option|`"[ View all versions ]"`|Scan folder|
|`setup`|option|`"[ Setup godot-cpp ]"`|Clone & compile|
|`bersihkan_lama`|option|`"[ Clean up old versions ]"`|Hapus selain aktif|
|`hapus`|option|`"[ Delete godot-cpp ]"`|Hapus aktif|

#### Bagian 3: `ACTIONS` (Baris 16 – 22)

|ID|Jenis|Teks di Layar|Fungsi|
|---|---|---|---|
|`head_aksi`|header|`"ACTIONS"`|Judul bagian|
|`generate`|option|`"[ Save options + Generate! ]"`|Simpan + generate SConstruct|
|`credits`|option|`"[ Credits ]"`|Tampilkan kredit|
|`export_credits`|option|`"[ Export Credits ]"`|Ekspor ke CREDITS.md|
|`license`|option|`"[ View License ]"`|Tampilkan lisensi (v2.4.0)|
|`export_license`|option|`"[ Export License ]"`|Ekspor ke LICENSE (v2.4.0)|
|`keluar`|option|`"[ Quit ]"`|Keluar dari menu|

### Perbedaan Header vs Option
- **Header** (`kind == "header"`):
    - Tidak bisa dipilih oleh kursor.
    - Ditampilkan dengan style `STYLE["section"]` (biasanya bold dan warna berbeda).
    - Berfungsi sebagai pemisah antar bagian menu.
    - Teksnya diambil dari elemen ketiga tuple `(id, "header", teks)`.
    
- **Option** (`kind == "option"`):
    - Bisa dipilih oleh kursor (masuk dalam `SELECTABLE`).
    - Nilai teksnya diambil dari dictionary `LABELS` di dalam [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|`render_menu()`]].
    - Saat dipilih, pengguna bisa mengubah nilainya (LEFT/RIGHT) atau mengeksekusi aksi (ENTER/SPACE).

### Urutan Menu dan Navigasi
Urutan dalam `MENU` menentukan:
1. **Urutan tampilan** dari atas ke bawah.
2. **Urutan navigasi** saat pengguna menekan UP/DOWN.

Kursor akan bergerak dari satu **option** ke option berikutnya, melewati header tanpa berhenti.

---

## 4. Konstanta `SELECTABLE` - Daftar ID yang Bisa Dipilih

*(Lokasi Baris 775)*
```python
SELECTABLE = [item[0] for item in MENU if item[1] == "option"]
```

### Tujuan
`SELECTABLE` adalah list yang berisi **hanya ID dari elemen bertipe `"option"`** di `MENU`. List ini digunakan untuk:
- Menentukan berapa banyak posisi kursor yang tersedia.
- Mengakses elemen menu berdasarkan indeks kursor (`cursor`).
- Memvalidasi bahwa kursor tidak pernah menunjuk ke header.

### Isi `SELECTABLE`
Berdasarkan `MENU` di atas, `SELECTABLE` akan berisi:

```python
[
    "mode", "bits", "linux", "windows", "jobs",
    "branch", "api_version", "cek_versi", "cek_godot", 
    "lihat_semua", "setup", "bersihkan_lama", "hapus",
    "generate", "credits", "export_credits", 
    "license", "export_license", "keluar"
]
```
Total ada **19 option** yang bisa dipilih.

### Penggunaan di `main()`
Di loop utama [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]], variabel `cursor` bergerak dalam rentang `0` hingga `len(SELECTABLE) - 1`. Saat pengguna menekan UP/DOWN, `cursor` di-update dan digunakan untuk mengambil ID yang sedang dipilih:

```python
pilihan = SELECTABLE[cursor]
```

---

## 5. Konstanta `LICENSE_TEXT` - Teks Lisensi GPL-3.0

*(Lokasi Baris 733 – 736)*
```python
LICENSE_TEXT = r'''
[[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
[[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
'''
```

### Tujuan
`LICENSE_TEXT` adalah **placeholder** untuk teks lisensi GPL-3.0-or-later yang **harus diisi oleh pengguna** sebelum sistem build siap digunakan sepenuhnya. Ini adalah konsekuensi dari keputusan desain untuk menyertakan lisensi sebagai bagian dari bootstrapper, tetapi tidak otomatis mengunduh teks lisensi dari internet.

### Mengapa Tidak Otomatis Mengunduh?
Ada beberapa alasan:
1. **Kepatuhan hukum** - menyalin teks lisensi secara otomatis tanpa pengawasan pengguna bisa dianggap sebagai "penerimaan lisensi" yang tidak eksplisit.
2. **Koneksi internet** - bootstrapper dirancang untuk bekerja offline setelah cache versi di-pull. Mengunduh lisensi dari internet akan menambah ketergantungan.
3. **Kontrol pengguna** - pengguna bisa memilih untuk menggunakan lisensi yang berbeda atau memodifikasi teks untuk kebutuhan proyek mereka.

### Panduan Mengisi `LICENSE_TEXT`
Pengguna harus:
1. Buka `https://www.gnu.org/licenses/gpl-3.0.txt` di browser.
2. Salin seluruh teks lisensi.
3. Tempelkan di antara tanda `'''` dan `'''`, menggantikan baris placeholder.
4. Pastikan formatnya tetap sebagai **raw string** (`r'''...'''`) agar karakter backslash (`\`) tidak diinterpretasikan sebagai escape sequence.

### Penggunaan di Menu
`LICENSE_TEXT` digunakan oleh dua menu baru di v2.4.0:

|Menu|Fungsi|Pemanggilan|
|---|---|---|
|`[ View License ]`|Menampilkan lisensi dengan `show_scrollable_dialog()`|`show_scrollable_dialog(stdscr, "LICENSE (GPL-3.0-or-later)", LICENSE_TEXT.splitlines())`|
|`[ Export License ]`|Mengekspor ke file `LICENSE` di folder proyek|`with open("LICENSE", "w") as f: f.write(LICENSE_TEXT.strip("\n") + "\n")`|

### Fitur `show_scrollable_dialog()`
Karena teks lisensi GPL-3.0 sangat panjang (~700 baris), fungsi [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]] dirancang khusus untuk
- Menampilkan teks panjang dengan scroll (UP/DOWN, PgUp/PgDn, Home/End).
- Mendeteksi **judul bab** (baris huruf besar semua) dan meratakannya ke tengah secara otomatis.
- Tidak keluar jika pengguna meng-scroll dengan mouse wheel (berkat event mouse handling).

>[!quote] **Referensi Silang:**
>Lihat [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|Bab 10]] untuk implementasi `show_scrollable_dialog()` dan bagaimana ia menangani teks panjang.

---

## 6. Fitur-Fitur Baru di v2.4.0 yang Relevan dengan Bab Ini

### Menu `license` dan `export_license`
Dua menu baru ini adalah tambahan langsung di v2.4.0, menunjukkan komitmen proyek terhadap kepatuhan lisensi GPL-3.0. Dengan adanya menu ini:
- Pengguna dapat membaca lisensi kapan saja tanpa harus membuka browser.
- Pengguna dapat mengekspor lisensi ke file `LICENSE` di root proyek, yang diperlukan untuk distribusi kode sumber (sesuai ketentuan GPL-3.0).

### Pembaruan `CREDITS_LINES`
Dibandingkan versi sebelumnya, `CREDITS_LINES` v2.4.0 menambahkan: ^47c189
- **`"DeepSeek -- Wrote the documentation"`** - mengakui kontribusi DeepSeek dalam menulis dokumentasi teknis.
- **`f"Build System v{BOOTSTRAPPER_VERSION}"`** - menampilkan versi build system secara dinamis, memudahkan pelacakan versi.

### Konstanta `BOOTSTRAPPER_VERSION`
Meskipun tidak secara eksplisit dijelaskan di bab ini, `BOOTSTRAPPER_VERSION = "2.4.0"` didefinisikan di **Baris 104** dan digunakan di `CREDITS_LINES`. Ini adalah **satu-satunya tempat** di mana versi build system dideklarasikan, sehingga jika ada pembaruan di masa depan, cukup mengubah satu nilai.

---

## 7. Tabel Rangkuman Konstanta Data Statis

| Konstanta              | Lokasi Baris | Tipe          | Isi                         | Digunakan Oleh                                |
| ---------------------- | ------------ | ------------- | --------------------------- | --------------------------------------------- |
| `CREDITS_LINES`        | 739 - 748    | `list[str]`   | Daftar kredit tim           | Menu `[ Credits ]`, `[ Export Credits ]`      |
| `MENU`                 | 751 - 774    | `list[tuple]` | Struktur menu utama         | `render_menu()`, `main()`                     |
| `SELECTABLE`           | 775          | `list[str]`   | ID option yang bisa dipilih | `main()` (navigasi kursor)                    |
| `LICENSE_TEXT`         | 733 – 736    | `str`         | Teks placeholder GPL-3.0    | Menu `[ View License ]`, `[ Export License ]` |
| `BOOTSTRAPPER_VERSION` | 104          | `str`         | `"2.4.0"`                   | `CREDITS_LINES`                               |

---

## 8. Interaksi dengan Fungsi Lain

### [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|`render_menu()`]]
`render_menu()` menggunakan:
- `MENU` - untuk mengetahui urutan dan jenis elemen.
- `SELECTABLE` - untuk menentukan posisi kursor relatif terhadap elemen.
- `CREDITS_LINES` - tidak digunakan langsung; hanya ditampilkan oleh dialog terpisah. ^558366

### [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]]
`main()` menggunakan:
- `MENU` - tidak secara langsung, tapi `SELECTABLE` diambil dari `MENU`.
- `SELECTABLE` - untuk mengakses ID yang sedang dipilih oleh kursor.
- `CREDITS_LINES` - saat menu `[ Credits ]` dipilih.
- `LICENSE_TEXT` - saat menu `[ View License ]` atau `[ Export License ]` dipilih.

### [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]]
Fungsi ini dirancang khusus untuk menampilkan `LICENSE_TEXT` yang panjang, dengan kemampuan:
- Deteksi otomatis baris judul (huruf besar) untuk perataan tengah.
- Scroll dengan keyboard (UP/DOWN, PgUp/PgDn, Home/End).
- Resistensi terhadap mouse wheel yang tidak sengaja menutup dialog.

---

## 9. Kesimpulan

Pada bab ini, kita telah membahas **konstanta data statis** yang menjadi fondasi antarmuka menu curses. Kita mempelajari:
1. **`CREDITS_LINES`** - daftar kredit tim pengembang dan kontributor AI. ^9f35ed
2. **`MENU`** - struktur menu dengan 3 bagian utama: BUILD OPTIONS, GODOT-CPP, dan ACTIONS.
3. **`SELECTABLE`** - daftar ID option yang bisa dipilih, dihasilkan secara dinamis dari `MENU`.
4. **`LICENSE_TEXT`** - placeholder untuk teks lisensi GPL-3.0 yang harus diisi pengguna.
5. **Fitur baru v2.4.0** - menu `license` dan `export_license`, serta pembaruan `CREDITS_LINES` dengan versi build system.