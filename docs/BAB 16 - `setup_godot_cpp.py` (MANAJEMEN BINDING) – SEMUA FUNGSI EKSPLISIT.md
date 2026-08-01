# BAB 16 - "setup_godot_cpp.py" (MANAJEMEN BINDING)

---

## 1. Pendahuluan: Mengelola Binding Godot-CPP

Setelah kita membahas seluruh logika build di `build_logic.py` (Bab 13 - 15), kini saatnya beralih ke **komponen pendukung yang tak kalah penting**: `setup_godot_cpp.py`. File ini adalah **manajer binding** godot-cpp - bertanggung jawab untuk:
1. **Meng-clone** repository godot-cpp dari GitHub (dengan branch yang dipilih di menu).
2. **Mengompilasi** godot-cpp untuk platform yang diperlukan (Linux dan/atau Windows).
3. **Menghapus** folder godot-cpp jika pengguna ingin membersihkan atau memulai ulang.

File ini di-**generate** secara otomatis oleh `jalankan_bootstrapper.sh` (di bagian akhir, bersama `bootstrap_scons_gui.py`) dan selalu tersedia di folder proyek. Ini adalah **bagian kedua** dari sistem bootstrapper yang di-_embed_ sebagai heredoc `PYEOF_SETUP` di **Baris 1400–1580** dari shell script.

Pada Bab 16, kita akan membahas **seluruh fungsi** yang ada di `setup_godot_cpp.py`:
1. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#2. Fungsi Pembaca Opsi dari `build_options.json`|Fungsi pembaca opsi - `baca_mode_dari_build_options()`, `baca_branch_dari_build_options()`, `baca_api_version_dari_build_options()`, dan `baca_bits_dari_build_options()` (v2.4.0).]]
2. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#3. Konstanta dan Variabel Global|Konstanta build - `MODE`, `SCONS_TARGET`, `GODOT_CPP_BRANCH`, `GODOT_CPP_API_VERSION`, `BITS`, `ARCH_SCONS`, `REPO_URL`, dan `GODOT_CPP_DIR`.]]
3. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#`validasi_format_versi()` - Salinan dari GUI|`validasi_format_versi()` - validasi input custom (salinan dari GUI).]]
4. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#4. Fungsi `jalankan()` - Wrapper Subprocess|`jalankan()` - wrapper untuk menjalankan subprocess dengan error handling.]]
5. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#5. Fungsi `cek_command_ada()` - Mengecek Command di PATH|`cek_command_ada()` - mengecek keberadaan command di `PATH`.]]
6. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#6. Fungsi `cek_branch_ada_di_remote()` - Cek Branch di GitHub|`cek_branch_ada_di_remote()` - memeriksa branch di GitHub sebelum clone.]]
7. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#7. Fungsi `clone_godot_cpp()` - Logika Cloning|`clone_godot_cpp()` - cloning dengan logika redownload (interaktif maupun non-interaktif).]]
8. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#8. Fungsi `sudah_dicompile()` - Cek Status Kompilasi|`sudah_dicompile()` - mengecek apakah godot-cpp sudah di-compile untuk platform tertentu.]]
9. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#9. Fungsi `compile_godot_cpp()` - Mengompilasi Binding|`compile_godot_cpp()` - mengompilasi godot-cpp dengan SCons.]]
10. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#10. Fungsi `hapus_godot_cpp()` - Menghapus Folder Binding|`hapus_godot_cpp()` - menghapus folder godot-cpp dengan konfirmasi.]]
11. [[BAB 16 - `setup_godot_cpp.py` (MANAJEMEN BINDING) – SEMUA FUNGSI EKSPLISIT#11. Fungsi `main()` - Alur Eksekusi Utama|`main()` - alur eksekusi utama.]]

> [!quote] **Referensi Silang:** 
> - `setup_godot_cpp.py` dipanggil oleh menu `[ Setup godot-cpp ]` dan [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `bersihkan_lama` - Clean Up Old godot-cpp|`[ Delete godot-cpp ]` di Bab 11]].
> - `setup_godot_cpp.py` membaca `build_options.json` yang sama dengan [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)|`build_logic.py.]]
> - Logika penentuan `GODOT_CPP_DIR` di sini **harus identik** dengan [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)#BAB 13 - ISI "build_logic.py" (PROLOG, KELAS, KONFIGURASI)|`build_logic.py`]] dan [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)#9. Fungsi `get_godot_cpp_status()` - Status Binding Aktif|`get_godot_cpp_status()`]].

---

## 2. Fungsi Pembaca Opsi dari `build_options.json`

*(Lokasi Baris 1889 - 1932)*
```python
def baca_mode_dari_build_options():
    """Ikutin mode (debug/release) yang lagi dipilih di menu curses -> build_options.json,
    biar godot-cpp yang di-compile konsisten sama compile.<plat>.<bits> project kamu.
    Kalau file belum ada (misal setup_godot_cpp.py dijalanin duluan sebelum pernah
    buka menu), default ke "debug" (lebih aman buat development)"""
    if os.path.exists("build_options.json"):
        try:
            with open("build_options.json", "r") as f:
                return json.load(f).get("mode", "debug")
        except: pass
    return "debug"
def baca_branch_dari_build_options():
    """Baca versi godot-cpp (branch) yang dipilih di menu curses -> build_options.json.
    Kalau belum pernah diset, default "4.2"."""
    if os.path.exists("build_options.json"):
        try:
            with open("build_options.json", "r") as f:
                return json.load(f).get("godot_cpp_branch", "4.2")
        except: pass
    return "4.2"
def baca_api_version_dari_build_options():
    """Baca target api_version (cuma dipakai kalau branch == 'master') dari build_options.json.
    Default "4.7" kalau belum pernah diset."""
    if os.path.exists("build_options.json"):
        try:
            with open("build_options.json", "r") as f:
                return json.load(f).get("godot_cpp_api_version", "4.7")
        except: pass
    return "4.7"
def baca_bits_dari_build_options():
    """Baca arsitektur (64/32-bit) yang dipilih di menu curses -> build_options.json.
    Default "64" kalau belum pernah diset (paling umum dipakai)."""
    if os.path.exists("build_options.json"):
        try:
            with open("build_options.json", "r") as f:
                return json.load(f).get("bits", "64")
        except: pass
    return "64"
```

### Tujuan
Keempat fungsi ini adalah **getter** sederhana yang membaca nilai dari `build_options.json`. Mereka dipanggil di awal `setup_godot_cpp.py` untuk menentukan:
- **Mode build** (`debug`/`release`) - agar godot-cpp dikompilasi dengan mode yang sama dengan proyek.
- **Branch godot-cpp** - versi binding yang akan di-clone.
- **API version** - untuk branch `master`, menentukan target Godot.
- **Bits** (v2.4.0) - arsitektur 64/32-bit untuk compile godot-cpp.

### Nilai Default

Setiap fungsi memiliki **fallback** yang aman jika `build_options.json` tidak ada atau corrupt:

| Fungsi                                  | Default   | Alasan                                                  |
| --------------------------------------- | --------- | ------------------------------------------------------- |
| `baca_mode_dari_build_options()`        | `"debug"` | Debug lebih aman untuk development (ada debug symbols). |
| `baca_branch_dari_build_options()`      | `"4.2"`   | Versi stabil dan umum digunakan.                        |
| `baca_api_version_dari_build_options()` | `"4.7"`   | Versi terbaru yang didukung oleh master (per v2.4.0).   |
| `baca_bits_dari_build_options()`        | `"64"`    | 64-bit adalah arsitektur paling umum.                   |

### Exception Handling
Semua fungsi menggunakan `try/except` untuk menangani:
- File tidak ditemukan (`FileNotFoundError`).
- File corrupt (JSON decode error).
- Kunci tidak ada di dictionary (`KeyError`).

Jika terjadi error, fungsi mengembalikan nilai default tanpa crash.

---

## 3. Konstanta dan Variabel Global

*(Lokasi Baris 1935 - 1966)*
```python
def validasi_format_versi(versi):
    """Validasi kasar format versi angka.angka (mis. '4.7', '4.7.1'). Salinan dari
    fungsi yang sama di bootstrap_scons_gui.py -- dipakai buat ngecek api_version
    sebelum beneran dipakai buat compile."""
    import re as _re
    return bool(_re.match(r'^\d+(\.\d+)+$', versi.strip()))
MODE = baca_mode_dari_build_options()
SCONS_TARGET = "template_debug" if MODE == "debug" else "template_release"
GODOT_CPP_BRANCH = baca_branch_dari_build_options()
GODOT_CPP_API_VERSION = baca_api_version_dari_build_options()
BITS = baca_bits_dari_build_options()
ARCH_SCONS = "x86_64" if BITS == "64" else "x86_32"
REPO_URL = "https://github.com/godotengine/godot-cpp"
if GODOT_CPP_BRANCH == "master":
    GODOT_CPP_DIR = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
    GODOT_CPP_DIR = f"godot-cpp-{GODOT_CPP_BRANCH}"
NONINTERAKTIF = os.environ.get("KOBI_NONINTERAKTIF") == "1"
```

### `validasi_format_versi()` - Salinan dari GUI

*(Lokasi Baris 535 - 540 Versi 1)*
*(Lokasi Baris 1569 - 1598 Versi Baru 1)*
*(Lokasi Baris 1688 - 1690 Versi Baru 2)*
*(Lokasi Baris 1635 - 1940 Versi 2)*

Fungsi ini adalah **salinan persis** dari fungsi yang sama di [[BAB 7 - `bootstrap_scons_gui.py` FUNGSI UTILITY (VERSI, CACHE, SCAN)|`bootstrap_scons_gui.py`.]] Digunakan untuk memvalidasi input `api_version` sebelum digunakan untuk compile. Jika format tidak valid (misal `"4.7.0.0"` atau `"empat.tujuh"`), fungsi akan mengembalikan `False`.

### Konstanta Build

|Konstanta|Nilai|Deskripsi|
|---|---|---|
|`MODE`|`"debug"` atau `"release"`|Mode build dari `build_options.json`|
|`SCONS_TARGET`|`"template_debug"` atau `"template_release"`|Target SCons untuk godot-cpp|
|`GODOT_CPP_BRANCH`|Branch yang dipilih|Versi godot-cpp (misal `"4.2"`, `"master"`)|
|`GODOT_CPP_API_VERSION`|Versi API|Target Godot (hanya untuk `"master"`)|
|`BITS`|`"64"` atau `"32"`|Arsitektur (v2.4.0)|
|`ARCH_SCONS`|`"x86_64"` atau `"x86_32"`|Nilai `arch` yang dipahami SCons|
|`REPO_URL`|`https://github.com/godotengine/godot-cpp`|URL repository godot-cpp|
|`GODOT_CPP_DIR`|`godot-cpp-master-api{api}` atau `godot-cpp-{branch}`|Nama folder binding|

### Penentuan `GODOT_CPP_DIR` - Logika Penting

*(Lokasi Baris 1956 - 1959)*
```python
if GODOT_CPP_BRANCH == "master":
    GODOT_CPP_DIR = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
    GODOT_CPP_DIR = f"godot-cpp-{GODOT_CPP_BRANCH}"
```

Logika ini **harus identik** dengan:
- `build_logic.py` ==(Bab 13)== - menentukan `godot_cpp_path`.
- `get_godot_cpp_status()` ==(Bab 7)== - menentukan path untuk status kompilasi.
- `main()` di `bootstrap_scons_gui.py` ==(Bab 11)== - menentukan folder aktif untuk cleanup.

### `NONINTERAKTIF` - Mode Non-Interaktif

*(Lokasi Baris 1966)*
```python
NONINTERAKTIF = os.environ.get("KOBI_NONINTERAKTIF") == "1"
```

`NONINTERAKTIF` adalah flag yang **sangat penting** untuk integrasi dengan menu curses (Bab 11). Ketika `setup_godot_cpp.py` dipanggil dari menu `[ Setup godot-cpp ]` atau `[ Delete godot-cpp ]`:
1. Menu sudah menanyakan konfirmasi (misal "Re-download?" atau "Type DELETE").
2. Menu mengatur environment variable `KOBI_NONINTERAKTIF=1`.
3. `setup_godot_cpp.py` membaca flag ini dan **tidak** meminta input interaktif.
4. Semua keputusan sudah dibuat di menu, script hanya menjalankan perintah.

Ini mencegah **dua lapis input** yang membingungkan (menu curses sudah meminta input, lalu script meminta input lagi di terminal yang sama).

---

## 4. Fungsi `jalankan()` - Wrapper Subprocess

*(Lokasi Baris 1969 - 1974)*
```python
def jalankan(cmd, cwd=None):
    print(f">>> Running: {' '.join(cmd)}" + (f"  (in folder {cwd})" if cwd else ""))
    hasil = subprocess.run(cmd, cwd=cwd)
    if hasil.returncode != 0:
        print(f"Failed to run: {' '.join(cmd)}")
        sys.exit(1)
```

### Tujuan
`jalankan()` adalah wrapper sederhana untuk `subprocess.run()` yang:
1. Mencetak command yang akan dijalankan (untuk transparansi).
2. Menjalankan command di direktori yang ditentukan (opsional).
3. Jika return code tidak 0 (`!= 0`), cetak error dan **keluar dari script** (`sys.exit(1)`).

### Mengapa `sys.exit(1)`?
Karena `setup_godot_cpp.py` adalah script **otomatis** yang dipanggil oleh menu curses (atau dijalankan manual). Jika ada error (misal `git clone` gagal), script sebaiknya berhenti dan memberi tahu pengguna melalui terminal (yang akan terlihat di output live di `run_subprocess_in_curses()`).

### Penggunaan

```python
jalankan(["git", "clone", "--recursive", "-b", branch, REPO_URL, GODOT_CPP_DIR])
jalankan(["scons", f"platform={platform}", f"target={SCONS_TARGET}", f"arch={ARCH_SCONS}"], cwd=GODOT_CPP_DIR)
```

---

## 5. Fungsi `cek_command_ada()` - Mengecek Command di PATH

*(Lokasi Baris 1977 - 1979)*
```python
def cek_command_ada(nama_command):
    from shutil import which
    return which(nama_command) is not None
```

### Tujuan
Mengecek apakah sebuah command tersedia di `PATH` sistem. Ini digunakan untuk memeriksa dependensi:
- `git` - untuk cloning.
- `scons` - untuk kompilasi godot-cpp.
- `x86_64-w64-mingw32-g++` / `i686-w64-mingw32-g++` - compiler Windows.

### `shutil.which()`

`shutil.which()` adalah fungsi bawaan Python yang mencari executable di `PATH`. Mengembalikan path absolut jika ditemukan, `None` jika tidak.

### Penggunaan

*(Lokasi Baris 2121 - 2123)*
```python
if not cek_command_ada("git"):
    print("'git' is not installed. Install it first: sudo apt install git")
    sys.exit(1)
```

---

## 6. Fungsi `cek_branch_ada_di_remote()` - Cek Branch di GitHub

*(Lokasi Baris 1982 - 1995)*
```python
def cek_branch_ada_di_remote(branch):
    """Cek ke GitHub apakah branch ini beneran ada di repo godot-cpp, SEBELUM clone.
    Kalau gagal cek (misal gak ada internet), anggap 'gak yakin' -- biarin user lanjut
    sendiri, jangan blokir total cuma gara-gara network check gagal."""
    try:
        hasil = subprocess.run(
            ["git", "ls-remote", "--heads", REPO_URL, branch],
            capture_output=True, text=True, timeout=15
        )
        if hasil.returncode != 0:
            return None  # gagal cek (network/git error), gak yakin
        return bool(hasil.stdout.strip())
    except Exception:
        return None
```

### Tujuan
Fungsi ini memeriksa apakah branch tertentu **benar-benar ada** di repository godot-cpp di GitHub. Ini mencegah pengguna mencoba clone branch yang tidak ada dan mendapatkan error yang membingungkan.

### Return Value
- **`True`** - branch ditemukan.
- **`False`** - branch tidak ditemukan.
- **`None`** - gagal cek (network error, git error, timeout).

### Timeout 15 Detik
`timeout=15` mencegah script menggantung terlalu lama jika koneksi internet lambat atau tidak ada.

### Penggunaan

```python
ada = cek_branch_ada_di_remote(GODOT_CPP_BRANCH)
if ada is False:
    print(f"WARNING: Branch '{GODOT_CPP_BRANCH}' NOT FOUND in {REPO_URL}.")
    # Tanya user apakah tetap lanjut (jika interaktif)
```

---

## 7. Fungsi `clone_godot_cpp()` - Logika Cloning

*(Lokasi Baris 1998 - 2059)*
```python
def clone_godot_cpp():
    if os.path.isdir(GODOT_CPP_DIR):
        if NONINTERAKTIF:
            if os.environ.get("KOBI_REDOWNLOAD") == "1":
                print(f"Removing old folder '{GODOT_CPP_DIR}' (redownload requested)...")
                shutil.rmtree(GODOT_CPP_DIR)
            else:
                print(f"Using existing '{GODOT_CPP_DIR}', skipping clone.")
                return
        else:
            print(f"Folder '{GODOT_CPP_DIR}' already exists.")
            print("   [1] Use existing (skip download)")
            print("   [2] Re-download (delete old folder, clone from scratch)")
            pilihan = input("   Choose (1/2, default 1): ").strip()
            if pilihan == "2":
                print(f"Removing old folder '{GODOT_CPP_DIR}'...")
                shutil.rmtree(GODOT_CPP_DIR)
            else:
                print(f"Using existing '{GODOT_CPP_DIR}', skipping clone.")
                return
    print(f"Checking whether branch '{GODOT_CPP_BRANCH}' exists in the godot-cpp repo...")
    if GODOT_CPP_BRANCH == "master":
        print("Master mode -- this branch always exists, skipping branch check.")
        if not validasi_format_versi(GODOT_CPP_API_VERSION):
            print(f"WARNING: '{GODOT_CPP_API_VERSION}' is not a valid api_version format (correct example: 4.7).")
            if NONINTERAKTIF:
                print("Proceeding automatically (non-interactive mode from the menu) -- it'll show up at compile time if wrong.")
            else:
                lanjut = input("   Still proceed to compile with this value? (y/N): ").strip().lower()
                if lanjut != "y":
                    print("Cancelled. Change Target api_version via the curses menu then try again.")
                    sys.exit(1)
        else:
            print(f"Target api_version '{GODOT_CPP_API_VERSION}' has a valid format.")
    else:
        ada = cek_branch_ada_di_remote(GODOT_CPP_BRANCH)
        if ada is False:
            print(f"WARNING: Branch '{GODOT_CPP_BRANCH}' NOT FOUND in {REPO_URL}.")
            if NONINTERAKTIF:
                print("Proceeding automatically (non-interactive mode from the menu) -- it'll show up at clone time if wrong.")
            else:
                lanjut = input("   Still try to clone? (y/N): ").strip().lower()
                if lanjut != "y":
                    print("Cancelled. Change the version via the curses menu (toggle 'godot-cpp version') then try again.")
                    sys.exit(1)
        elif ada is None:
            print("   (Can't be sure -- proceeding anyway, it'll show up at clone time if wrong.)")
        else:
            print(f"Branch '{GODOT_CPP_BRANCH}' found.")
    print(f"Cloning godot-cpp (branch {GODOT_CPP_BRANCH}) into '{GODOT_CPP_DIR}'...")
    jalankan([
        "git", "clone", "--recursive",
        "-b", GODOT_CPP_BRANCH,
        REPO_URL, GODOT_CPP_DIR
    ])
    print("Clone finished.")
```

### Tujuan
`clone_godot_cpp()` adalah fungsi kompleks yang menangani seluruh logika cloning godot-cpp:
1. **Cek apakah folder sudah ada**.
2. **Tanyakan (atau baca dari env) apakah akan redownload**.
3. **Cek branch di remote** (atau validasi `api_version` untuk master).
4. **Lakukan clone** dengan `git clone --recursive -b <branch>`.

### Logika Redownload

**Jika folder sudah ada:**

|Mode|Perilaku|
|---|---|
|**Interaktif** (`NONINTERAKTIF = False`)|Tanya user: "[1] Use existing" atau "[2] Re-download". Default 1.|
|**Non-Interaktif** (`NONINTERAKTIF = True`)|Baca `KOBI_REDOWNLOAD` dari environment. Jika `"1"`, hapus folder lama. Jika `"0"` atau tidak ada, gunakan yang sudah ada.|

### Cek Branch vs Validasi API Version
**Untuk branch `"master"`:**
- Branch `master` **selalu ada** - tidak perlu cek ke GitHub.
- **Validasi `api_version`** - cek format menggunakan `validasi_format_versi()`. Jika tidak valid, beri peringatan dan tanya (jika interaktif) apakah tetap lanjut.

**Untuk branch lainnya:**
- Cek ke GitHub menggunakan `cek_branch_ada_di_remote()`.
- Jika tidak ditemukan (`False`), beri peringatan dan tanya (jika interaktif) apakah tetap lanjut.
- Jika gagal cek (`None`), lanjutkan dengan peringatan "Can't be sure".

### `git clone --recursive`
Flag `--recursive` penting karena godot-cpp memiliki **submodule** (`godot-headers`). Tanpa flag ini, submodule tidak akan di-clone dan compile akan gagal.

### Output

```text
Checking whether branch '4.2' exists in the godot-cpp repo...
Branch '4.2' found.
Cloning godot-cpp (branch 4.2) into 'godot-cpp-4.2'...
>>> Running: git clone --recursive -b 4.2 https://github.com/godotengine/godot-cpp godot-cpp-4.2
Clone finished.
```

---

## 8. Fungsi `sudah_dicompile()` - Cek Status Kompilasi

*(Lokasi Baris 2062 - 2067)*
```python
def sudah_dicompile(platform):
    """Cek kasar: apakah sudah ada file .a / .lib hasil compile buat platform+mode+arch ini.
    Pola nyertain ARCH_SCONS (x86_64/x86_32) juga -- biar build 32-bit dan 64-bit yang
    kebetulan ada di folder godot-cpp yang sama gak saling ketuker/anggep 'udah compile'."""
    pola = os.path.join(GODOT_CPP_DIR, "bin", f"*{platform}*{SCONS_TARGET}*{ARCH_SCONS}*")
    return len(glob.glob(pola)) > 0
```

### Tujuan
Fungsi ini mengecek apakah godot-cpp sudah di-compile untuk platform tertentu. Ini mencegah kompilasi ulang yang tidak perlu jika hasil compile sudah ada.

###  Pola Pencarian

*(Lokasi Baris 2066)*
```python
pola = os.path.join(GODOT_CPP_DIR, "bin", f"*{platform}*{SCONS_TARGET}*{ARCH_SCONS}*")
```

Contoh pola:
- Linux 64-bit, release: `godot-cpp-4.2/bin/*linux*template_release*x86_64*`
- Windows 32-bit, debug: `godot-cpp-4.2/bin/*windows*template_debug*x86_32*`

### Mengapa Menyertakan `ARCH_SCONS`?
Ini adalah **perbaikan penting di v2.4.0**. Tanpa `ARCH_SCONS`, pola akan mencari `*linux*` saja dan bisa menemukan file 64-bit meskipun pengguna sekarang menginginkan 32-bit. Dengan menyertakan `ARCH_SCONS`, 64-bit dan 32-bit **tidak saling ketuker**.

### Return Value
- **`True`** - ada file yang cocok dengan pola (sudah di-compile).
- **`False`** - tidak ada file yang cocok (belum di-compile).

---

## 9. Fungsi `compile_godot_cpp()` - Mengompilasi Binding

*(Lokasi Baris 2070 - 2085)*
```python
def compile_godot_cpp(platform):
    if sudah_dicompile(platform):
        print(f"godot-cpp for '{platform}' ({SCONS_TARGET}, {ARCH_SCONS}) has already been compiled, skipping.")
        return
    cmd = ["scons", f"platform={platform}", f"target={SCONS_TARGET}", f"arch={ARCH_SCONS}", f"-j{os.cpu_count() or 2}"]
    keterangan_versi = f"{SCONS_TARGET}, {ARCH_SCONS}"
    if GODOT_CPP_BRANCH == "master":
        cmd.append(f"api_version={GODOT_CPP_API_VERSION}")
        keterangan_versi = f"{SCONS_TARGET}, {ARCH_SCONS}, api_version={GODOT_CPP_API_VERSION}"
    print(f"Compiling godot-cpp for platform '{platform}', target '{keterangan_versi}'... (this can take a while)")
    jalankan(cmd, cwd=GODOT_CPP_DIR)
    print(f"Finished compiling godot-cpp for '{platform}' ({keterangan_versi}).")
```

### Tujuan
`compile_godot_cpp()` menjalankan SCons untuk mengompilasi godot-cpp untuk platform tertentu (Linux atau Windows).

### Cek Apakah Sudah Di-Compile

*(Lokasi Baris 2071 - 2073)*
```python
if sudah_dicompile(platform):
    print(f"godot-cpp for '{platform}' ({SCONS_TARGET}, {ARCH_SCONS}) has already been compiled, skipping.")
    return
```

Jika sudah ada hasil compile, skip untuk menghemat waktu.

### Perintah SCons

*(Lokasi Baris 2075)*
```python
cmd = ["scons", f"platform={platform}", f"target={SCONS_TARGET}", f"arch={ARCH_SCONS}", f"-j{os.cpu_count() or 2}"]
```

- **`platform={platform}`** - `"linux"` atau `"windows"`.
- **`target={SCONS_TARGET}`** - `"template_debug"` atau `"template_release"`.
- **`arch={ARCH_SCONS}`** - `"x86_64"` atau `"x86_32"`.
- **`-j{os.cpu_count() or 2}`** - jumlah proses paralel (semua core, atau 2 jika tidak bisa deteksi).

### API Version untuk Branch Master

*(Lokasi Baris 2077 - 2080)*
```python
if GODOT_CPP_BRANCH == "master":
    cmd.append(f"api_version={GODOT_CPP_API_VERSION}")
```

Jika branch `"master"`, tambahkan argumen `api_version` untuk menentukan target Godot. Ini adalah fitur penting untuk godot-cpp 10.x.

### Output

```text
Compiling godot-cpp for platform 'linux', target 'template_release, x86_64'... (this can take a while)
>>> Running: scons platform=linux target=template_release arch=x86_64 -j8
Finished compiling godot-cpp for 'linux' (template_release, x86_64).
```

---

## 10. Fungsi `hapus_godot_cpp()` - Menghapus Folder Binding

*(Lokasi Baris 2088 - 2104)*
```python
def hapus_godot_cpp():
    """Hapus total folder godot-cpp-<branch> yang lagi aktif. Dipanggil dari menu curses
    (opsi [ Hapus godot-cpp ]) atau lewat --hapus di command line."""
    if not os.path.isdir(GODOT_CPP_DIR):
        print(f"Folder '{GODOT_CPP_DIR}' doesn't exist, nothing to delete.")
        return
    print(f"This will COMPLETELY delete folder '{GODOT_CPP_DIR}' (approximately {round(sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fn in os.walk(GODOT_CPP_DIR) for f in fn) / (1024*1024))} MB).")
    if NONINTERAKTIF:
        konfirmasi = os.environ.get("KOBI_HAPUS_KONFIRMASI", "")
    else:
        konfirmasi = input(f"   Type 'DELETE' (all caps) to confirm, or ENTER to cancel: ").strip()
    if konfirmasi == "DELETE":
        shutil.rmtree(GODOT_CPP_DIR)
        print(f"Folder '{GODOT_CPP_DIR}' has been deleted.")
    else:
        print("Cancelled, folder was not deleted.")
```

### Tujuan
`hapus_godot_cpp()` menghapus folder godot-cpp yang aktif. Ini digunakan oleh:
- Menu `[ Delete godot-cpp ]` di [[BAB 11 - `bootstrap_scons_gui.py` INTI MAIN LOOP DAN NAVIGASI KEYBOARD#Menu `hapus` - Delete Active godot-cpp|curses.]]
- Command line `python3 setup_godot_cpp.py --hapus`.

### Perhitungan Ukuran

```python
round(sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fn in os.walk(GODOT_CPP_DIR) for f in fn) / (1024*1024))
```

Menghitung total ukuran folder dalam MB dengan `os.walk()` dan `os.path.getsize()`. Ini memberi tahu pengguna berapa banyak ruang disk yang akan dibebaskan.

### Konfirmasi

|Mode|Perilaku|
|---|---|
|**Interaktif** (`NONINTERAKTIF = False`)|Tanya user: "Type 'DELETE' to confirm".|
|**Non-Interaktif** (`NONINTERAKTIF = True`)|Baca `KOBI_HAPUS_KONFIRMASI` dari environment. Jika `"DELETE"`, hapus; jika tidak, batalkan.|

### `shutil.rmtree()`

`shutil.rmtree()` adalah fungsi Python untuk menghapus direktori beserta seluruh isinya secara rekursif. **Peringatan:** Operasi ini **tidak dapat dibatalkan** - itulah mengapa konfirmasi `"DELETE"` sangat ketat.

---

## 11. Fungsi `main()` - Alur Eksekusi Utama

*(Lokasi Baris 2107 - 2147)*
```python
def main():
    print("=== Setup godot-cpp (automatic) ===")
    if GODOT_CPP_BRANCH == "master":
        print(f"    Version/branch : master, api_version={GODOT_CPP_API_VERSION}  (folder: {GODOT_CPP_DIR})")
    else:
        print(f"    Version/branch : {GODOT_CPP_BRANCH}  (folder: {GODOT_CPP_DIR})")
    print(f"    Active mode  : {MODE.upper()} -> scons target={SCONS_TARGET}")
    print(f"    Architecture : {BITS}-bit -> scons arch={ARCH_SCONS}\n")
    if "--hapus" in sys.argv:
        hapus_godot_cpp()
        return
    if not cek_command_ada("git"):
        print("'git' is not installed. Install it first: sudo apt install git")
        sys.exit(1)
    if not cek_command_ada("scons"):
        print("'scons' is not installed / not found in PATH.")
        sys.exit(1)
    clone_godot_cpp()
    compile_godot_cpp("linux")
    MINGW_CXX = "x86_64-w64-mingw32-g++" if BITS == "64" else "i686-w64-mingw32-g++"
    if cek_command_ada(MINGW_CXX):
        compile_godot_cpp("windows")
    else:
        print(f"{MINGW_CXX} is not installed, skipping godot-cpp compile for Windows.")
        paket = "mingw-w64" if BITS == "64" else "mingw-w64-i686-dev g++-mingw-w64-i686"
        print(f"    Install it first: sudo apt install {paket}")
    print("\nAll done! godot-cpp is ready to use. Now just run `scons` in your project folder.")
    print(f"   (folder used: {GODOT_CPP_DIR})")
```
### Tujuan
`main()` adalah entry point `setup_godot_cpp.py`. Ia melakukan:
1. **Menampilkan informasi** - versi, mode, arsitektur, folder.
2. **Menangani flag `--hapus`** - jika ada, panggil `hapus_godot_cpp()` dan keluar.
3. **Cek dependensi** - `git` dan `scons`.
4. **Clone godot-cpp** - panggil `clone_godot_cpp()`.
5. **Compile Linux** - selalu dicoba (tidak bergantung pada compiler tambahan).
6. **Compile Windows** - hanya jika compiler mingw yang sesuai terinstall.
7. **Tampilkan pesan selesai** - instruksi untuk pengguna.

### Informasi yang Ditampilkan

```text
=== Setup godot-cpp (automatic) ===
    Version/branch : master, api_version=4.7  (folder: godot-cpp-master-api4.7)
    Active mode  : RELEASE -> scons target=template_release
    Architecture : 64-bit -> scons arch=x86_64
```

### Deteksi Compiler Mingw Dinamis (v2.4.0)

```python
MINGW_CXX = "x86_64-w64-mingw32-g++" if BITS == "64" else "i686-w64-mingw32-g++"
if cek_command_ada(MINGW_CXX):
    compile_godot_cpp("windows")
else:
    print(f"{MINGW_CXX} is not installed, skipping godot-cpp compile for Windows.")
    paket = "mingw-w64" if BITS == "64" else "mingw-w64-i686-dev g++-mingw-w64-i686"
    print(f"    Install it first: sudo apt install {paket}")
```

Ini adalah **perbaikan penting di v2.4.0**:

|BITS|Compiler Windows|Paket Instalasi (Ubuntu/Debian)|
|---|---|---|
|`"64"`|`x86_64-w64-mingw32-g++`|`mingw-w64`|
|`"32"`|`i686-w64-mingw32-g++`|`mingw-w64-i686-dev g++-mingw-w64-i686`|

Sebelum v2.4.0, script selalu memeriksa `x86_64-w64-mingw32-g++` dan memberikan saran `mingw-w64`. Jika pengguna menginginkan 32-bit, mereka akan bingung karena compiler yang salah tidak terdeteksi.

### Mengapa Linux Selalu Dicoba?

Linux compilation tidak memerlukan compiler tambahan selain `g++` yang biasanya sudah terinstall di sistem Linux. Windows compilation memerlukan **cross-compiler** (mingw) yang mungkin tidak terinstall.

### Pesan Selesai

```text
All done! godot-cpp is ready to use. Now just run `scons` in your project folder.
   (folder used: godot-cpp-4.2)
```

---

## 12. Blok `if __name__ == "__main__":`

*(Lokasi Baris 2150 - 2151)*
```python
if __name__ == "__main__":
    main()
```

Standar Python: jika file dijalankan sebagai script (`python3 setup_godot_cpp.py`), panggil `main()`. Jika di-import sebagai module, `main()` tidak dipanggil otomatis.

---

## 13. Tabel Rangkuman Fungsi `setup_godot_cpp.py`

| Fungsi                                  | Lokasi       | Tujuan                                       | Dipanggil Oleh                             |
| --------------------------------------- | ------------ | -------------------------------------------- | ------------------------------------------ |
| `baca_mode_dari_build_options()`        | 1889 - 1899  | Baca mode dari `build_options.json`          | `main()`                                   |
| `baca_branch_dari_build_options()`      | 1902 - 1910  | Baca branch dari `build_options.json`        | `main()`                                   |
| `baca_api_version_dari_build_options()` | 1913 - 1921  | Baca api_version dari `build_options.json`   | `main()`                                   |
| `baca_bits_dari_build_options()`        | 1924 - 1932  | Baca bits dari `build_options.json` (v2.4.0) | `main()`                                   |
| `validasi_format_versi()`               | 1935 - 1940  | Validasi format versi angka.angka            | `clone_godot_cpp()`                        |
| `jalankan()`                            | 1969 - 1974  | Wrapper subprocess dengan error handling     | `clone_godot_cpp()`, `compile_godot_cpp()` |
| `cek_command_ada()`                     | 1977 - 1979  | Cek command di PATH                          | `main()`                                   |
| `cek_branch_ada_di_remote()`            | 1982 - 1995  | Cek branch di GitHub                         | `clone_godot_cpp()`                        |
| `clone_godot_cpp()`                     | 1998 - 2059  | Clone godot-cpp dengan logika redownload     | `main()`                                   |
| `sudah_dicompile()`                     | 2062 - 2067  | Cek status kompilasi per platform            | `compile_godot_cpp()`                      |
| `compile_godot_cpp()`                   | 2070 - 2073  | Kompilasi godot-cpp dengan SCons             | `main()`                                   |
| `hapus_godot_cpp()`                     | 2088 - 2104  | Hapus folder godot-cpp                       | `main()` (jika `--hapus`)                  |
| `main()`                                | 2107 - 2147  | Alur eksekusi utama                          | `if __name__ == "__main__"`                |

---

## 14. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Opsi bits - Perubahan Utama
> ### Opsi `bits` - Perubahan Utama
> Fitur `bits` di v2.4.0 memengaruhi:
> - **`baca_bits_dari_build_options()`** - membaca arsitektur dari JSON.
> - **`BITS`** - konstanta global.
> - **`ARCH_SCONS`** - nilai `"x86_64"` atau `"x86_32"`.
> - **`sudah_dicompile()`** - pola pencarian sekarang menyertakan `ARCH_SCONS` (64-bit dan 32-bit tidak saling ketuker).
> - **`compile_godot_cpp()`** - menambahkan `arch={ARCH_SCONS}` ke perintah SCons.
> - **`main()`** - deteksi mingw dinamis berdasarkan `BITS`.

> [!done]- NONINTERAKTIF dan Integrasi Curses
> ### `NONINTERAKTIF` dan Integrasi Curses
> Mode non-interaktif memungkinkan:
> - Menu curses menangani semua interaksi (konfirmasi redownload, konfirmasi DELETE).
> - `setup_godot_cpp.py` hanya menjalankan perintah tanpa meminta input.
> - Tidak ada "double prompt" yang membingungkan.

> [!done]- Validasi api_version untuk Branch Master
> ### Validasi `api_version` untuk Branch Master
> Jika branch `"master"`, `clone_godot_cpp()` memvalidasi format `api_version` menggunakan `validasi_format_versi()`. Ini mencegah pengguna memasukkan nilai yang salah (misal `"4.7.0.0"` atau `"empat.tujuh"`).

---

## 15. Alur Lengkap `setup_godot_cpp.py`

Berikut adalah alur lengkap saat `setup_godot_cpp.py` dijalankan:

> [!info]- Alur Lengkap setup_godot_cpp.py
> ```text
> 1. Script dimulai
> 	|
> 2. Baca build_options.json (mode, branch, api_version, bits)
> 	|
> 3. Tentukan MODE, SCONS_TARGET, BITS, ARCH_SCONS, GODOT_CPP_DIR
> 	|
> 4. Jika ada argumen --hapus → panggil hapus_godot_cpp() → keluar
> 	|
> 5. Cek git dan scons di PATH
> 	|
> 6. clone_godot_cpp():
>    a. Cek apakah folder sudah ada
>    b. Jika ada dan interaktif → tanya redownload?
>    c. Jika ada dan non-interaktif → baca KOBI_REDOWNLOAD
>    d. Jika folder baru atau redownload:
>       - Cek branch di remote (atau validasi api_version)
>       - git clone --recursive -b <branch>
> 	|
> 7. compile_godot_cpp("linux"):
>    a. Cek apakah sudah ada hasil compile (*linux*{SCONS_TARGET}*{ARCH_SCONS}*)
>    b. Jika belum → scons platform=linux target={SCONS_TARGET} arch={ARCH_SCONS} -j{N}
> 	|
> 8. compile_godot_cpp("windows") (jika mingw terinstall):
>    a. Cek apakah sudah ada hasil compile (*windows*{SCONS_TARGET}*{ARCH_SCONS}*)
>    b. Jika belum → scons platform=windows target={SCONS_TARGET} arch={ARCH_SCONS} -j{N}
> 	|
> 9. Tampilkan "All done!" dan instruksi
> 	|
> 10. Selesai
> ```

---

## 16. Kesimpulan

Pada bab ini, kita telah membahas **seluruh fungsi** di `setup_godot_cpp.py` - script yang mengelola cloning dan kompilasi godot-cpp. Kita mempelajari:
1. **Fungsi pembaca opsi** - membaca `mode`, `branch`, `api_version`, dan `bits` dari `build_options.json`.
2. **Konstanta build** - `MODE`, `SCONS_TARGET`, `GODOT_CPP_BRANCH`, `GODOT_CPP_API_VERSION`, `BITS`, `ARCH_SCONS`, `GODOT_CPP_DIR`.
3. **`validasi_format_versi()`** - validasi input custom (salinan dari GUI).
4. **`jalankan()`** - wrapper subprocess dengan error handling.
5. **`cek_command_ada()`** - mengecek command di PATH.
6. **`cek_branch_ada_di_remote()`** - memeriksa branch di GitHub sebelum clone.
7. **`clone_godot_cpp()`** - cloning dengan logika redownload (interaktif dan non-interaktif).
8. **`sudah_dicompile()`** - mengecek status kompilasi (dengan `ARCH_SCONS` untuk membedakan 64/32-bit).
9. **`compile_godot_cpp()`** - kompilasi godot-cpp dengan SCons.
10. **`hapus_godot_cpp()`** - menghapus folder godot-cpp dengan konfirmasi.
11. **`main()`** - alur eksekusi utama.
12. **Fitur v2.4.0** - opsi `bits` dengan deteksi mingw dinamis, `ARCH_SCONS` di pola pencarian, dan mode non-interaktif.