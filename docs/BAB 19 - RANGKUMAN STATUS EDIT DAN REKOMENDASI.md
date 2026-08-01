# BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI

---

## 1. Pendahuluan: Panduan Praktis untuk Pengembang

Setelah kita membahas seluruh aspek teknis sistem build - dari shell script hingga logika kompilasi, dari antarmuka curses hingga manajemen lisensi - kini tiba saatnya untuk memberikan **panduan praktis** bagi pengembang yang ingin menggunakan, memodifikasi, atau memperluas sistem ini.

Pada Bab 19, kita akan membahas:
1. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#2. Tabel Final File yang Boleh Diedit vs Tidak|File mana yang boleh diedit dan mana yang tidak - tabel jelas tentang apa yang aman untuk diubah.]]
2. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#3. Tabel Final Folder yang Boleh Diedit vs Tidak|Folder mana yang boleh diedit dan mana yang tidak - struktur direktori proyek.]]
3. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#4. Skenario Kerja Pengembang|Skenario kerja pengembang - workflow dari nol hingga build sukses.]]
4. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#5. Peringatan Jangan Tekan `[Generate!]` Sembarangan!|Peringatan kritis - mengapa `[Generate!]` harus digunakan dengan hati-hati.]]
5. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#6. Cara Backup dan Pemulihan `build_logic.py`|Cara backup dan pemulihan - melindungi kustomisasi dari overwrite.]]
6. [[BAB 19 - RANGKUMAN STATUS EDIT DAN REKOMENDASI#7. Penutup dan Saran Eksplorasi|Penutup dan saran eksplorasi - kata-kata terakhir untuk pengembang.]]

---

## 2. Tabel Final: File yang Boleh Diedit vs Tidak

### File yang **TIDAK Boleh** Diedit (Akan Ditimpa)

| File                       | Lokasi      | Mengapa Tidak Boleh Diedit                                                                                                                                                                                                       | Alternatif                                                                   |
| -------------------------- | ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------- |
| `jalankan_bootstrapper.sh` | Root proyek | File ini adalah **sumber dari segalanya**. Jika diedit, perubahan akan hilang saat versi baru diunduh atau saat file di-generate ulang.                                                                                          | Fork bootstrapper dan modifikasi di sana.                                    |
| `bootstrap_scons_gui.py`   | Root proyek | [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String\|Digenerate ulang setiap kali `jalankan_bootstrapper.sh` dijalankan.]]                  | Modifikasi heredoc di `jalankan_bootstrapper.sh` (untuk fork).               |
| `setup_godot_cpp.py`       | Root proyek | [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT\|Digenerate ulang setiap kali `jalankan_bootstrapper.sh` dijalankan.]]                                                                              | Modifikasi heredoc di `jalankan_bootstrapper.sh` (untuk fork).               |
| `SConstruct`               | Root proyek | [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py\|Digenerate ulang setiap kali menu `[ Generate! ]` dijalankan.]] | Jangan diedit; semua logika ada di `build_logic.py`.                         |
| `build_logic.py`           | Root proyek | [[BAB 12 - `bootstrap_scons_gui.py` FUNGSI GENERATE FILE (`SConstruct` & `build_logic.py`)#2. Fungsi `generate_files()` - Menulis SConstruct dan build_logic.py\|Digenerate ulang setiap kali menu `[ Generate! ]` dijalankan.]] | **JANGAN DIEDIT** – akan hilang saat generate ulang. Gunakan fork atau hook. |

### File yang **BOLEH** Diedit (Aman)

|File|Lokasi|Mengapa Boleh Diedit|Catatan|
|---|---|---|---|
|`build_options.json`|Root proyek|File konfigurasi yang disimpan dan dibaca oleh sistem. Backup otomatis ke `.bak`.|Edit dengan hati-hati; format JSON harus valid.|
|`build_options.json.bak`|Root proyek|Backup otomatis dari versi sebelumnya.|Bisa dipulihkan jika perlu.|
|`*.cpp`, `*.h`, `*.hpp`|`src/` dan subfolder|File sumber C++ proyek.|Bebas diedit.|
|`CREDITS.md`|Root proyek|Diekspor dari menu `[ Export Credits ]`.|Bisa diedit manual.|
|`LICENSE`|Root proyek|Diekspor dari menu `[ Export License ]`.|Bisa diedit manual jika perlu.|
|`compile.gdextension`|`bin/`|Digenerate oleh `build_logic.py`.|Jangan diedit manual; akan ditimpa.|

### File Log (Hanya Dibaca)

|File|Lokasi|Fungsi|
|---|---|---|
|`logs/build_report.md`|`logs/`|Log Markdown (dibaca manusia).|
|`logs/build_history.json`|`logs/`|Log JSON (dibaca mesin).|
|`logs/build_errors.log`|`logs/`|Log error detail.|
|`logs/build_history_archive.json`|`logs/`|Arsip JSON lama.|
|`logs/terminal_cctv.log`|`logs/`|Rekaman semua output terminal.|
|`logs/build_report_archive_*.md`|`logs/`|Arsip Markdown dengan timestamp.|

---

## 3. Tabel Final: Folder yang Boleh Diedit vs Tidak

| Folder                   | Lokasi      | Status       | Keterangan                                    |
| ------------------------ | ----------- | ------------ | --------------------------------------------- |
| `src/`                   | Root proyek | Boleh diedit | Tempat file sumber C++ proyek.                |
| `bin/`                   | Root proyek | Baca saja    | Output compile; jangan diedit manual.         |
| `build/`                 | Root proyek | Baca saja    | Objek file compile; jangan diedit manual.     |
| `logs/`                  | Root proyek | Boleh dibaca | File log; jangan dihapus saat build berjalan. |
| `godot-cpp-*/`           | Root proyek | Baca saja    | Binding godot-cpp; jangan diedit manual.      |
| `godot-cpp-master-api*/` | Root proyek | Baca saja    | Binding godot-cpp (master + api_version).     |

---

## 4. Skenario Kerja Pengembang

> [!info]- Skenario 1
> ### Skenario 1: Pengguna Baru (Membangun Proyek Pertama Kali)
> ```text
> 1. Download jalankan_bootstrapper.sh
> 	|
> 2. chmod +x jalankan_bootstrapper.sh (jika perlu)
> 	|
> 3. Jalankan: ./jalankan_bootstrapper.sh
> 	|
> 4. Dialog "Create a new project folder?" > Ya
> 	|
> 5. Masukkan nama folder (misal "my_extension")
> 	|
> 6. Menu curses muncul
> 	|
> 7. Pilih [ Setup godot-cpp ] > tunggu clone & compile selesai
> 	|
> 8. Pilih [ Generate! ] > konfirmasi > SConstruct & build_logic.py dibuat
> 	|
> 9. Keluar dari menu (Q)
> 	|
> 10. cd my_extension
> 	|
> 11. scons (jalankan build)
> 	|
> 12. Hasil compile di bin/linux_64_release/ (atau sesuai opsi)
> ```

> [!info]- Skenario 2
> ### Skenario 2: Pengembang Berpengalaman (Mengubah Opsi Build)
> 
> ```text
> 1. Jalankan ./jalankan_bootstrapper.sh
> 	|
> 2. Menu curses muncul
> 	|
> 3. Navigasi ke opsi yang ingin diubah (LEFT/RIGHT atau ENTER)
> 	|
> 4. Contoh: ubah mode ke Debug, aktifkan Windows, ubah bits ke 32
> 	|
> 5. Pilih [ Generate! ] > konfirmasi
> 	|
> 6. Keluar dari menu
> 	|
> 7. scons (build dengan opsi baru)
> ```

> [!info]- Skenario 3
> ### Skenario 3: Mengganti Versi godot-cpp
> 
> ```text
> 1. Jalankan ./jalankan_bootstrapper.sh
> 	|
> 2. Menu curses muncul
> 	|
> 3. Navigasi ke godot-cpp version > tekan LEFT/RIGHT sampai versi yang diinginkan
> 	|
> 4. Jika memilih "custom...", ketik branch manual (misal "4.5")
> 	|
> 5. Pilih [ Setup godot-cpp ] > tunggu clone & compile selesai
> 	|
> 6. Pilih [ Generate! ] → konfirmasi
> 	|
> 7. Keluar dari menu
> 	|
> 8. scons (build dengan godot-cpp versi baru)
> ```

> [!info]- Skenario 4
> ### Skenario 4: Membersihkan Ruang Disk
> 
> ```text
> 1. Jalankan ./jalankan_bootstrapper.sh
> 	|
> 2. Menu curses muncul
> 	|
> 3. Pilih [ View all godot-cpp versions ] > lihat folder mana yang besar
> 	|
> 4. Pilih [ Clean up old godot-cpp ]
> 	|
> 5. Ketik "DELETE" untuk konfirmasi
> 	|
> 6. Folder lama dihapus, ruang disk dibebaskan
> ```
> 

---

## 5. Peringatan: Jangan Tekan `[Generate!]` Sembarangan!

### Apa yang Terjadi Saat `[Generate!]` Dipilih?
Menu `[ Generate! ]` melakukan tiga hal:
1. **`save_options(opts)`** - menyimpan opsi ke `build_options.json` (dengan backup ke `.bak`).
2. **Menulis `SConstruct`** - file stub dengan `exec(open("build_logic.py").read())`.
3. **Menulis `build_logic.py`** - menimpa file dengan versi default dari bootstrapper.

### Mengapa Ini Berbahaya?
**`build_logic.py` akan ditimpa** dengan versi default. Jika Anda telah mengedit `build_logic.py` secara manual (meskipun kami sangat menyarankan untuk tidak melakukannya), semua perubahan Anda akan **hilang**!

### Bagaimana Menghindarinya?

|Tindakan|Deskripsi|
|---|---|
|**Jangan edit `build_logic.py`**|Ini adalah aturan #1. Semua kustomisasi sebaiknya dilakukan di tempat lain.|
|**Fork bootstrapper**|Jika harus mengubah logika build, fork `jalankan_bootstrapper.sh` dan modifikasi `LOGIC_CONTENT` di dalamnya.|
|**Backup sebelum generate**|Jika terpaksa mengedit `build_logic.py`, backup sebelum menjalankan `[ Generate! ]`.|
|**Gunakan Git**|Simpan proyek di Git; jika `build_logic.py` tertimpa, Anda bisa `git checkout` versi sebelumnya.|

### Apa yang Harus Dilakukan Jika Tidak Sengaja Menekan `[Generate!]`?
1. Jangan panik.
2. Jika Anda memiliki backup `build_logic.py`, pulihkan
3. Jika menggunakan Git: `git checkout build_logic.py`.
4. Jika tidak ada backup: jalankan `[ Generate! ]` lagi (tidak akan memperbaiki, hanya menimpa dengan versi default).
5. Pertimbangkan untuk fork bootstrapper di masa depan.

---

## 6. Cara Backup dan Pemulihan `build_logic.py`

### Menggunakan Git (Rekomendasi)

```bash
# Inisialisasi repo Git di folder proyek
git init
# Commit versi awal
git add .
git commit -m "Initial commit before editing build_logic.py"
# Edit build_logic.py (jika terpaksa)
nano build_logic.py
# Jika build_logic.py tertimpa oleh Generate!
git checkout build_logic.py
```

### Backup Manual

```bash
# Backup sebelum generate
cp build_logic.py build_logic.py.backup_$(date +%Y%m%d_%H%M%S)
# Jika tertimpa, pulihkan
cp build_logic.py.backup_* build_logic.py
```

### Menggunakan `build_options.json.bak`

`build_options.json` selalu di-backup ke `.bak` sebelum ditimpa. Jika Anda salah mengubah opsi dan ingin memulihkan:

```bash
cp build_options.json.bak build_options.json
```

---

## 7. Penutup dan Saran Eksplorasi

### Ringkasan Sistem
Sistem build KOBI GDExtension adalah **ekosistem lengkap** yang:
- **Self-contained** - semua kode ada di satu file shell script.
- **Regeneratif** - memperbaiki dan menghasilkan ulang dirinya sendiri.
- **Terminal-first** - antarmuka curses yang intuitif.
- **Multi-platform** - mendukung Linux dan Windows (cross-compilation).
- **Multi-arsitektur** - 64-bit dan 32-bit (v2.4.0).
- **Terlisensi GPL-3.0** - open source dengan kepatuhan lisensi.

### Saran untuk Pengembang
1. **Jangan mengedit `build_logic.py`** - gunakan fork jika perlu modifikasi.
2. **Gunakan Git** - selalu simpan proyek di version control.
3. **Eksplorasi menu** - semua opsi di menu curses sudah dijelaskan di dokumentasi ini.
4. **Baca log** - jika build gagal, cek `logs/build_errors.log` dan `logs/terminal_cctv.log`.
5. **Perbarui bootstrapper** - jika ada versi baru, ganti `jalankan_bootstrapper.sh`.
6. **Kontribusi** - jika menemukan bug atau ingin menambah fitur, fork dan pull request.

### Saran untuk Eksplorasi Lebih Lanjut
Jika Anda ingin **memperluas** sistem, berikut adalah beberapa ide:

|Ide|Deskripsi|Tantangan|
|---|---|---|
|**Tambahkan platform macOS**|Dukungan untuk `platform=macos` di SCons.|Membutuhkan compiler macOS dan toolchain.|
|**Tambahkan platform Android**|Dukungan untuk `platform=android` di SCons.|Membutuhkan Android NDK dan toolchain.|
|**Tambahkan opsi `custom_cppflags`**|Memungkinkan pengguna menambahkan flag compiler sendiri.|Perlu modifikasi `build_logic.py`.|
|**Tambahkan hook pre/post build**|Menjalankan script sebelum/sesudah build.|Perlu modifikasi `build_logic.py`.|
|**Buat versi GUI (Qt/GTK)**|Mengganti curses dengan GUI sebenarnya.|Proyek besar, memerlukan library tambahan.|
|**Integrasi dengan Godot Editor**|Menjalankan build dari dalam Godot.|Memerlukan plugin Godot.|


---

## 8. Tabel Rangkuman

| Sub-Bab | Topik                                                      | Halaman |
| ------- | ---------------------------------------------------------- | ------- |
| 1       | Pendahuluan: Panduan Praktis untuk Pengembang              | 1       |
| 2       | Tabel Final: File yang Boleh Diedit vs Tidak               | 1 - 2   |
| 3       | Tabel Final: Folder yang Boleh Diedit vs Tidak             | 2       |
| 4       | Skenario Kerja Pengembang (Workflow dari Nol)              | 2 - 3   |
| 5       | Peringatan Kritis: Jangan Tekan `[Generate!]` Sembarangan! | 3       |
| 6       | Cara Backup dan Pemulihan `build_logic.py`                 | 3 - 4   |
| 7       | Penutup dan Saran Eksplorasi                               | 4       |

---

## 9. Keterkaitan dengan Bab Lain

|Konsep di Bab 19|Terkait dengan Bab|
|---|---|
|`build_logic.py` tidak boleh diedit|Bab 12 (generate_files), Bab 15 (build engine)|
|`build_options.json` backup|Bab 8 (save_options)|
|Workflow dari nol|Bab 17 (alur eksekusi)|
|`[Generate!]` peringatan|Bab 11 (menu generate), Bab 12 (generate_files)|
|Git dan backup|Bab 17 (troubleshooting)|

---

## 10. Kesimpulan

Pada bab ini, kita telah membahas **rangkuman status edit dan rekomendasi** untuk pengembang yang menggunakan sistem build KOBI GDExtension. Kita mempelajari:

1. **Tabel file yang boleh diedit vs tidak** - panduan jelas tentang mana yang aman untuk diubah.
2. **Tabel folder yang boleh diedit vs tidak** - struktur direktori proyek.
3. **Skenario kerja pengembang** - workflow dari nol, mengubah opsi, mengganti versi, dan membersihkan ruang disk.
4. **Peringatan kritis** - mengapa `[Generate!]` harus digunakan dengan hati-hati dan bagaimana menghindari kehilangan kustomisasi.
5. **Cara backup dan pemulihan** - menggunakan Git, backup manual, dan memulihkan `build_options.json`.
6. **Penutup dan saran eksplorasi** - ide untuk memperluas sistem dan kata terakhir untuk pengembang.