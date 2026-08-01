# BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)

---

## 1. Pendahuluan: Fondasi dari Seluruh Sistem

Setelah kita memahami latar belakang, filosofi, dan alur eksekusi dari sistem build KOBI GDExtension di [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#1. Pendahuluan Mengapa Dokumentasi Ini Dibutuhkan?|Bab 1]], kini saatnya membahas **baris demi baris** dari shell script `jalankan_bootstrapper.sh`. Bab ini adalah fondasi dari seluruh sistem – di sinilah interpreter ditentukan, hak cipta dinyatakan, dan direktori kerja dikunci.

Pada Bab 2, kita akan membahas **bagian paling awal** dari `jalankan_bootstrapper.sh`:
1. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#2. ` !/bin/bash` - Penanda Interpreter|`#!/bin/bash` - penanda interpreter yang memastikan script dijalankan dengan Bash.]]
2. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#3. Komentar Pembuka dan Penjelasan Tujuan|Komentar pembuka dan SPDX header - deklarasi lisensi dan hak cipta (Baris 1 - 18).]]
3. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#4. Perintah `cd "$(dirname "$0")"` - Mengunci Direktori Kerja|`cd "$(dirname "$0")"` - mengunci direktori kerja ke lokasi script.]]
4. [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#5. Variabel `SCRIPT_ABS="$(readlink -f "$0")"` - Mendapatkan Path Absolut|`SCRIPT_ABS="$(readlink -f "$0")"` - mendapatkan path absolut dari script untuk keperluan referensi.]]

Semua kode dalam bab ini berada di **awal** dari `jalankan_bootstrapper.sh`, sebelum logika self-heal dan self-relaunch (Bab 3 - 4).

> [!quote] **Referensi Silang:**
> - Variabel `SCRIPT_ABS` yang didefinisikan di bab ini akan digunakan di [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#2. Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`|Bab 3]] untuk pembuatan `.desktop` dan [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#2. Kondisi `[ ! -t 0 ]` - Deteksi Terminal Non-Interaktif|Bab 4]] untuk self-relaunch.
> - SPDX header di sini merujuk ke file `LICENSE` yang dijelaskan di [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File|Bab 20.]]

---

## 2. `#!/bin/bash` - Penanda Interpreter

*(Lokasi Baris 1)*
```bash
#!/bin/bash
```

### Tujuan
Baris pertama ini adalah **shebang** - sebuah mekanisme di sistem Unix/Linux yang memberi tahu kernel interpreter mana yang harus digunakan untuk menjalankan file ini. Ketika pengguna menjalankan `./jalankan_bootstrapper.sh` (atau mengklik file di file manager), sistem membaca baris ini dan menjalankan script dengan **Bash** (`/bin/bash`).

### Mengapa Bash, Bukan Sh?
- **`/bin/sh`** - adalah shell POSIX standar yang ringan, tetapi tidak mendukung semua fitur Bash (misal array, `[[ ]]`, heredoc dengan delimiter yang kompleks).
- **`/bin/bash`** - adalah Bourne Again Shell yang mendukung fitur-fitur modern yang digunakan di script ini, seperti:
    - Heredoc dengan delimiter (`<< 'PYEOF_INNER'`).
    - `readlink -f` untuk mendapatkan path absolut.
    - `[[ ]]` untuk conditional expression.
    - Array (tidak digunakan langsung, tetapi tersedia jika diperlukan).

### Portabilitas
Meskipun `#!/bin/bash` mengasumsikan Bash terinstall di `/bin/bash` (lokasi standar di sebagian besar distribusi Linux), ada beberapa sistem (misal BSD, atau Linux dengan Bash di `/usr/bin/bash`) yang mungkin berbeda. Namun, untuk keperluan sistem build KOBI yang ditargetkan untuk distribusi Linux mainstream (Ubuntu, Debian, Fedora, Arch), lokasi ini aman.

---

## 3. Komentar Pembuka dan Penjelasan Tujuan

*(Lokasi: Baris 2 -18)*
```bash
# ============================================================
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yohanes Alan Jasper (Koha) / KOBI Studio
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version. See LICENSE in this folder for
# the full license text.
# ============================================================
#
# jalankan_bootstrapper.sh
# ------------------------
# File ini SATU-SATUNYA yang perlu kamu klik/jalanin.
# Begitu dieksekusi, dia bakal:
#   1. Nulis ulang bootstrap_scons_gui.py (generate dari isi yang di-embed di sini)
#   2. Langsung jalanin python3 bootstrap_scons_gui.py
# Jadi gak perlu 2 file terpisah lagi, cukup 1 .sh ini aja.
```

### SPDX Header – Deklarasi Lisensi

*(Lokasi Baris 3 - 10)*
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


|Komponen|Nilai|Deskripsi|
|---|---|---|
|`SPDX-License-Identifier`|`GPL-3.0-or-later`|Menyatakan lisensi file ini di bawah GPL-3.0 atau versi yang lebih baru.|
|`Copyright (C) 2026 Yohanes Alan Jasper (Koha) / KOBI Studio`|Pemegang hak cipta|Nama pencipta dan tahun pembuatan.|
|"This program is free software..."|Pernyataan hak pengguna|Ringkasan singkat tentang hak pengguna di bawah GPL.|
|"See LICENSE in this folder..."|Referensi ke file lisensi|Mengarahkan pengguna ke file `LICENSE` untuk teks lengkap.|

SPDX header ini adalah **praktik terbaik** dalam pengembangan open source karena
- Memudahkan alat otomatis (seperti `licensee` atau GitHub) untuk mendeteksi lisensi.
- Memberikan kepastian hukum yang jelas bagi pengguna dan kontributor.
- Menunjukkan komitmen proyek terhadap open source dan kepatuhan lisensi.

### Komentar Deskriptif - Filosofi Satu File

*(Lokasi Baris 12 - 19)*
```bash
#
# jalankan_bootstrapper.sh
# ------------------------
# File ini SATU-SATUNYA yang perlu kamu klik/jalanin.
# Begitu dieksekusi, dia bakal:
#   1. Nulis ulang bootstrap_scons_gui.py (generate dari isi yang di-embed di sini)
#   2. Langsung jalanin python3 bootstrap_scons_gui.py
# Jadi gak perlu 2 file terpisah lagi, cukup 1 .sh ini aja.
```

Komentar ini menjelaskan **filosofi utama** dari sistem bootstrapper:
1. **Satu file** - pengguna hanya perlu meng-klik satu file `.sh`.
2. **Generatif** - script menulis ulang file Python secara otomatis dari konten yang di-_embed_.
3. **Self-contained** - tidak perlu file terpisah yang harus disalin atau diunduh.

Ini adalah **pengantar bagi pengguna** tentang apa yang akan terjadi ketika mereka menjalankan script - memberikan kejelasan dan mengurangi kecemasan (terutama bagi pengguna yang tidak terbiasa dengan terminal).

---

## 4. Perintah `cd "$(dirname "$0")"` - Mengunci Direktori Kerja

*(Lokasi Baris 21)*
```bash
cd "$(dirname "$0")"
```

### Tujuan

Perintah ini mengubah **direktori kerja saat ini** (current working directory) ke folder tempat `jalankan_bootstrapper.sh` berada. Ini penting karena:
1. **Konsistensi** - terlepas dari dari mana pengguna menjalankan script (misal dari terminal dengan `~/Downloads/jalankan_bootstrapper.sh` atau dari file manager), script akan selalu beroperasi di direktori yang sama dengan file script itu sendiri.
2. **Path relatif** - semua operasi file selanjutnya (seperti `cat > bootstrap_scons_gui.py`) akan menggunakan path relatif terhadap direktori script, sehingga tidak perlu hard-code path absolut.
3. **Keamanan** - mencegah script secara tidak sengaja menulis file di lokasi yang tidak diinginkan (misal jika pengguna menjalankan dari `~`).

### Komponen Perintah

|Komponen|Fungsi|
|---|---|
|`$0`|Nama script yang sedang dijalankan (misal `./jalankan_bootstrapper.sh` atau `~/Downloads/jalankan_bootstrapper.sh`).|
|`dirname "$0"`|Mengambil direktori dari path script (misal `./` atau `/home/user/Downloads`).|
|`"$(...)"`|Substitusi command – output dari `dirname` digunakan sebagai argumen `cd`.|
|`cd ...`|Mengubah direktori kerja ke path yang dihasilkan.|

### Contoh

Jika pengguna menjalankan:
```bash
~/Downloads/jalankan_bootstrapper.sh
```
Maka:

- `$0` = `~/Downloads/jalankan_bootstrapper.sh`
- `dirname "$0"` = `~/Downloads`
- `cd ~/Downloads` → direktori kerja menjadi `~/Downloads`.

Jika pengguna menjalankan dari folder yang sama:

```bash
./jalankan_bootstrapper.sh
```

- `$0` = `./jalankan_bootstrapper.sh` 
- `dirname "$0"` = `.`
- `cd .` → tetap di folder yang sama.

### Mengapa Tidak Menggunakan `$(pwd)`?
`$(pwd)` mengembalikan direktori kerja **saat ini**, yang bisa berbeda dari lokasi script. `dirname "$0"` selalu mengembalikan lokasi script, terlepas dari di mana pengguna berdiri saat menjalankannya. Ini adalah pendekatan yang lebih aman dan dapat diprediksi.

---

## 5. Variabel `SCRIPT_ABS="$(readlink -f "$0")"` -  Mendapatkan Path Absolut

*(Lokasi Baris 32)*
```bash
SCRIPT_ABS="$(readlink -f "$0")"
```

### Tujuan
Variabel `SCRIPT_ABS` menyimpan **path absolut** dari script `jalankan_bootstrapper.sh`. Ini digunakan di beberapa bagian script:
- [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#2. Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`|Bab 3 - untuk membuat file `.desktop` dengan `Exec=bash "$SCRIPT_ABS"`.]]
- [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch|Bab 4 - untuk self-relaunch: `SCRIPT_PATH="$(readlink -f "$0")"` (variabel serupa).]]
- [[BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN#BAB 17 - EKSEKUSI AKHIR SHELL DAN PENUTUPAN|Bab 17 - sebagai referensi path absolut saat script dieksekusi.]]

### Mengapa `readlink -f`?

|Perintah|Output|Kelebihan|
|---|---|---|
|`$0`|`./jalankan_bootstrapper.sh`|Path relatif (tidak absolut).|
|`dirname "$0"`|`.`|Hanya direktori, bukan full path.|
|`pwd`|`/home/user/Downloads`|Direktori kerja saat ini (bisa berbeda).|
|`readlink -f "$0"`|`/home/user/Downloads/jalankan_bootstrapper.sh`|**Path absolut** yang selalu benar.|

`readlink -f` melakukan:
1. **Resolusi path** - mengubah path relatif menjadi absolut.
2. **Follow symlink** - jika script adalah symbolic link, `readlink -f` mengikuti link ke target sebenarnya.
3. **Normalisasi** - menghilangkan `..` dan `.` dari path.

### Portabilitas
`readlink -f` adalah perintah GNU yang tersedia di sebagian besar distribusi Linux. Untuk sistem yang lebih eksotis (misal BSD atau macOS), `readlink -f` mungkin tidak tersedia. Namun, karena target sistem build KOBI adalah Linux, ini bukan masalah.

### Alternatif jika `readlink -f` Tidak Tersedia
Jika ada kekhawatiran tentang portabilitas, alternatifnya adalah:

*(Kode Alternatif)*
```bash
SCRIPT_ABS="$(cd "$(dirname "$0")" && pwd)/$(basename "$0")"
```

Namun, pendekatan ini tidak menangani symlink dengan baik. `readlink -f` adalah pilihan yang lebih robust.

---

## 6. Blok Komentar tentang Self-Heal & .desktop

*(Lokasi Baris 23 - 31)*
```bash
# ============================================================
# BIKIN LAUNCHER .desktop OTOMATIS + SELF-HEAL PERMISSION
# Biar file ini beneran "jadi program" begitu diklik, tanpa perlu
# klik kanan -> Properties -> "Allow run as program" tiap kali
# pindah/salin ke folder proyek baru. Sekali generate, dia bikin
# file .desktop di folder yang sama, langsung di-chmod +x, dan
# ini sendiri juga di-chmod +x ulang tiap kali dijalankan (self-heal
# kalau suatu saat permission-nya kebalik lagi).
# ============================================================
```

### Tujuan
Komentar ini menjelaskan **filosofi desain** di balik pembuatan `.desktop` dan self-heal permission yang akan diimplementasikan di **Bab 3**. Poin-poin penting:
1. **Launcher .desktop otomatis** - script membuat file `.desktop` sehingga pengguna dapat meng-klik ikon di file manager.
2. **Self-heal permission** - script secara otomatis memperbaiki izin eksekusi (`chmod +x`) setiap kali dijalankan, sehingga pengguna tidak perlu melakukannya secara manual.
3. **Portabilitas** - semua ini terjadi otomatis setiap kali script dipindahkan ke folder baru.

### Mengapa Komentar Ini Penting?
Komentar ini adalah **dokumentasi inline** yang memberi tahu pembaca (dan pengembang) tentang apa yang akan terjadi selanjutnya. Ini adalah praktik baik dalam penulisan kode – menjelaskan **"mengapa"** sebelum kode itu sendiri.

---

## 7. Tabel Rangkuman

| Komponen                           | Lokasi Baris | Fungsi                                     |
| ---------------------------------- | ------------ | ------------------------------------------ |
| Shebang `#!/bin/bash`              | 1            | Menentukan interpreter Bash                |
| SPDX License Header                | 2 - 11       | Deklarasi lisensi GPL-3.0                  |
| Komentar filosofi                  | 11 - 19      | Menjelaskan tujuan satu-file               |
| `cd "$(dirname "$0")"`             | 21           | Mengunci direktori kerja ke lokasi script  |
| `SCRIPT_ABS="$(readlink -f "$0")"` | 32           | Mendapatkan path absolut script            |
| Komentar self-heal                 | 23 - 31      | Menjelaskan desain .desktop dan permission |

---

## 8. Keterkaitan dengan Bab Lain

| Variabel / Konsep                    | Digunakan di Bab                                                                                                                                         | Deskripsi                                                  |
| ------------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------- |
| `SCRIPT_ABS`                         | [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#4. Isi Template `.desktop` - Heredoc dan Field-nya\|Bab 3]]                              | Digunakan dalam file `.desktop`: `Exec=bash "$SCRIPT_ABS"` |
| `SCRIPT_ABS` (sebagai `SCRIPT_PATH`) | [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#3. Variabel `SCRIPT_PATH="$(readlink -f "$0")"` - Mengunci Path Absolut untuk Relaunch\|Bab 4]] | Digunakan untuk self-relaunch di level Bash                |
| SPDX Header                          | [[BAB 20 - LICENSE_TEXT DAN MANAJEMEN LISENSI#7. SPDX Header di Shell Script - Deklarasi Lisensi di Awal File\|Bab 20]]                                  | Merujuk ke file `LICENSE` yang dijelaskan di Bab 20        |
| Filosofi satu-file                   | [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String\|Bab 5]]        | Dijelaskan implementasinya di heredoc `PYEOF_INNER`        |

---

## 9. Kesimpulan

Pada bab ini, kita telah membahas **fondasi dari `jalankan_bootstrapper.sh`** - bagian awal yang menentukan bagaimana script akan berperilaku. Kita mempelajari:
1. **Shebang `#!/bin/bash`** - memastikan script dijalankan dengan Bash, bukan shell lain.
2. **SPDX header dan komentar lisensi** - deklarasi hak cipta dan lisensi GPL-3.0.
3. **Komentar filosofi** – menjelaskan tujuan satu-file dari bootstrapper.
4. **`cd "$(dirname "$0")"`** - mengunci direktori kerja ke lokasi script, memastikan konsistensi.
5. **`SCRIPT_ABS="$(readlink -f "$0")"`** - mendapatkan path absolut script untuk keperluan referensi di bagian selanjutnya.
6. **Komentar self-heal** - menjelaskan desain pembuatan `.desktop` dan perbaikan permission otomatis.