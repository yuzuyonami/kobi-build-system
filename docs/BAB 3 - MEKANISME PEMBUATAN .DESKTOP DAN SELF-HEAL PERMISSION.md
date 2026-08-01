# BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION

---

## 1. Pendahuluan: Menjadikan Script "Bisa Diklik"

Setelah kita memahami fondasi awal script di **Bab 2** - shebang, SPDX header, penguncian direktori, dan path absolut – kini saatnya membahas **fitur ramah pengguna** yang membuat sistem build ini terasa seperti aplikasi "normal", bukan sekadar script terminal yang harus dijalankan manual.

Pada Bab 3, kita akan membahas bagaimana `jalankan_bootstrapper.sh` secara otomatis:
1. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#5. `chmod +x "$DESKTOP_FILE"` - Memberi Izin Eksekusi pada Launcher|Membuat file `.desktop` - launcher yang memungkinkan pengguna mengklik ikon di file manager (Nautilus, Dolphin, Thunar, dll) untuk menjalankan bootstrapper.]]
2. [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#6. `chmod +x "$SCRIPT_ABS"` - Self-Heal Permission pada Shell|Melakukan self-heal permission - memperbaiki izin eksekusi pada script itu sendiri setiap kali dijalankan, sehingga pengguna tidak perlu repot mengatur "Allow executing file as program" secara manual.]]

Fitur-fitur ini adalah bagian dari [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#Terminal-First (Namun Ramah Pengguna)|filosofi desain "terminal-first tapi user-friendly" yang dijelaskan di Bab 1]] - sistem tetap berbasis terminal, tetapi kemudahan akses dibuat semulus mungkin.

> [!quote] 📌 **Referensi Silang:**
> - Variabel `SCRIPT_ABS` yang didefinisikan di **Bab 2** digunakan di sini untuk path absolut.
> - File `.desktop` yang dibuat di sini akan merujuk ke `SCRIPT_ABS` di `Exec=` field.
> - Self-heal permission di sini adalah fondasi untuk [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)|self-relaunch di Bab 4.]]

---

## 2. Variabel `DESKTOP_FILE` dan Lokasi File `.desktop`

*(Lokasi: Baris 32 - 33)*
```bash
SCRIPT_ABS="$(readlink -f "$0")"
DESKTOP_FILE="$(dirname "$SCRIPT_ABS")/Jalankan KOBI Bootstrapper.desktop"
```

### Tujuan
Variabel `DESKTOP_FILE` menyimpan **path lengkap** ke file `.desktop` yang akan dibuat. File ini akan ditempatkan di **folder yang sama** dengan `jalankan_bootstrapper.sh`, sehingga pengguna dapat dengan mudah melihat dan mengkliknya di file manager.

### Komponen

| Komponen                | Nilai                                         | Deskripsi                                                                                                                                                 |
| ----------------------- | --------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `SCRIPT_ABS`            | `/path/to/jalankan_bootstrapper.sh`           | [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#5. Variabel `SCRIPT_ABS="$(readlink -f "$0")"` - Mendapatkan Path Absolut\|Path absolut script.]] |
| `dirname "$SCRIPT_ABS"` | `/path/to/`                                   | Direktori tempat script berada.                                                                                                                           |
| `DESKTOP_FILE`          | `/path/to/Jalankan KOBI Bootstrapper.desktop` | Path lengkap file `.desktop`.                                                                                                                             |

### Mengapa Nama File Mengandung Spasi?
Nama `"Jalankan KOBI Bootstrapper.desktop"` mengandung spasi karena:
- Ini adalah **judul yang ramah pengguna** - terlihat seperti nama aplikasi di file manager.
- Di sebagian besar file manager (Nautilus, Dolphin), spasi di nama file didukung dengan baik.
- Nama ini akan muncul di menu aplikasi (jika pengguna memindahkan file ke `~/.local/share/applications/`).

### Mengapa Tidak di `~/.local/share/applications/`?
File `.desktop` dibuat di **folder yang sama** dengan script, bukan di direktori sistem (`~/.local/share/applications/`) karena:
- **Portabilitas** - file tetap berada bersama script, sehingga jika pengguna memindahkan folder proyek, launcher ikut berpindah.
- **Tidak perlu sudo** - menulis ke direktori sistem memerlukan izin administrator.
- **Sederhana** - pengguna cukup melihat file `.desktop` di folder yang sama dan mengkliknya.

---

## 3. Logika `if [ ! -f "$DESKTOP_FILE" ]` - Pengecekan Keberadaan

*(Lokasi Baris 34)*
```bash
if [ ! -f "$DESKTOP_FILE" ]; then
```

### Tujuan
Logika ini memeriksa apakah file `.desktop` **sudah ada** di folder tersebut. Jika belum, script akan membuatnya. Jika sudah ada, script akan **melewati** pembuatan (tetapi tetap melakukan `chmod +x` untuk memastikan izinnya benar).

### Komponen Kondisi

|Komponen|Fungsi|
|---|---|
|`[ ! -f "$DESKTOP_FILE" ]`|Mengembalikan `true` jika file **tidak** ada (`!` = negasi, `-f` = file regular).|
|`then`|Jika kondisi `true`, jalankan blok di bawahnya.|

### Mengapa Hanya Membuat Jika Belum Ada?
- **Efisiensi** - tidak perlu menimpa file yang sudah ada setiap kali script dijalankan.
- **Kustomisasi** - jika pengguna ingin mengubah `.desktop` (misal mengganti ikon), perubahan mereka tidak akan ditimpa.
- **Keamanan** - mencegah penulisan yang tidak perlu ke disk.

### Apa yang Terjadi Jika File Sudah Ada?
Jika file sudah ada, script **tidak** akan menulis ulang isinya. Namun, di [[BAB 3 - MEKANISME PEMBUATAN .DESKTOP DAN SELF-HEAL PERMISSION#5. `chmod +x "$DESKTOP_FILE"` - Memberi Izin Eksekusi pada Launcher|sub-bab 3.5, script tetap akan menjalankan `chmod +x "$DESKTOP_FILE"`]] untuk memastikan file tersebut memiliki izin eksekusi yang benar.

---

## 4. Isi Template `.desktop` - Heredoc dan Field-nya

*(Lokasi Baris 35 - 44)*
```bash
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Type=Application
Name=Jalankan KOBI Bootstrapper
Comment=Klik buat jalanin KOBI Build Bootstrapper
Exec=bash "$SCRIPT_ABS"
Terminal=true
Icon=utilities-terminal
Categories=Development;
EOF
```

### Tujuan
Blok heredoc ini menulis file `.desktop` dengan konten yang telah ditentukan. File `.desktop` adalah **standar [freedesktop.org](https://freedesktop.org)** yang digunakan oleh lingkungan desktop Linux (GNOME, KDE, XFCE, dll) untuk menampilkan aplikasi di menu dan file manager.

### Mekanisme Heredoc

```bash
cat > "$DESKTOP_FILE" << EOF
... konten ...
EOF
```

- **`cat > "$DESKTOP_FILE"`** - mengarahkan output `cat` ke file `$DESKTOP_FILE` (menimpa jika sudah ada).
- **`<< EOF`** – memulai heredoc dengan delimiter `EOF`.
- **`... konten ...`** - teks yang akan ditulis ke file.
- **`EOF`**- mengakhiri heredoc.

Karena heredoc menggunakan delimiter `EOF` (tanpa tanda kutip), variabel seperti `$SCRIPT_ABS` akan di-**ekspansi** (diganti dengan nilainya). Ini penting karena `Exec=` membutuhkan path absolut.

### Field `.desktop` - Penjelasan Lengkap

|Field|Nilai|Deskripsi|
|---|---|---|
|`Type`|`Application`|Menyatakan bahwa ini adalah aplikasi (bukan link atau direktori).|
|`Name`|`Jalankan KOBI Bootstrapper`|Nama yang ditampilkan di file manager dan menu aplikasi.|
|`Comment`|`Klik buat jalanin KOBI Build Bootstrapper`|Deskripsi singkat (tooltip) saat mouse diarahkan ke ikon.|
|`Exec`|`bash "$SCRIPT_ABS"`|Perintah yang dijalankan saat ikon diklik. `$SCRIPT_ABS` diekspansi ke path absolut script.|
|`Terminal`|`true`|Menjalankan aplikasi di terminal (karena bootstrapper adalah aplikasi terminal).|
|`Icon`|`utilities-terminal`|Nama ikon dari tema sistem (biasanya ikon terminal).|
|`Categories`|`Development;`|Kategori aplikasi (agar muncul di menu Development di GNOME/KDE).|

### Field `Exec` - Detail Penting

*(Lokasi Baris 40)*
```bash
Exec=bash "$SCRIPT_ABS"
```

- **`bash`** - memastikan script dijalankan dengan Bash (bukan shell default).
- **`"$SCRIPT_ABS"`** - path absolut script dengan tanda kutip untuk menangani spasi di path.
- **Tanpa `$SCRIPT_ABS` diekspansi** - karena heredoc tanpa tanda kutip (`<< EOF`), variabel diekspansi. Jika menggunakan `<< 'EOF'`, variabel tidak akan diekspansi.

### Mengapa `Terminal=true`?
Bootstrapper adalah **aplikasi terminal** (curses UI). Tanpa `Terminal=true`, terminal tidak akan terbuka dan pengguna hanya akan melihat proses latar belakang tanpa antarmuka.

### Ikon `utilities-terminal`
`utilities-terminal` adalah nama ikon standar di tema ikon sistem (misal Adwaita, Breeze, Papirus). Ini akan menampilkan ikon terminal yang dikenali pengguna. Jika ingin ikon khusus, pengguna dapat mengganti field ini nanti.

---

## 5. `chmod +x "$DESKTOP_FILE"` - Memberi Izin Eksekusi pada Launcher

*(Lokasi Baris 45)*
```bash
chmod +x "$DESKTOP_FILE" 2>/dev/null
```

### Tujuan
Memberikan izin eksekusi pada file `.desktop`. Meskipun file `.desktop` bukan executable dalam arti binary, beberapa file manager memerlukan izin eksekusi untuk memperlakukan file `.desktop` sebagai launcher yang bisa diklik.

### Mengapa `2>/dev/null`?
- **`2>`** - mengarahkan error (stderr) ke...
- **`/dev/null`** - perangkat null (membuang output).

Ini menyembunyikan pesan error jika `chmod` gagal (misal karena permission). Ini adalah **praktik defensif** - script tetap berjalan meskipun ada error kecil.

### Kapan Ini Dilakukan?
`chmod +x "$DESKTOP_FILE"` dijalankan **di luar blok `if`** (setelah heredoc), sehingga file `.desktop` selalu diberikan izin eksekusi setiap kali script dijalankan, baik baru dibuat maupun sudah ada sebelumnya.

---

## 6. `chmod +x "$SCRIPT_ABS"` - Self-Heal Permission pada Shell

*(Lokasi Baris 47)*
```bash
chmod +x "$SCRIPT_ABS" 2>/dev/null
```

### Tujuan
Ini adalah **self-heal permission** - script secara otomatis memperbaiki izin eksekusinya sendiri setiap kali dijalankan. Ini mengatasi masalah umum di mana:
- Pengguna mendownload script dari internet, tetapi izin eksekusi tidak diatur secara default.
- Pengguna memindahkan script ke folder baru, dan izin eksekusi hilang (tergantung sistem file).
- Pengguna secara tidak sengaja menghapus izin eksekusi (misal dengan `chmod -x`).

### Filosofi Self-Heal
Filosofi di balik self-heal adalah:
1. **Pengguna tidak perlu repot** - tidak ada lagi langkah manual "klik kanan > Properties > Allow executing file as program".
2. **Portabilitas** - script "memperbaiki diri sendiri" di mana pun ia ditempatkan.
3. **Kegagalan yang elegan** - jika `chmod` gagal (misal di filesystem yang tidak mendukung izin eksekusi), error dibuang (`2>/dev/null`) dan script tetap berjalan (walaupun mungkin tidak bisa dieksekusi langsung).

### Mengapa Self-Heal Penting di Konteks Ini?
Bayangkan skenario:
1. Pengguna mendownload `jalankan_bootstrapper.sh` dari email atau USB.
2. File tersebut **tidak memiliki izin eksekusi** (default dari download).
3. Pengguna mengklik file di file manager > tidak terjadi apa-apa (karena tidak executable).
4. Pengguna bingung dan frustrasi.

Dengan self-heal, **pada eksekusi pertama** (mungkin dari terminal dengan `bash jalankan_bootstrapper.sh`), script akan memperbaiki izinnya sendiri. Pada eksekusi berikutnya, pengguna bisa langsung mengklik file tersebut.

### Keterkaitan dengan Self-Relaunch (Bab 4)
Self-heal permission di sini adalah **prasyarat** untuk self-relaunch di Bab 4. Jika script tidak memiliki izin eksekusi, self-relaunch (yang memanggil script lagi) tidak akan berhasil.

---

## 7. Alur Lengkap Pembuatan .desktop dan Self-Heal

Berikut adalah alur lengkap dari bagian script ini:

> [!info]- Alur Pembuatan .desktop dan Self-Heal
> ```text
> 1. SCRIPT_ABS = readlink -f "$0"  (path absolut script)
> 	|
> 2. DESKTOP_FILE = dirname(SCRIPT_ABS) + "/Jalankan KOBI Bootstrapper.desktop"
> 	|
> 3. if [ ! -f "$DESKTOP_FILE" ]; then
> 	|
> 4.   cat > "$DESKTOP_FILE" << EOF
>      [Desktop Entry]
>      Type=Application
>      Name=Jalankan KOBI Bootstrapper
>      Comment=Klik buat jalanin KOBI Build Bootstrapper
>      Exec=bash "$SCRIPT_ABS"
>      Terminal=true
>      Icon=utilities-terminal
>      Categories=Development;
>      EOF
>    ↓
> 5. fi
> 	|
> 6. chmod +x "$DESKTOP_FILE"  (self-heal launcher)
> 	|
> 7. chmod +x "$SCRIPT_ABS"    (self-heal script itu sendiri)
> ```

---

## 8. Tabel Rangkuman

| Komponen                      | Lokasi Baris | Fungsi                               |
| ----------------------------- | ------------ | ------------------------------------ |
| `SCRIPT_ABS`                  | 32           | Path absolut script (dari Bab 2)     |
| `DESKTOP_FILE`                | 33           | Path lengkap file `.desktop`         |
| `if [ ! -f "$DESKTOP_FILE" ]` | 34           | Cek apakah file `.desktop` sudah ada |
| Heredoc `.desktop`            | 35 - 44      | Menulis template `.desktop` ke file  |
| `chmod +x "$DESKTOP_FILE"`    | 45           | Memberi izin eksekusi pada launcher  |
| `chmod +x "$SCRIPT_ABS"`      | 47           | Self-heal permission pada script     |

### Field `.desktop` - Tabel Ringkas

|Field|Nilai|Fungsi|
|---|---|---|
|`Type`|`Application`|Tipe aplikasi|
|`Name`|`Jalankan KOBI Bootstrapper`|Nama yang ditampilkan|
|`Comment`|`Klik buat jalanin KOBI Build Bootstrapper`|Deskripsi tooltip|
|`Exec`|`bash "$SCRIPT_ABS"`|Perintah eksekusi|
|`Terminal`|`true`|Buka di terminal|
|`Icon`|`utilities-terminal`|Ikon dari tema sistem|
|`Categories`|`Development;`|Kategori menu|

---

## 9. Keterkaitan dengan Bab Lain

| Konsep               | Digunakan di Bab                                                                                                                           | Deskripsi                                                                                   |
| -------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------- |
| `SCRIPT_ABS`         | [[BAB 2 - STRUKTUR AWAL BASH (SHEBANG DAN INISIALISASI)#5. Variabel `SCRIPT_ABS="$(readlink -f "$0")"` - Mendapatkan Path Absolut\|Bab 2]] | Didefinisikan di Bab 2, digunakan di sini untuk `Exec=` dan self-heal.                      |
| File `.desktop`      | [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#^4cd593\|Bab 4]]                                                                  | Self-relaunch di Bab 4 memastikan script berjalan di terminal; `.desktop` memudahkan akses. |
| Self-heal permission | [[BAB 4 - SELF-RELAUNCH DI LEVEL BASH (DETEKSI TERMINAL)#^4cd593\|Bab 4]]                                                                  | Self-relaunch membutuhkan script executable; self-heal untuk memastikannya.                 |
| Filosofi "satu file" | [[BAB 1 - PENDAHULUAN DAN FILOSOFI SISTEM#3. Filosofi Desain Self-Contained, Regeneratif, dan Terminal-First\|Bab 1]]                      | `.desktop` adalah bonus yang membuat satu file ini terasa seperti aplikasi.                 |

---

## 10. Troubleshooting .desktop

|Masalah|Penyebab|Solusi|
|---|---|---|
|File `.desktop` tidak muncul di file manager|Ikon tidak di-refresh|Restart file manager atau logout/login|
|Klik `.desktop` tidak membuka terminal|`Terminal=true` tidak dihormati|Coba jalankan dari terminal: `bash -c "bash /path/to/script.sh"`|
|Ikon tidak muncul|Tema ikon tidak memiliki `utilities-terminal`|Ganti field `Icon=` ke nama ikon lain (misal `terminal`)|
|`.desktop` tidak bisa diklik|Izin eksekusi hilang|Jalankan `chmod +x` manual atau jalankan script dari terminal sekali agar self-heal bekerja|
|Error "bash: /path/to/script.sh: No such file or directory"|Path di `Exec=` salah|Periksa apakah `SCRIPT_ABS` benar; jalankan `readlink -f "$0"` manual|

---

## 11. Kustomisasi .desktop

Pengguna dapat mengkustomisasi file `.desktop` yang sudah dibuat dengan mengeditnya secara manual:

```bash
nano "Jalankan KOBI Bootstrapper.desktop"
```

Beberapa kustomisasi umum:

|Field|Contoh Nilai|Efek|
|---|---|---|
|`Icon`|`/path/to/custom/icon.png`|Menggunakan ikon kustom|
|`Name`|`KOBI Launcher`|Nama yang lebih singkat|
|`Comment`|`Build system for Godot GDExtension`|Deskripsi dalam bahasa Inggris|
|`Exec`|`bash -c "cd /path/to/project && bash /path/to/script.sh"`|Menjalankan dari direktori tertentu|

**Peringatan:** Jika script di-generate ulang (misal dengan menjalankan `jalankan_bootstrapper.sh` lagi), file `.desktop` **tidak** akan ditimpa (karena ada pengecekan `if [ ! -f ]`). Namun, jika pengguna menghapus file `.desktop`, script akan membuatnya kembali dengan template default.

---

## 12. Kesimpulan

Pada bab ini, kita telah membahas **mekanisme pembuatan .desktop dan self-heal permission** yang membuat `jalankan_bootstrapper.sh` terasa seperti aplikasi yang ramah pengguna. Kita mempelajari:

1. **`DESKTOP_FILE`** - variabel yang menyimpan path lengkap ke file `.desktop` di folder yang sama dengan script.
2. **Logika `if [ ! -f "$DESKTOP_FILE" ]`** - memeriksa apakah file `.desktop` sudah ada; jika belum, membuatnya.
3. **Template `.desktop`**- isi file dengan field `Type`, `Name`, `Comment`, `Exec`, `Terminal`, `Icon`, dan `Categories`.
4. **`chmod +x "$DESKTOP_FILE"`** - memberikan izin eksekusi pada launcher agar dapat diklik di file manager.
5. **`chmod +x "$SCRIPT_ABS"`** - self-heal permission pada script itu sendiri, memastikan script selalu dapat dieksekusi tanpa intervensi manual.
6. **Filosofi self-heal** - mengurangi friction bagi pengguna, terutama yang tidak terbiasa dengan terminal.