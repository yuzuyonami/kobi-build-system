# BAB 20 - `LICENSE_TEXT` DAN MANAJEMEN LISENSI

---

## 1. Pendahuluan: Kepatuhan Hukum dalam Sistem Build

Setelah kita membahas seluruh aspek teknis sistem build - dari shell script hingga logika kompilasi - kini tiba saatnya untuk membahas **aspek non-teknis namun sangat penting**: manajemen lisensi. Sistem build KOBI GDExtension dirilis di bawah **GNU General Public License v3.0 or later (GPL-3.0-or-later)**, dan kepatuhan terhadap lisensi ini bukan hanya kewajiban hukum tetapi juga bagian dari **filosofi open source** yang dianut oleh proyek.

Pada Bab 20, kita akan membahas
1. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#2. Konstanta `LICENSE_TEXT` - Placeholder Teks Lisensi|Konstanta `LICENSE_TEXT` - placeholder untuk teks lisensi GPL-3.0 yang harus diisi oleh pengguna sebelum digunakan.]]
2. [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#3. Fungsi `show_scrollable_dialog()` - Menampilkan Teks Panjang|Fungsi `show_scrollable_dialog()` - mekanisme untuk menampilkan teks lisensi panjang di layar curses.]]
3.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#4. Menu `[ View License ]` - Menampilkan Lisensi di Curses|Menu `[ View License ]` - menampilkan lisensi di dalam antarmuka curses.]]
4.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#5. Menu `[ Export License ]` - Mengekspor Lisensi ke File|Menu `[ Export License ]` - mengekspor lisensi ke file `LICENSE` di folder proyek.]]
5.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#6. Alur Pengisian Lisensi - Panduan Langkah demi Langkah|Alur pengisian lisensi - panduan langkah demi langkah untuk mengisi `LICENSE_TEXT` dengan teks resmi dari [gnu.org](https://gnu.org).]]
6.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File|SPDX Header di Shell Script - bagaimana lisensi dinyatakan di awal `jalankan_bootstrapper.sh`.]]
7.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#8. Keterkaitan dengan GPL-3.0 - Implikasi dan Kewajiban|Keterkaitan dengan GPL-3.0 - implikasi dan kewajiban yang harus dipahami pengguna.]]
8.  [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#9. Tabel Rangkuman Komponen Lisensi|Tabel rangkuman - semua komponen terkait lisensi.]]

> [!quote] **Referensi Silang:**
> - `LICENSE_TEXT` didefinisikan di **Baris 734 - 736** dari [[BAB 9 - `bootstrap_scons_gui.py` KONSTANTA DATA STATIS (CREDITS & MENU)#2. Konstanta `CREDITS_LINES` - Daftar Kredit Tim|`bootstrap_scons_gui.py`]].
> - [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#6. Fungsi `show_scrollable_dialog()` - Dialog untuk Teks Panjang|`show_scrollable_dialog()`]] dijelaskan secara teknis di Bab 10, tetapi di sini kita bahas dalam konteks lisensi.
> - [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `license` - View License (v2.4.0)|Menu `license`]] dan [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#lisensi|`export_license`]] dieksekusi di `main()` (Bab 11, Baris 1840 - 1848).
> - SPDX header lisensi ada di **Baris 2 - 11** dari [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)|`jalankan_bootstrapper.sh`.]]

---

## 2. Konstanta `LICENSE_TEXT` - Placeholder Teks Lisensi

*(Lokasi Baris 733 - 736)*
```python
LICENSE_TEXT = r'''
[[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
[[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
'''
```

### Tujuan
`LICENSE_TEXT` adalah **string placeholder** yang berisi teks lisensi GPL-3.0-or-later. Namun, **isi defaultnya bukanlah teks lisensi yang sebenarnya** - melainkan instruksi kepada pengguna untuk menempelkan teks lisensi dari sumber resmi.

### Mengapa Tidak Diisi Otomatis?
Ada beberapa alasan kuat mengapa bootstrapper **tidak** mengunduh atau menyertakan teks lisensi secara otomatis:
1. **Kepatuhan Hukum** - menyalin teks lisensi secara otomatis tanpa pengawasan pengguna bisa dianggap sebagai "penerimaan lisensi" yang tidak eksplisit. Dengan meminta pengguna untuk secara manual menempelkan teks, kami memastikan bahwa mereka **sadar** bahwa mereka menerima lisensi GPL-3.0.
2. **Koneksi Internet** - bootstrapper dirancang untuk bekerja **offline** setelah cache versi di-pull. Mengunduh lisensi dari internet akan menambah ketergantungan pada koneksi internet, yang bertentangan dengan filosofi "bekerja di mana saja".
3. **Kontrol Pengguna** - beberapa pengguna mungkin ingin menggunakan **lisensi yang berbeda** (misal LGPL, MIT, atau lisensi proprietary). Dengan menyediakan placeholder, kami memberi fleksibilitas kepada pengguna untuk mengganti teks lisensi sesuai kebutuhan mereka.
4. **Ukuran File** - teks lisensi GPL-3.0 memiliki panjang sekitar **700 baris** (~34 KB). Menyertakannya sebagai string literal di dalam script akan menambah ukuran file secara signifikan, meskipun tidak terlalu besar untuk standar modern.

### Raw String (`r'''...'''`)

*(Lokasi Baris 733)*
```python
LICENSE_TEXT = r'''...'''
```

Penggunaan **raw string** (`r'''...'''`) memastikan bahwa karakter backslash (`\`) di dalam teks lisensi tidak diinterpretasikan sebagai escape sequence oleh Python. Ini penting karena teks lisensi GPL-3.0 mengandung banyak backslash (misal dalam contoh kode atau path).

### Instruksi di Placeholder

*(Lokasi Baris 734 - 735)*
```python
[[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
[[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
```

Dua baris placeholder memberikan instruksi yang jelas:
- **Baris 1** - instruksi untuk menempelkan teks lisensi.
- **Baris 2** - URL resmi tempat teks lisensi dapat diunduh.

### Dampak Jika Tidak Diisi
Jika pengguna **tidak** mengisi `LICENSE_TEXT` dan mencoba menggunakan menu `[ View License ]` atau `[ Export License ]`:
- **`[ View License ]`** - akan menampilkan placeholder (dua baris instruksi) - tidak ada teks lisensi yang ditampilkan.
- **`[ Export License ]`**- akan mengekspor placeholder ke file `LICENSE` - file tersebut **tidak** berisi lisensi GPL-3.0 yang sebenarnya.

Ini adalah **perilaku yang diinginkan** - karena pengguna secara eksplisit harus mengambil tindakan untuk menyertakan lisensi.

---

## 3. Fungsi `show_scrollable_dialog()` - Menampilkan Teks Panjang

*(Lokasi Baris 982 dan 1840)*

Fungsi `show_scrollable_dialog()` telah dijelaskan secara teknis di [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#^0438b0|bab 10]]. Di sini, kita akan membahasnya dalam **konteks lisensi** – mengapa fungsi ini sangat cocok untuk menampilkan teks lisensi.

### Karakteristik Teks Lisensi GPL-3.0

| Aspek    | Karakteristik                                                   |
| -------- | --------------------------------------------------------------- |
| Panjang  | ~700 baris                                                      |
| Format   | Teks biasa dengan judul bab (huruf besar)                       |
| Struktur | Pembukaan, 17 pasal definisi/ketentuan, dan penutup             |
| Lebar    | ~65 – 70 karakter per baris (sudah di-_wrap_ oleh sumber resmi) |

### Mengapa `show_scrollable_dialog()` Cocok untuk Lisensi?
1. **Scroll** - dengan 700 baris, layar tidak mungkin menampilkan semuanya sekaligus. Scroll (UP/DOWN, PgUp/PgDn, Home/End) memungkinkan navigasi yang nyaman.
2. **Deteksi judul bab** - fungsi ini secara otomatis mendeteksi baris yang **semua huruf besar** (misal `"PREAMBLE"`, `"TERMS AND CONDITIONS"`, `"0. Definitions."`) dan meratakannya ke tengah dengan style bold. Ini membuat struktur lisensi lebih mudah dibaca.
3. **Resistensi terhadap mouse** - event mouse (termasuk scroll wheel) dikonsumsi tetapi **tidak** menutup dialog. Ini mencegah pengguna tidak sengaja menutup lisensi saat mencoba meng-scroll dengan mouse.
4. **Indikator posisi** - menampilkan persentase posisi scroll (misal `-- 45% --`), membantu pengguna mengetahui seberapa jauh mereka telah membaca.

### Kode Pemanggilan

```python
show_scrollable_dialog(stdscr, "LICENSE (GPL-3.0-or-later)", LICENSE_TEXT.splitlines())
```

- **Judul** – `"LICENSE (GPL-3.0-or-later)"` memberi tahu pengguna lisensi apa yang sedang mereka lihat.
- **`LICENSE_TEXT.splitlines()`** - mengubah string multi-line menjadi list of lines, yang merupakan format yang diharapkan oleh `show_scrollable_dialog()`.


---

## 4. Menu `[ View License ]` - Menampilkan Lisensi di Curses

*(Lokasi Baris 1839 - 1840)*
```python
elif pilihan == "license":
    show_scrollable_dialog(stdscr, "LICENSE (GPL-3.0-or-later)", LICENSE_TEXT.splitlines())
```

### Tujuan
Menu `[ View License ]` memungkinkan pengguna **membaca lisensi** langsung di dalam antarmuka curses, tanpa harus membuka browser atau file eksternal. Ini adalah fitur **aksesibilitas** yang memudahkan pengguna untuk memahami hak dan kewajiban mereka.

### Kapan Pengguna Menggunakan Ini?
- **Saat pertama kali menggunakan sistem** - untuk memahami lisensi proyek.
- **Sebelum mendistribusikan kode** - untuk memastikan kepatuhan terhadap GPL-3.0.
- **Untuk referensi** - saat menulis dokumentasi atau atribusi.

### Apa yang Terjadi Jika `LICENSE_TEXT` Belum Diisi?
Seperti yang telah dijelaskan, jika `LICENSE_TEXT` masih berisi placeholder, dialog akan menampilkan dua baris instruksi. Ini adalah **indikator visual** bagi pengguna bahwa mereka perlu mengisi lisensi.

### Contoh Tampilan

```text
═══════════════════════════════════════════════════════════════════
                   LICENSE (GPL-3.0-or-later)
        UP/DOWN scroll  |  PgUp/PgDn page  |  Home/End jump  |  Q/ESC/ENTER close
═══════════════════════════════════════════════════════════════════
                    GNU GENERAL PUBLIC LICENSE
                       Version 3, 29 June 2007
 Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
 Everyone is permitted to copy and distribute verbatim copies
 of this license document, but changing it is not allowed.
                            Preamble
  The GNU General Public License is a free, copyleft license for
  software and other kinds of works.
  The licenses for most software and other practical works are designed
  to take away your freedom to share and change the works.  By contrast,
  the GNU General Public License is intended to guarantee your freedom to
  share and change all versions of a program--to make sure it remains free
  software for all its users.
  ...
```

---

## 5. Menu `[ Export License ]` - Mengekspor Lisensi ke File

(Lokasi di `main()`: Baris 1842 - 1848)*
```python
elif pilihan == "export_license":
    try:
        with open("LICENSE", "w", encoding="utf-8") as f:
            f.write(LICENSE_TEXT.strip("\n") + "\n")
        log_lines.append("OK: LICENSE exported successfully.")
    except Exception as e:
        log_lines.append(f"FAILED to export LICENSE: {e}")
```

### Tujuan
Menu `[ Export License ]` mengekspor teks lisensi ke file **`LICENSE`** di folder proyek. Ini diperlukan untuk:
- **Distribusi kode sumber** - GPL-3.0 mewajibkan penyertaan salinan lisensi bersama kode sumber.
- **Kepatuhan hukum** - pengguna yang mendistribusikan kode KOBI harus menyertakan file `LICENSE`.
- **Dokumentasi proyek** - file `LICENSE` adalah standar di repositori open source.

### Format File
File `LICENSE` ditulis dengan:
- **Encoding UTF-8** - mendukung karakter khusus (misal simbol ©).
- **Teks polos** - tanpa format Markdown atau HTML.
- **Akhir newline** - `LICENSE_TEXT.strip("\n") + "\n"` memastikan file diakhiri dengan newline (best practice).

### Nama File
Nama file **`LICENSE`** (tanpa ekstensi) adalah **konvensi standar** di dunia open source. Ini diakui oleh:
- GitHub - menampilkan badge lisensi di repository.
- Package managers - beberapa package manager membaca file ini untuk menentukan lisensi.
- Pengguna - mudah dikenali sebagai file lisensi.

### Penanganan Error

*(Lokasi baris 1843 - 1848)*
```python
try:
    # ... write file
    log_lines.append("OK: LICENSE exported successfully.")
except Exception as e:
    log_lines.append(f"FAILED to export LICENSE: {e}")
```

Jika terjadi error (misal permission denied, disk full), pesan error dicatat di `log_lines` dan ditampilkan di menu utama. Ini memberi tahu pengguna bahwa ekspor gagal tanpa menghentikan aplikasi.

### Apa yang Terjadi Jika `LICENSE_TEXT` Belum Diisi?
Jika `LICENSE_TEXT` masih berisi placeholder, file `LICENSE` yang diekspor akan berisi:
```text
[[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
[[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
```

Ini **bukan** lisensi GPL-3.0 yang valid. Oleh karena itu, sangat disarankan untuk mengisi `LICENSE_TEXT` sebelum mengekspor.

---

## 6. Alur Pengisian Lisensi - Panduan Langkah demi Langkah

Berikut adalah panduan lengkap untuk mengisi `LICENSE_TEXT` dengan teks lisensi GPL-3.0 yang benar:

> [!todo]+ Persiapan
> ### Langkah 1: Buka File `jalankan_bootstrapper.sh`
> Buka file `jalankan_bootstrapper.sh` di editor teks (misal VS Code, Sublime Text, gedit, atau nano).
> 
> ### Langkah 2: Cari `LICENSE_TEXT`
> Cari konstanta `LICENSE_TEXT` di dalam heredoc `PYEOF_INNER`. Biasanya terletak di sekitar **Baris 733 - 736** (dalam file yang digenerate, tetapi di shell script, lokasi persisnya tergantung pada struktur heredoc dan juga versi updatenya itu sendiri).
> 
> ### Langkah 3: Buka Sumber Resmi
> Buka browser dan kunjungi <a href="https://www.gnu.org/licenses/gpl-3.0.txt">gpl-3.0.txt</a>
> 
>
> > [!todo]- Langkah Selanjutnya
> > ### Langkah 4: Salin Seluruh Teks
> > - **Ctrl+A** (select all) - pilih seluruh teks.
> > - **Ctrl+C** (copy) - salin ke clipboard.
> > 
> > ### Langkah 5: Tempel di Antara Tanda `'''`
> > 
> > Di editor, temukan placeholder:
> > ```python
> > LICENSE_TEXT = r'''
> > [[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
> > [[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
> > '''
> > ```
> > 
> > **Hapus** dua baris placeholder, lalu **tempel** (Ctrl+V) teks lisensi di antara `r'''` dan `'''`.
> > 
> > Hasil akhir:
> > ```python
> > LICENSE_TEXT = r'''
> >                     GNU GENERAL PUBLIC LICENSE
> >                        Version 3, 29 June 2007
> >  Copyright (C) 2007 Free Software Foundation, Inc. <https://fsf.org/>
> >  Everyone is permitted to copy and distribute verbatim copies
> >  of this license document, but changing it is not allowed.
> >                             Preamble
> >   The GNU General Public License is a free, copyleft license for
> >   software and other kinds of works.
> >   ... (seluruh teks lisensi) ...
> > '''
> > ```
> > 
> > ### Langkah 6: Simpan File
> > Simpan `jalankan_bootstrapper.sh`. Pastikan tidak ada error sintaks (misal tanda kutip yang tidak seimbang).
> > 
> > ### Langkah 7: Uji
> > Jalankan `jalankan_bootstrapper.sh`, buka menu, dan pilih `[ View License ]`. Teks lisensi harus muncul dengan benar.
> > 
> > ### Langkah 8: Ekspor
> > Pilih `[ Export License ]` untuk menghasilkan file `LICENSE` di folder proyek.

---

## 7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File

*(Lokasi Baris 2 - 11)*
```bash
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yohanes Alan Jasper (Koha) / KOBI Studio
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version. See LICENSE in this folder for
# the full license text.
```

### Tujuan
SPDX header adalah **deklarasi lisensi** yang terstandarisasi, memudahkan alat otomatis untuk mendeteksi lisensi suatu file. Ini adalah **praktik terbaik** dalam pengembangan open source.

### Komponen SPDX Header

|Komponen|Nilai|Deskripsi|
|---|---|---|
|`SPDX-License-Identifier`|`GPL-3.0-or-later`|Menyatakan bahwa file ini dilisensikan di bawah GPL-3.0 atau versi yang lebih baru.|
|`Copyright (C) 2026 Yohanes Alan Jasper (Koha) / KOBI Studio`|Pemegang hak cipta|Nama pencipta dan tahun pembuatan.|
|Teks GPL|"This program is free software..."|Pernyataan singkat tentang hak pengguna di bawah GPL.|

### Mengapa SPDX Penting?
- **Deteksi otomatis** - alat seperti `scancode-toolkit`, `licensee`, dan GitHub sendiri dapat mendeteksi lisensi dari SPDX header.
- **Kepatuhan** - memudahkan audit lisensi dalam proyek besar.
- **Kejelasan** - setiap file secara eksplisit menyatakan lisensinya, tidak ada ambiguitas.

### Kaitan dengan `LICENSE_TEXT`
SPDX header di shell script **merujuk** ke file `LICENSE` yang akan diekspor oleh menu `[ Export License ]`:

```bash
# ... See LICENSE in this folder for the full license text.
```

Ini memberi tahu pengguna bahwa teks lisensi lengkap ada di file `LICENSE` di folder yang sama. Dengan demikian, jika pengguna mengekspor lisensi, mereka memenuhi kewajiban untuk menyertakan teks lengkap.

---

## 8. Keterkaitan dengan GPL-3.0 - Implikasi dan Kewajiban

### Apa Itu GPL-3.0-or-later?
- **GPL-3.0** – GNU General Public License versi 3, lisensi copyleft yang kuat.
- **"-or-later"** – berarti pengguna dapat menggunakan lisensi ini **atau versi yang lebih baru** dari GPL (misal GPL-4.0 jika dirilis di masa depan).

### Kewajiban Pengguna
Di bawah GPL-3.0, pengguna yang **mendistribusikan** kode (baik dalam bentuk sumber maupun biner) memiliki kewajiban:

1. **Menyertakan salinan lisensi** - file `LICENSE` harus disertakan.
2. **Menyertakan pemberitahuan hak cipta** - header copyright harus dipertahankan.
3. **Menyediakan kode sumber** - jika mendistribusikan binary, kode sumber harus tersedia.
4. **Mencatat perubahan** - jika mengubah kode, perubahan harus didokumentasikan.

### Bagaimana Sistem Build Membantu Kepatuhan?

|Fitur|Membantu Kepatuhan|
|---|---|
|SPDX header di shell script|Mendeklarasikan lisensi di setiap file|
|`[ View License ]`|Memudahkan pengguna membaca lisensi|
|`[ Export License ]`|Memudahkan pengguna menyertakan file `LICENSE`|
|`CREDITS_LINES`|Memberikan atribusi kepada pencipta|

---

## 9. Tabel Rangkuman Komponen Lisensi

| Komponen                   | Lokasi                                    | Fungsi                                 | Status                                    |
| -------------------------- | ----------------------------------------- | -------------------------------------- | ----------------------------------------- |
| SPDX header                | `jalankan_bootstrapper.sh` Baris 2 - 11   | Deklarasi lisensi di shell script      | Otomatis                                  |
| `BOOTSTRAPPER_VERSION`     | `bootstrap_scons_gui.py` Baris 79         | Versi sistem (muncul di credits)       | Otomatis                                  |
| `LICENSE_TEXT`             | `bootstrap_scons_gui.py` Baris 733 - 736  | Placeholder teks lisensi               | Harus diisi manual                        |
| `show_scrollable_dialog()` | `bootstrap_scons_gui.py` Baris 982 - 1065 | Menampilkan teks panjang dengan scroll | Otomatis                                  |
| Menu `[ View License ]`    | `main()` Baris 816                        | Menampilkan lisensi di curses          | Otomatis (bergantung pada `LICENSE_TEXT`) |
| Menu `[ Export License ]`  | `main()` Baris 817                        | Mengekspor lisensi ke `LICENSE`        | Otomatis (bergantung pada `LICENSE_TEXT`) |
| `CREDITS_LINES`            | `bootstrap_scons_gui.py` Baris 739 - 748  | Atribusi pencipta                      | Otomatis                                  |

---

## 10 Troubleshooting Lisensi

|Masalah|Penyebab|Solusi|
|---|---|---|
|`[ View License ]` menampilkan placeholder|`LICENSE_TEXT` belum diisi|Ikuti panduan di sub-bab 20.6|
|`[ Export License ]` menghasilkan file dengan placeholder|`LICENSE_TEXT` belum diisi|Ikuti panduan di sub-bab 20.6|
|Error "Permission denied" saat ekspor|Tidak ada izin tulis di folder|`chmod +w .` atau jalankan di folder yang dapat ditulis|
|Teks lisensi tidak terlihat di dialog|Terminal terlalu kecil|Perbesar terminal (minimal 80x24)|
|Scroll tidak berfungsi di dialog lisensi|Terminal tidak mendukung keypad|Gunakan tombol Page Up/Down atau Home/End sebagai alternatif|

---

## 11. Praktik Terbaik untuk Manajemen Lisensi

1. **Isi `LICENSE_TEXT` segera setelah bootstrapper dijalankan pertama kali** - jangan menunda.
2. **Gunakan `[ Export License ]` untuk menghasilkan file `LICENSE`** - ini memastikan format yang benar.
3. **Sertakan file `LICENSE` di setiap distribusi kode** - baik melalui Git, zip, atau tarball.
4. **Pertahankan SPDX header di semua file** - jika menambahkan file baru, tambahkan header yang sama.
5. **Jika menggunakan lisensi yang berbeda** - ganti `LICENSE_TEXT` dan SPDX header sesuai kebutuhan.
6. **Perbarui tahun hak cipta** - setiap tahun baru, perbarui `Copyright (C) 2026 ...` menjadi `2026-2027` atau `2027`.

---

## 12. Kesimpulan

Pada bab ini, kita telah membahas **manajemen lisensi** dalam sistem build KOBI GDExtension. Kita mempelajari:
1. **Konstanta `LICENSE_TEXT`** - placeholder untuk teks lisensi GPL-3.0 yang **harus diisi manual** oleh pengguna.
2. **Fungsi `show_scrollable_dialog()`** - mekanisme untuk menampilkan teks lisensi panjang dengan scroll, deteksi judul bab, dan resistensi terhadap mouse.
3. **Menu `[ View License ]`** - menampilkan lisensi di dalam antarmuka curses.
4. **Menu `[ Export License ]`** - mengekspor lisensi ke file `LICENSE` di folder proyek.
5. **Alur pengisian lisensi** - panduan langkah demi langkah untuk mengisi `LICENSE_TEXT` dengan teks resmi dari [gnu.org](https://gnu.org).
6. **SPDX header di shell script** - deklarasi lisensi di awal file menggunakan standar SPDX.
7. **Keterkaitan dengan GPL-3.0** - implikasi dan kewajiban yang harus dipahami pengguna.
8. **Troubleshooting dan praktik terbaik** – solusi untuk masalah umum dan rekomendasi untuk kepatuhan lisensi.