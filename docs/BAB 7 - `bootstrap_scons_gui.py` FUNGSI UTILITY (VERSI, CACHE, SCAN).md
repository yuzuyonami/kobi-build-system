# BAB 7 - `bootstrap_scons_gui.py`: FUNGSI UTILITY (VERSI, CACHE, SCAN)

---

## 1. Pendahuluan: Mengapa Utility Functions Penting?

Setelah memahami bagaimana sistem melakukan **self-relaunch** (Bab 6) dan bagaimana file-file inti di-_embed_ ke dalam shell script, kini kita memasuki jantung logika manajemen versi dari sistem build KOBI GDExtension.

Pada Bab ini, kita akan membahas **sembilan fungsi utility** yang bertugas mengelola:
1. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#2. Fungsi `get_daftar_versi_cache_path()` - Path Cache Versi|Daftar versi godot-cpp yang tersedia (baik dari cache lokal maupun dari GitHub).]]
2. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#5. Fungsi `validasi_format_versi(versi)` - Validasi Input Custom|Validasi input custom dari pengguna.]]
3. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding|Status kompilasi setiap folder godot-cpp yang pernah di-_setup_.]]
4. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#7. Fungsi `cek_godot_terinstall()` - Deteksi Godot Editor di Sistem|Deteksi versi Godot editor yang terinstall di sistem.]]
5. [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#10. Fungsi `get_last_build_info()` - Informasi Build Terakhir|Informasi build terakhir dari riwayat log.]]

Fungsi-fungsi ini adalah fondasi bagi menu utama curses dan menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `setup` - Setup godot-cpp|`[ Setup godot-cpp ]`]] . Tanpa fungsi-fungsi ini, sistem tidak akan tahu:

- Versi apa saja yang bisa dipilih di toggle `godot-cpp version`.
- Apakah sebuah versi sudah di-_clone_ atau sudah di-_compile_.
- Berapa besar ruang disk yang terpakai oleh versi-versi lama.
- Build terakhir berhasil atau gagal.

>[!quote] **Referensi Silang:** 
>Fungsi-fungsi di bab ini dipanggil oleh:
> - [[BAB 10 - `bootstrap_scons_gui.py` FUNGSI LAYAR CURSES (RENDER, INPUT, DIALOG)#2. Fungsi `render_menu()` - Menggambar UI Utama|`render_menu()`]] - untuk menampilkan status kompilasi dan build terakhir.
> - [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#2. Fungsi `main(stdscr)` - Entry Point dan Inisialisasi|`main()`]] - untuk navigasi keyboard dan eksekusi menu.
> - `update_daftar_versi_online()` - dipanggil langsung dari menu `[ Update version list ]`.

Semua kode yang dibahas dalam bab ini berada di dalam **heredoc `PYEOF_INNER`** dari [[BAB 5 - EMBEDDING FILE PYTHON HEREDOC DAN AWAL#3. Heredoc `cat > bootstrap_scons_gui.py << 'PYEOF_INNER'` - Mekanisme Embedding String|`jalankan_bootstrapper.sh`]], tepatnya setelah konstanta `STUB_CONTENT` dan `LOGIC_CONTENT` didefinisikan, dan sebelum fungsi-fungsi render menu dimulai.

---

## 2. Fungsi `get_daftar_versi_cache_path()` - Path Cache Versi

*(Lokasi Baris 503 - 504)*
```python
def get_daftar_versi_cache_path():
    return "godot_cpp_versi_cache.json"
```

### Tujuan dan Penggunaan
Fungsi ini adalah **getter** paling sederhana: mengembalikan nama file cache yang digunakan untuk menyimpan daftar versi godot-cpp yang berhasil di-_pull_ dari GitHub.

### Mengapa Perlu Cache?
Bayangkan setiap kali pengguna membuka menu, sistem harus melakukan `git ls-remote` ke GitHub untuk mengetahui branch apa saja yang tersedia di `godotengine/godot-cpp`. Ini akan:
1. **Memakan waktu** (tergantung koneksi internet).
2. **Mengganggu pengalaman pengguna** (menu jadi lambat).
3. **Bergantung pada koneksi internet** – tanpa internet, menu tetap harus bisa jalan.

Dengan adanya cache, sistem hanya perlu melakukan _network call_ **saat pengguna secara eksplisit memilih menu `[ Update version list ]`**. Sisanya, daftar versi dibaca dari file lokal `godot_cpp_versi_cache.json`.

### Format Cache
File cache menyimpan JSON dengan struktur:
```json
{
  "versi": ["3.0", "3.1", "3.2", ..., "4.0", "4.1", ..., "4.5"],
  "updated": "2026-07-25 14:30:22"
}
```

- `versi`: daftar branch yang ditemukan di GitHub (hanya yang berformat angka.angka, misal `4.5`, `4.6`, dst).
- `updated`: timestamp kapan terakhir kali cache diperbarui.

---

## 3. Fungsi `load_daftar_versi()` - Memuat Daftar Versi

*(Lokasi Baris 507 - 525)*
```python
def load_daftar_versi():
    cache_path = get_daftar_versi_cache_path()
    if os.path.exists(cache_path):
        try:
            with open(cache_path, "r") as f:
                data = json.load(f)
            if data.get("versi"):
                return data["versi"] + ["master", "custom..."]
        except Exception:
            pass
    return ["4.0", "4.1", "4.2", "4.3", "4.4", "4.5", "master", "custom..."]
```

### Logika Fungsi
1. **Baca cache** - jika file `godot_cpp_versi_cache.json` ada dan valid, ambil daftar `versi`-nya.
2. **Tambahkan `"master"` dan `"custom..."`** - kedua entri ini **selalu** ada, karena:
    - `"master"` adalah branch utama godot-cpp (versi 10.x ke atas) yang **tidak punya branch per-versi Godot** (Bab 1).
    - `"custom..."` adalah pintu masuk untuk pengguna yang ingin mengetik branch secara manual.
3. **Fallback ke daftar bawaan** - jika cache tidak ada atau rusak, kembalikan daftar default: `["4.0", "4.1", "4.2", "4.3", "4.4", "4.5", "master", "custom..."]`.

### Mengapa Hanya Sampai 4.5 di Daftar Bawaan?
Karena **godot-cpp versi 10.x (branch master)** tidak lagi membuat branch baru untuk setiap rilis Godot (4.6, 4.7, dst). Branch per-versi hanya ada sampai **godot-cpp 4.5** (yang kompatibel dengan Godot 4.5 ke bawah). Untuk Godot 4.6 ke atas, pengguna **harus** menggunakan `master` dan mengatur `api_version` di menu.

> [!warning] **Catatan Penting:**
 **Jangan mengedit file cache secara manual** - kecuali kamu benar-benar paham strukturnya. Cache akan diperbarui otomatis oleh menu `[ Update version list ]`.

---

## 4. Fungsi `get_daftar_api_version()` - Daftar API Version untuk Branch Master

*(Lokasi Baris 507 dan 525)*
```python
def get_daftar_api_version():
    return ["4.3", "4.4", "4.5", "4.6", "4.7", "custom..."]
```

### Tujuan
Fungsi ini mengembalikan daftar **nilai `api_version`** yang valid untuk branch `master` godot-cpp. `api_version` menentukan versi Godot mana yang menjadi target saat meng-_compile_ binding godot-cpp.

### Mengapa Mulai dari 4.3?
Menurut dokumentasi resmi godot-cpp, branch `master` mendukung `api_version` mulai dari **4.3** ke atas. Versi di bawah 4.3 harus menggunakan branch per-versi (misal `4.0`, `4.1`, `4.2`).

### Peran `"custom..."`
Sama seperti di `load_daftar_versi()`, opsi `"custom..."` memungkinkan pengguna mengetik versi secara manual, misal `"4.8"` (jika Godot 4.8 sudah rilis dan godot-cpp master sudah mendukungnya).

### Kaitan dengan `validasi_format_versi()`
Opsi `"custom..."` akan memicu validasi format menggunakan fungsi `validasi_format_versi()` (akan dibahas di sub-bab 7.5), sehingga pengguna tidak bisa salah ketik (misal `"4.7.0.1"` atau `"empat.tujuh"`).

---

## 5. Fungsi `validasi_format_versi(versi)` - Validasi Input Custom

*(Lokasi Baris 535 - 540)*
```python
def validasi_format_versi(versi):
    import re as _re
    return bool(_re.match(r'^\d+(\.\d+)+$', versi.strip()))
```

### Tujuan
Memastikan input custom dari pengguna (baik untuk `branch` maupun `api_version`) mengikuti format **angka.angka** (misal `4.7`, `4.7.1`, `3.2.4`).

### Logika Regex
- `^` - awal string.
- `\d+` - satu atau lebih digit (angka).
- `(\.\d+)+` - satu atau lebih kemunculan dari "titik diikuti satu atau lebih digit".
- `$` - akhir string.

Contoh valid: `"4.7"`, `"4.7.1"`, `"3.0"`.  
Contoh tidak valid: `"4."`, `".7"`, `"empat.7"`, `"4.7.0.0.0"` (meskipun ini valid secara regex, tapi tidak lazim untuk versi Godot; namun tidak diblokir).

### Penggunaan di Menu
Validasi ini dipanggil saat pengguna memilih `"custom..."` di toggle `branch` atau `api_version`. Jika input tidak valid, sistem menampilkan pesan error dan meminta input ulang.

---

## 6. Fungsi `cek_semua_godot_cpp()` - Scan Semua Folder Binding

*(Lokasi Baris 543 - 567)*
```python
def cek_semua_godot_cpp():
    hasil = []
    for d in sorted(glob.glob("godot-cpp-*")):
        if not os.path.isdir(d):
            continue
        bin_dir = os.path.join(d, "bin")
        linux_ok = len(glob.glob(os.path.join(bin_dir, "*linux*"))) > 0
        windows_ok = len(glob.glob(os.path.join(bin_dir, "*windows*"))) > 0
        if linux_ok and windows_ok:
            status = "compiled: linux+windows"
        elif linux_ok:
            status = "compiled: linux only"
        elif windows_ok:
            status = "compiled: windows only"
        else:
            status = "not compiled yet"
        try:
            ukuran_mb = round(sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fn in os.walk(d) for f in fn) / (1024 * 1024))
        except Exception:
            ukuran_mb = 0
        hasil.append((d, status, ukuran_mb))
    return hasil
```

### Tujuan
Fungsi ini **memindai semua folder `godot-cpp-*`** di direktori proyek, lalu mengembalikan **list tuple** berisi:
- Nama folder.
- Status kompilasi (4 kemungkinan).
- Perkiraan ukuran folder dalam MB.

### Status Kompilasi - 4 Kemungkinan

|Status|Kondisi|
|---|---|
|`"compiled: linux+windows"`|Ada file hasil compile untuk Linux DAN Windows di `bin/`|
|`"compiled: linux only"`|Ada file hasil compile Linux, tapi tidak ada Windows|
|`"compiled: windows only"`|Ada file hasil compile Windows, tapi tidak ada Linux|
|`"not compiled yet"`|Tidak ada file hasil compile sama sekali di `bin/`|

### Perhitungan Ukuran
Fungsi menggunakan `os.walk()` untuk menjumlahkan ukuran **seluruh file** di dalam folder godot-cpp, lalu membaginya dengan `1024 * 1024` untuk mendapatkan MB. Jika terjadi error (misal permission denied), ukuran dicatat sebagai `0`.

### Penggunaan di Menu
Fungsi ini dipanggil oleh dua menu:
1. **`[ View all godot-cpp versions ]`** - menampilkan daftar lengkap ke layar.
2. **`[ Clean up old godot-cpp ]`** - menentukan folder mana yang akan dihapus (selain yang aktif).

---

## 7. Fungsi `cek_godot_terinstall()` - Deteksi Godot Editor di Sistem

*(Lokasi Baris 570 - 582)*
```python
def cek_godot_terinstall():
    for nama_bin in ("godot4", "godot", "godot.x11.opt.tools.64", "godot-mono"):
        if shutil.which(nama_bin):
            try:
                hasil = subprocess.run([nama_bin, "--version"], capture_output=True, text=True, timeout=10)
                if hasil.returncode == 0 and hasil.stdout.strip():
                    return hasil.stdout.strip().splitlines()[0]
            except Exception:
                continue
    return None
```

### Tujuan
Mendeteksi apakah ada **Godot editor** yang terinstall di sistem dan dapat dijalankan dari `PATH`. Fungsi ini **hanya memberikan saran** – tidak mengubah opsi apapun secara otomatis.

### Kandidat Nama Binary
Fungsi mencoba 4 nama binary yang umum digunakan di berbagai distribusi Linux:
- `godot4` - umum di Arch Linux dan beberapa distro modern.
- `godot` - default di banyak distro.
- `godot.x11.opt.tools.64` - binary bawaan dari rilis resmi Godot (untuk Linux 64-bit).
- `godot-mono` - untuk versi dengan dukungan Mono/C#.

### Eksekusi `--version`
Setelah menemukan binary, fungsi menjalankan `--version` dengan timeout 10 detik. Output baris pertama (biasanya berupa `Godot Engine v4.x.x.stable ...`) dikembalikan.

### Penggunaan di Menu
Menu `[ Check installed Godot version ]` (Bab 11) memanggil fungsi ini dan menampilkan:
- Jika ditemukan: versi yang terdeteksi + saran untuk mengatur `api_version` sesuai versi tersebut.
- Jika tidak ditemukan: pesan bahwa Godot tidak ada di `PATH`.

---

## 8. Fungsi `update_daftar_versi_online()` - Tarik Versi dari GitHub

*(Lokasi Baris 585 - 612)*
```python
def update_daftar_versi_online():
    try:
        hasil = subprocess.run(
            ["git", "ls-remote", "--heads", "https://github.com/godotengine/godot-cpp"],
            capture_output=True, text=True, timeout=15
        )
        if hasil.returncode != 0:
            return None
        import re as _re
        ditemukan = []
        for baris in hasil.stdout.splitlines():
            m = _re.search(r"refs/heads/(\d+)\.(\d+)$", baris)
            if m:
                ditemukan.append((int(m.group(1)), int(m.group(2))))
        if not ditemukan:
            return None
        ditemukan = sorted(set(ditemukan))
        versi_list = [f"{maj}.{minr}" for maj, minr in ditemukan]
        cache_path = get_daftar_versi_cache_path()
        with open(cache_path, "w") as f:
            json.dump({"versi": versi_list, "updated": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")}, f, indent=4)
        return versi_list
    except Exception:
        return None
```

### Tujuan
Menghubungi GitHub `godotengine/godot-cpp` untuk mendapatkan daftar **semua branch** yang berformat `refs/heads/<maj>.<minr>` (misal `refs/heads/4.0`, `refs/heads/4.5`), lalu menyimpannya ke cache lokal.

### Mengapa Hanya Branch `refs/heads/angka.angka`?
Karena hanya branch dengan format angka.angka yang relevan untuk daftar versi godot-cpp. Branch lain (misal `master`, `3.x`, `4.5-rc1`) tidak diambil karena:
- `master` selalu ditambahkan manual di `load_daftar_versi()`.
- Branch `3.x` tidak digunakan di Godot 4.
- Branch `-rc` atau `-beta` tidak stabil untuk produksi.

### Sortir dan Unik
Setelah mengumpulkan semua pasangan `(maj, minr)`, fungsi:
1. Mengubah ke `set` untuk menghilangkan duplikat.
2. Mengurutkan secara ascending (dari versi tertua ke terbaru).
3. Mengubah kembali ke format `"maj.minr"`.

### Penanganan Gagal
Jika terjadi error (timeout, git tidak terinstall, network error), fungsi mengembalikan `None` dan **tidak** mengubah cache. Menu akan menampilkan pesan error dan tetap menggunakan daftar lama.

### Format Cache

```json
{
  "versi": ["4.0", "4.1", "4.2", "4.3", "4.4", "4.5"],
  "updated": "2026-07-25 14:30:22"
}
```

> [!NOTE] **Catatan Penting:**
Cache ini **tidak** menyertakan `"master"` atau `"custom..."` – keduanya ditambahkan secara dinamis di `load_daftar_versi()`.

---

## 9. Fungsi `get_godot_cpp_status()` - Status Binding Aktif

^02277e

*(Lokasi Baris 615 - 631)*
```python
def get_godot_cpp_status(branch, api_version):
    d = f"godot-cpp-master-api{api_version}" if branch == "master" else f"godot-cpp-{branch}"
    if not os.path.isdir(d):
        return "not downloaded yet"
    bin_dir = os.path.join(d, "bin")
    linux_ok = len(glob.glob(os.path.join(bin_dir, "*linux*"))) > 0
    windows_ok = len(glob.glob(os.path.join(bin_dir, "*windows*"))) > 0
    if linux_ok and windows_ok:
        return "compiled: linux+windows"
    elif linux_ok:
        return "compiled: linux only"
    elif windows_ok:
        return "compiled: windows only"
    else:
        return "downloaded, not compiled yet"
```

### Tujuan
Menentukan status kompilasi dari **versi godot-cpp yang sedang aktif** (sesuai pilihan di menu). Status ini ditampilkan langsung di menu utama, di sebelah pilihan `godot-cpp version`.

### Perbedaan Nama Folder
Fungsi ini menggunakan logika yang sama dengan `build_logic.py` (Bab 13) dan `setup_godot_cpp.py` (Bab 16) untuk menentukan nama folder:
- Jika `branch == "master"` ke `godot-cpp-master-api{api_version}`
- Jika `branch != "master"` ke `godot-cpp-{branch}`

### 4 Status yang Dikembalikan

| Status                           | Deskripsi                                             |
| -------------------------------- | ----------------------------------------------------- |
| `"not downloaded yet"`           | Folder belum ada sama sekali.                         |
| `"downloaded, not compiled yet"` | Folder ada, tapi `bin/` kosong.                       |
| `"compiled: linux only"`         | Ada file `*.a` untuk Linux, tapi tidak untuk Windows. |
| `"compiled: linux+windows"`      | Ada file `*.a` untuk kedua platform.                  |

### Penggunaan di Menu
Fungsi ini dipanggil setiap kali menu di-_render_ (di dalam `render_menu()`). Status ditampilkan sebagai teks di samping pilihan `godot-cpp version`, misal:

```text
godot-cpp version : 4.2  (compiled: linux+windows)
```

> [!quote] **Referensi Silang:**
Lihat Bab 10 untuk implementasi `render_menu()` dan bagaimana `godot_status` digunakan.

---

## 10. Fungsi `get_last_build_info()` - Informasi Build Terakhir

*(Lokasi Baris 634 - 658)*
```python
def get_last_build_info():
    if not os.path.exists("logs/build_history.json"):
        return None
    try:
        with open("logs/build_history.json", "r") as f:
            history = json.load(f)
        if not history:
            return None
        entry = history[0]
        waktu = datetime.datetime.strptime(entry["time"], "%Y-%m-%d %H:%M:%S")
        detik = int((datetime.datetime.now() - waktu).total_seconds())
        if detik < 60:
            lalu = f"{detik} seconds ago"
        elif detik < 3600:
            lalu = f"{detik // 60} minutes ago"
        elif detik < 86400:
            lalu = f"{detik // 3600} hours ago"
        else:
            lalu = f"{detik // 86400} days ago"
        ikon = "✅" if entry.get("status") == "SUCCESS" else "❌"
        return f"{ikon} {entry.get('plat', '?')} {entry.get('arch', '?')} {entry.get('status', '?')} -- {lalu}"
    except Exception:
        return None
```

### Tujuan
Membaca file `logs/build_history.json` dan mengembalikan **ringkasan build terakhir** yang akan ditampilkan di bagian bawah menu utama.

### Format JSON `build_history.json`
File ini berisi **array** entri build, dengan entri **terbaru di index 0**. Setiap entri memiliki struktur:

```json
{
  "time": "2026-07-25 14:30:22",
  "plat": "linux",
  "arch": "64",
  "status": "SUCCESS",
  "msg": "bin/compile.linux.64.so (2m 15s)",
  "dur": "135s"
}
```
### Menghitung "Waktu Lalu" (Time Ago)
Fungsi menghitung selisih waktu antara `entry["time"]` dan `datetime.datetime.now()`, lalu mengonversinya ke format yang mudah dibaca:
- `< 60 detik` Jadi `X seconds ago`
- `< 3600 detik` Jadi `X minutes ago`
- `< 86400 detik` Jadi `X hours ago`
- `>= 86400 detik` Jadi `X days ago`

### Ikon Status
- `✅` jika `status == "SUCCESS"`.
- `❌` jika `status != "SUCCESS"` (misal `"FAILED"`).

### Penggunaan di Menu
String hasil fungsi ini ditampilkan di bawah menu utama, dengan warna:
- **Hijau** (`active`) jika build sukses.
- **Merah** (`inactive`) jika build gagal.
- **Abu-abu** (`dim`) jika belum pernah build.

```text
Last build: ✅ linux 64 SUCCESS -- 2 hours ago
```

> [!quote] **Referensi Silang:**
> Lihat Bab 10 untuk implementasi `render_menu()` dan bagaimana `last_build` digunakan.

---

## 11. Tabel Rangkuman Utility Functions

| Fungsi                          | Lokasi Baris | Tujuan                                                    | Dipakai Oleh                                          |
| ------------------------------- | ------------ | --------------------------------------------------------- | ----------------------------------------------------- |
| `get_daftar_versi_cache_path()` | 503 - 504    | Mengembalikan nama file cache versi.                      | `load_daftar_versi()`, `update_daftar_versi_online()` |
| `load_daftar_versi()`           | 507 - 525    | Memuat daftar versi dari cache atau fallback.             | Menu `branch` toggle (Bab 11)                         |
| `get_daftar_api_version()`      | 507 dan 525  | Mengembalikan daftar `api_version` untuk branch `master`. | Menu `api_version` toggle (Bab 11)                    |
| `validasi_format_versi()`       | 535 - 540    | Memvalidasi input custom `branch` / `api_version`.        | Menu `custom...` input (Bab 11)                       |
| `cek_semua_godot_cpp()`         | 543 - 567    | Scan semua folder `godot-cpp-*` dan statusnya.            | Menu `[ View all ]` dan `[ Clean up ]` (Bab 11)       |
| `cek_godot_terinstall()`        | 570 - 582    | Deteksi Godot editor di `PATH`.                           | Menu `[ Check installed Godot ]` (Bab 11)             |
| `update_daftar_versi_online()`  | 585 - 612    | Tarik daftar branch dari GitHub ke cache.                 | Menu `[ Update version list ]` (Bab 11)               |
| `get_godot_cpp_status()`        | 615 - 631    | Status kompilasi binding aktif.                           | `render_menu()` (Bab 10)                              |
| `get_last_build_info()`         | 634 - 658    | Ringkasan build terakhir dari log.                        | `render_menu()` (Bab 10)                              |

---

## 12. Keterkaitan dengan Fitur Baru v2.4.0

Meskipun bab ini fokus pada fungsi-fungsi utility, beberapa fitur baru v2.4.0 **memengaruhi** cara kerja fungsi-fungsi ini:

> [!done]- Opsi bits (Arsitektur)
> ### Opsi `bits` (Arsitektur)
> Meskipun tidak secara langsung mengubah fungsi-fungsi di atas, opsi `bits` (64/32-bit) **memengaruhi**:
> - **`cek_semua_godot_cpp()`** - scan folder `godot-cpp-*` tidak tergantung arsitektur, tapi status kompilasi di `get_godot_cpp_status()` **akan berbeda** antara build 32-bit dan 64-bit. Folder `godot-cpp-master-api4.7` yang sama bisa berisi file `bin/*linux*template_debug*x86_64*` (64-bit) atau `x86_32*` (32-bit).
> - **`get_godot_cpp_status()`** - pola glob `"*linux*"` tetap sama, tapi file yang ditemukan berbeda tergantung arsitektur yang dipilih di `build_options.json`. **Namun**, fungsi ini tidak membaca `bits` dari `build_options.json` - hanya mengecek apakah ada file `*linux*` (tanpa memedulikan `x86_64`/`x86_32`). Ini adalah **kelemahan** yang harus diperhatikan: jika kamu mengganti arsitektur, status kompilasi mungkin tetap terbaca "compiled" padahal file untuk arsitektur yang baru belum ada.

> [!done]- LICENSE_TEXT dan Menu Lisensi
> ### `LICENSE_TEXT` dan Menu Lisensi
> Fungsi utility di bab ini **tidak** terlibat langsung dengan lisensi. Lisensi ditangani oleh:
> - `show_scrollable_dialog()` (Bab 10) – untuk menampilkan teks panjang.
> - Menu [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `license` - View License (v2.4.0)|`license`]] dan [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `export_license` - Export LICENSE (v2.4.0)|`export_license`]] – untuk melihat dan mengekspor.

> [!done]- Event Mouse dan STYLE
> ### Event Mouse dan STYLE
> Fungsi-fungsi di bab ini **tidak** berinteraksi dengan mouse atau style - keduanya adalah tanggung jawab fungsi render dan dialog (Bab 10 - 11).

>[!tip]+ **Saran Perbaikan:**
>Di versi mendatang, `get_godot_cpp_status()` sebaiknya membaca `bits` dari `build_options.json` dan menyesuaikan pola glob menjadi `*{platform}*{SCONS_TARGET}*{ARCH_SCONS}*` seperti yang dilakukan di `setup_godot_cpp.py`.

---

## 13. Kesimpulan

Pada bab ini, kita telah membahas secara mendalam **sembilan fungsi utility** yang menjadi tulang punggung manajemen versi godot-cpp dan informasi build di sistem KOBI GDExtension. Fungsi-fungsi ini:
1. **Mengelola cache versi** - menyimpan daftar branch dari GitHub secara lokal, sehingga menu tetap responsif tanpa perlu koneksi internet terus-menerus.
2. **Memvalidasi input custom** - mencegah kesalahan ketik pada `branch` dan `api_version`.
3. **Memberikan visibilitas penuh** - menampilkan status kompilasi dan ukuran semua folder godot-cpp yang pernah di-_setup_.
4. **Mendeteksi environment** - mencari Godot editor yang terinstall di sistem untuk memberikan saran yang relevan.
5. **Menampilkan riwayat build** - memberi tahu pengguna kapan terakhir kali build berhasil atau gagal.