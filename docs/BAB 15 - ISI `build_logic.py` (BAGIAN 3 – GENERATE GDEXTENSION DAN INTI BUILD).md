# BAB 15 - ISI "build_logic.py" (GENERATE GDEXTENSION DAN INTI BUILD)

---

## 1. Pendahuluan: Mesin Build yang Sebenarnya

Setelah kita memahami [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)|sistem logging]] dan [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)|konfigurasi awa]]l, kini tiba saatnya untuk membahas **inti dari seluruh sistem build** – fungsi `build_with_logging()` dan `generate_gdextension()`. Di sinilah semua konfigurasi yang telah kita bahas di bab-bab sebelumnya benar-benar **dieksekusi** untuk menghasilkan file binary yang siap digunakan di Godot.

Pada Bab 15, kita akan membahas:
1. [[#2. Fungsi `generate_gdextension()` - Membuat File `.gdextension`|`generate_gdextension()` - menghasilkan file `.gdextension` yang memberi tahu Godot tentang library yang dihasilkan.]]
2. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()` - inti build engine SCons yang:]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Auto-Creation Folder|Auto-membuat folder yang diperlukan.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Pencarian File Sumber|Mencari semua file sumber C++.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Environment dan VariantDir|Mengonfigurasi environment build untuk setiap platform dan arsitektur.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Eksekusi SharedLibrary|Menjalankan kompilasi dengan `env.SharedLibrary()`.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Post-Action untuk Build Sukses|Mencatat hasil build sukses melalui post-action.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Exception Handling untuk Error Konfigurasi|Menangani error konfigurasi dengan exception handling.]]
3. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#4. Eksekusi Akhir - Memanggil Build dan Generate GDExtension|Eksekusi akhir - pemanggilan `build_with_logging()` dan `generate_gdextension()`.]]

Semua kode dalam bab ini adalah bagian dari konstanta `LOGIC_CONTENT` yang didefinisikan di **Baris 163 - 500** dari `bootstrap_scons_gui.py`.

> [!quote] **Referensi Silang:**
> - `build_with_logging()` membaca `build_options.json` yang disimpan di Bab 8.
> - `build_with_logging()` menggunakan `write_logs()` dari Bab 14 untuk mencatat hasil build.
> - `build_with_logging()` menggunakan `godot_cpp_path` yang ditentukan di Bab 13.
> - `generate_gdextension()` menghasilkan file yang akan dibaca oleh Godot Editor.

---

## 2. Fungsi `generate_gdextension()` - Membuat File `.gdextension`

*(Lokasi Baris 367 - 374)*
```python
def generate_gdextension():
    content = ["[configuration]\nentry_symbol = \"test_lib_library_init\"\ncompatibility_minimum = \"4.1\"\n\n[libraries]"]
    for plat, bits in targets:
        ext = ".so" if plat == "linux" else ".dll"
        content.append(f"{plat}.{bits} = \"res://bin/{plat}_{bits}_{BUILD_MODE}/libtest_lib.{plat}.{bits}{ext}\"")
    
    with open(GEXT_FILE, "w") as f:
        f.write("\n".join(content))
    sys.stdout.log_only("GDExtension config generated!")
```

### Tujuan
Fungsi `generate_gdextension()` menghasilkan file **`compile.gdextension`** di folder `bin/`. File ini adalah **konfigurasi GDExtension** yang dibaca oleh Godot untuk mengetahui:
- Simbol entry point dari library (`entry_symbol`).
- Versi kompatibilitas minimum Godot (`compatibility_minimum`).
- Path ke library untuk setiap platform dan arsitektur.

### Struktur File `.gdextension`
File `.gdextension` menggunakan format **INI** dengan dua bagian utama:

#### Bagian `[configuration]`

```ini
[configuration]
entry_symbol = "test_lib_library_init"
compatibility_minimum = "4.1"
```

- **`entry_symbol`** - nama fungsi yang akan dipanggil oleh Godot saat library dimuat. Nama ini harus **sama persis** dengan yang didefinisikan di kode C++ menggunakan `GDEXTENSION_INIT()`.
- **`compatibility_minimum`** - versi Godot minimum yang dibutuhkan. Nilai `"4.1"` berarti library ini kompatibel dengan Godot 4.1 ke atas.

#### Bagian `[libraries]`

```ini
[libraries]
linux.64 = "res://bin/linux_64_release/libtest_lib.linux.64.so"
windows.64 = "res://bin/windows_64_release/libtest_lib.windows.64.dll"
```

- Setiap baris memetakan `{platform}.{bits}` ke path library (menggunakan `res://`).
- Path mengikuti struktur folder: `bin/{plat}_{bits}_{BUILD_MODE}/libtest_lib.{plat}.{bits}{ext}`.
- Ekstensi: `.so` untuk Linux, `.dll` untuk Windows.

### Alur Eksekusi
1. **Inisialisasi konten** - `content` dimulai dengan bagian `[configuration]`.
2. **Loop target** - untuk setiap `(plat, bits)` di `targets`:
    - Tentukan ekstensi: `.so` untuk Linux, `.dll` untuk Windows.
    - Tambahkan baris ke `[libraries]`.
3. **Tulis file** - `"\n".join(content)` menggabungkan semua baris dengan newline.
4. **Log** - `sys.stdout.log_only()` mencatat bahwa file telah digenerate (hanya ke log, tidak ke terminal).

### Catatan Penting tentang Nama Library
Perhatikan bahwa nama library adalah **`libtest_lib`** - ini adalah nama default dari template proyek KOBI. Jika pengguna mengganti nama library di kode C++ (dengan `GDEXTENSION_INIT(nama_baru)`), mereka juga harus mengubah nama library di `build_logic.py` (atau mengubah `LOGIC_CONTENT` di bootstrapper).

---

## 3. Fungsi `build_with_logging()` - Inti Build Engine

*(Lokasi Baris 378 - 494)*
```python
def build_with_logging():
    print(f">>> Starting build process... (mode={BUILD_MODE}, platforms={[p for p, _ in targets]})")
    
    # Auto Make Folder
    for folder in ["bin", "src", "build", "logs"]:
        if not os.path.exists(folder):
            print(f"{C.GIW}>>> Folder '{folder}' Not Found. Make New Folder... {C.N}")
            os.makedirs(folder)
            
    src_files_found = glob.glob("src/**/*.cpp", recursive=True)
    
    all_libs = []
    
    for plat, bits in targets:
        env = Environment()
        
        env['PRINT_CMD_LINE_FUNC'] = lambda s, target, src, env: None
        
        build_path = f"build/{plat}_{bits}"
        VariantDir(build_path, "src", duplicate=0)
        CURRENT_SOURCES = []
        for src_file in src_files_found:
            rel_path = os.path.relpath(src_file, "src")
            target_src = os.path.join(build_path, rel_path)
            
            target_dir = os.path.dirname(target_src)
            if not os.path.exists(target_dir):
                os.makedirs(target_dir, exist_ok=True)
                
            CURRENT_SOURCES.append(File(target_src))
        
        if not CURRENT_SOURCES:
            print(f"{C.RYW} No Files in {build_path}{C.N}")
            continue
        
        # PATH & LIBRARY
        env.Append(CPPPATH=[
            "src/",
            os.path.join(godot_cpp_path, "include"),
            os.path.join(godot_cpp_path, "gen/include"),
        ])
        
        arch = "x86_64" if bits == "64" else "x86_32"
        scons_target = "template_debug" if BUILD_MODE == "debug" else "template_release"
        # Platform
        if plat == "windows":
            env["CXX"] = "x86_64-w64-mingw32-g++" if bits == "64" else "i686-w64-mingw32-g++"
            target_ext = ".dll"
        else:
            env.Append(CPPFLAGS=["-fPIC"])
            env.Append(CCFLAGS=["-m64" if bits == "64" else "-m32"])
            env.Append(LINKFLAGS=["-m64" if bits == "64" else "-m32"])
            target_ext = ".so"
        lib_name = f"godot-cpp.{plat}.{scons_target}.{arch}"
        # Mode (debug/release)
        if BUILD_MODE == "debug":
            env.Append(CCFLAGS=["-g", "-O0"])
            env.Append(CPPDEFINES=["DEBUG_ENABLED"])
        else:
            env.Append(CCFLAGS=["-O3"])
            env.Append(CPPDEFINES=["NDEBUG"])
            
        # Library & Flags
        env.Append(LIBPATH=[os.path.join(godot_cpp_path, "bin")])
        env.Append(LIBS=[lib_name])
        env.Append(CPPFLAGS=["-fPIC", "-std=c++17"])
                
        # Dynamic Target Name
        bin_subdir = f"bin/{plat}_{bits}_{BUILD_MODE}"
        if not os.path.exists(bin_subdir):
            os.makedirs(bin_subdir, exist_ok=True)
        current_target = f"{bin_subdir}/compile.{plat}.{bits}{target_ext}"
        
        print(f"{C.CIW}--- Registering {plat} {bits}-bit --- Output: {build_path}{C.N}")
        
        try:
            print(f"--- Building {plat} {bits}-bit --- {build_path}")
            result = env.SharedLibrary(target=current_target, source=CURRENT_SOURCES)
            def aksi_setelah_berhasil(target, source, env, p=plat, b=bits):
                durasi = time.time() - Start
                m, s = divmod(int(durasi), 60)
                d_teks = f"{m}m {s}s" if m > 0 else f"{s}s"
                print(f"{C.GIW}>>> Build {p} {b} SUCCESS in {d_teks}{C.N}")
                write_logs(p, b, "SUCCESS", f"{target[0].name} ({d_teks})")
                return None
            env.AddPostAction(result, aksi_setelah_berhasil)
            all_libs.append(result)
        except Exception as e:
            print(f"{C.RIW}>>> Failed to register target {plat} {bits}-bit: {e}{C.N}")
            write_logs(plat, bits, "FAILED", f"Config error: {str(e)}", full_error=str(e))
    return all_libs
```

### Tujuan

`build_with_logging()` adalah **inti dari seluruh sistem build**. Fungsi ini:
1. Membuat folder yang diperlukan.
2. Mencari semua file sumber C++ di `src/`.
3. Untuk setiap platform dan arsitektur yang aktif:
    - Mengonfigurasi environment build SCons.
    - Menentukan compiler, flags, dan library.
    - Menjalankan kompilasi dengan `env.SharedLibrary()`.
    - Menambahkan post-action untuk mencatat build sukses.
    - Menangani error konfigurasi.

### Auto-Creation Folder

*(Lokasi Baris 382 - 385)*
```python
for folder in ["bin", "src", "build", "logs"]:
    if not os.path.exists(folder):
        print(f"{C.GIW}>>> Folder '{folder}' Not Found. Make New Folder... {C.N}")
        os.makedirs(folder)
```

Fungsi memastikan folder-folder berikut ada:
- **`bin/`** - tempat output akhir (library `.so`/`.dll` dan `.gdextension`).
- **`src/`** - tempat file sumber C++ (jika belum ada, dibuat agar pengguna tidak perlu membuat manual).
- **`build/`** - tempat objek file `.o` selama kompilasi (dipisah per platform).
- **`logs/`** - tempat file log (sudah dibuat oleh `Terminal` class, tapi dicek lagi untuk amannya).

### Pencarian File Sumber

*(Lokasi Baris 388)*
```python
src_files_found = glob.glob("src/**/*.cpp", recursive=True)
```

Mencari **semua file `.cpp`** di `src/` dan subfoldernya secara rekursif. Hasilnya disimpan di `src_files_found`.

### Loop Per Platform

*(Lokasi Baris 396 - 494)*

Untuk setiap `(plat, bits)` di `targets`, fungsi melakukan konfigurasi dan build.

#### Environment dan VariantDir

*(Lokasi Baris 396 - 401)*
```python
env = Environment()
env['PRINT_CMD_LINE_FUNC'] = lambda s, target, src, env: None
build_path = f"build/{plat}_{bits}"
VariantDir(build_path, "src", duplicate=0)
```

- **`Environment()`** - membuat environment SCons baru.
- **`PRINT_CMD_LINE_FUNC = lambda ...: None`** - **meredam output command** yang biasanya panjang dan mengganggu. Tanpa ini, SCons akan mencetak setiap command compile ke terminal, membuat layar penuh dengan teks yang tidak perlu.
- **`VariantDir(build_path, "src", duplicate=0)`** - mengarahkan file objek ke `build/{plat}_{bits}/` tanpa menduplikasi file sumber. Ini menjaga `src/` tetap bersih.

#### Mapping Sumber ke Build Path

*(Lokasi Baris 402 - 411)*
```python
CURRENT_SOURCES = []
for src_file in src_files_found:
    rel_path = os.path.relpath(src_file, "src")
    target_src = os.path.join(build_path, rel_path)
    
    target_dir = os.path.dirname(target_src)
    if not os.path.exists(target_dir):
        os.makedirs(target_dir, exist_ok=True)
        
    CURRENT_SOURCES.append(File(target_src))
```

Untuk setiap file sumber:
1. Hitung path relatif dari `src/` (misal `main.cpp` → `main.cpp`, `subfolder/helper.cpp` → `subfolder/helper.cpp`).
2. Gabungkan dengan `build_path` → `build/linux_64/main.cpp`.
3. Buat folder target jika belum ada.
4. Tambahkan ke `CURRENT_SOURCES` sebagai objek `File` SCons.

#### Cek Apakah Ada Sumber

*(Lokasi Baris 413 - 415)*
```python
if not CURRENT_SOURCES:
    print(f"{C.RYW} No Files in {build_path}{C.N}")
    continue
```

Jika tidak ada file sumber, lewati platform ini.

#### Path Include (CPPPATH)

*(Lokasi Baris 421 - 425)*
```python
env.Append(CPPPATH=[
    "src/",
    os.path.join(godot_cpp_path, "include"),
    os.path.join(godot_cpp_path, "gen/include"),
])
```

Path include:
- **`"src/"`** - untuk header yang didefinisikan di proyek.
- **`godot_cpp_path/include/`** - header utama godot-cpp.
- **`godot_cpp_path/gen/include/`** - header generated (binding) dari godot-cpp.

> [!warning] **Catatan Penting:**
> Struktur `include/` dan `gen/include/` adalah struktur **godot-cpp versi 4.x**. Versi Godot 3.x menggunakan struktur yang berbeda (`include/core`, `include/gen`, `godot-headers`). Karena sistem build KOBI menggunakan Godot 4, struktur ini sudah benar.

#### Arsitektur dan SCons Target

*(Lokasi Baris 431 - 432)*
```python
arch = "x86_64" if bits == "64" else "x86_32"
scons_target = "template_debug" if BUILD_MODE == "debug" else "template_release"
```

- **`arch`** - `"x86_64"` untuk 64-bit, `"x86_32"` untuk 32-bit.
- **`scons_target`** - `"template_debug"` untuk debug, `"template_release"` untuk release.

Nilai `arch` dan `scons_target` digunakan untuk:
1. Menentukan nama library godot-cpp yang akan di-link.
2. Menentukan flag compiler yang sesuai.

#### Konfigurasi Compiler

**Untuk Windows (cross-compilation):**
*(Lokasi Baris 435 - 437)*
```python
if plat == "windows":
    env["CXX"] = "x86_64-w64-mingw32-g++" if bits == "64" else "i686-w64-mingw32-g++"
    target_ext = ".dll"
```

- **64-bit** - gunakan `x86_64-w64-mingw32-g++`.
- **32-bit** - gunakan `i686-w64-mingw32-g++`.

**Untuk Linux:**
*(Lokasi Baris 438 - 442)*
```python
else:
    env.Append(CPPFLAGS=["-fPIC"])
    env.Append(CCFLAGS=["-m64" if bits == "64" else "-m32"])
    env.Append(LINKFLAGS=["-m64" if bits == "64" else "-m32"])
    target_ext = ".so"
```

- **`-fPIC`** - Position Independent Code, diperlukan untuk shared library.
- **`-m64` / `-m32`** - menentukan arsitektur output.
- **`.so`** - ekstensi shared library untuk Linux.

#### Nama Library godot-cpp

*(Lokasi Baris 444)*
```python
lib_name = f"godot-cpp.{plat}.{scons_target}.{arch}"
```

Contoh nama library:
- `godot-cpp.linux.template_release.x86_64`
- `godot-cpp.windows.template_debug.x86_32`

#### Mode Debug/Release

*(Lokasi Baris 447 - 452)*
```python
if BUILD_MODE == "debug":
    env.Append(CCFLAGS=["-g", "-O0"])
    env.Append(CPPDEFINES=["DEBUG_ENABLED"])
else:
    env.Append(CCFLAGS=["-O3"])
    env.Append(CPPDEFINES=["NDEBUG"])
```

- **Debug** - `-g` (debug symbols), `-O0` (no optimization), `DEBUG_ENABLED` (macro).
- **Release** - `-O3` (max optimization), `NDEBUG` (macro untuk menghilangkan assert).

#### Library Path dan Flags

*(Lokasi Baris 455 - 457)*
```python
env.Append(LIBPATH=[os.path.join(godot_cpp_path, "bin")])
env.Append(LIBS=[lib_name])
env.Append(CPPFLAGS=["-fPIC", "-std=c++17"])
```

- **`LIBPATH`** - path ke folder `bin/` godot-cpp tempat library `.a` berada.
- **`LIBS`** - nama library yang akan di-link (tanpa prefix `lib` dan ekstensi).
- **`CPPFLAGS`** - `-fPIC` (Position Independent Code), `-std=c++17` (standar C++).

#### Nama Target Output

*(Lokasi Baris 460 - 463)*
```python
bin_subdir = f"bin/{plat}_{bits}_{BUILD_MODE}"
if not os.path.exists(bin_subdir):
    os.makedirs(bin_subdir, exist_ok=True)
current_target = f"{bin_subdir}/compile.{plat}.{bits}{target_ext}"
```

Contoh target output:
- `bin/linux_64_release/compile.linux.64.so`
- `bin/windows_32_debug/compile.windows.32.dll`

Folder output **dipisah per platform, arsitektur, dan mode** agar build yang berbeda tidak saling menimpa.

#### Eksekusi SharedLibrary

*(Lokasi Baris 465 - 469)*
```python
print(f"{C.CIW}--- Registering {plat} {bits}-bit --- Output: {build_path}{C.N}")
try:
    print(f"--- Building {plat} {bits}-bit --- {build_path}")
    result = env.SharedLibrary(target=current_target, source=CURRENT_SOURCES)
```

- **`env.SharedLibrary()`** - fungsi SCons untuk membuat shared library (`.so`/`.dll`).
- **`result`** - objek target SCons yang akan digunakan untuk post-action.

#### Post-Action untuk Build Sukses

*(Lokasi Baris 471 - 483)*
```python
def aksi_setelah_berhasil(target, source, env, p=plat, b=bits):
    durasi = time.time() - Start
    m, s = divmod(int(durasi), 60)
    d_teks = f"{m}m {s}s" if m > 0 else f"{s}s"
    print(f"{C.GIW}>>> Build {p} {b} SUCCESS in {d_teks}{C.N}")
    write_logs(p, b, "SUCCESS", f"{target[0].name} ({d_teks})")
    return None
env.AddPostAction(result, aksi_setelah_berhasil)
```

- **`AddPostAction()`** - menambahkan aksi yang akan dijalankan **setelah** target berhasil dibangun.
- **`aksi_setelah_berhasil`** - menghitung durasi build, menampilkan pesan sukses, dan memanggil `write_logs()`.
- Ini adalah cara yang benar untuk mencatat build sukses karena hanya dipanggil jika compile benar-benar berhasil.

#### Exception Handling untuk Error Konfigurasi

*(Lokasi Baris 486 - 490)*
```python
except Exception as e:
    print(f"{C.RIW}>>> Failed to register target {plat} {bits}-bit: {e}{C.N}")
    write_logs(plat, bits, "FAILED", f"Config error: {str(e)}", full_error=str(e))
```

- **`except Exception`** - menangkap error **konfigurasi** (misal argumen `SharedLibrary()` salah).
- **BUKAN** error compile - error compile ditangani oleh [[BAB 14 - ISI `build_logic.py` (BAGIAN 2 – FUNGSI LOGGING DAN REPORT)#5. Fungsi `report_build_failures()` - Menangkap Error Compile|`report_build_failures()` di Bab 14.]]

### Return Value

*(Lokasi Baris 494)*
```python
return all_libs
```

`all_libs` adalah list dari objek target SCons yang berhasil didaftarkan. Ini digunakan di akhir file untuk menentukan target default SCons.

---

## 4. Eksekusi Akhir - Memanggil Build dan Generate GDExtension

*(Lokasi Baris 496–499)*
```python
libs = build_with_logging()
if libs:
    Default(libs)
    generate_gdextension()
```

### Tujuan
Setelah `build_with_logging()` selesai, kode di luar fungsi menentukan:
1. **Jika ada library yang berhasil didaftarkan** (`libs` tidak kosong):
    - Panggil `Default(libs)` - memberitahu SCons target mana yang akan dibangun secara default (ketika pengguna menjalankan `scons` tanpa argumen).
    - Panggil `generate_gdextension()` - membuat file `.gdextension`.
2. **Jika tidak ada library** - tidak melakukan apa-apa (tidak ada yang perlu dibangun).

### Mengapa `generate_gdextension()` Dipanggil di Sini?
`generate_gdextension()` harus dipanggil **setelah** `Default(libs)` karena:
- `generate_gdextension()` membaca `targets` untuk mengetahui platform dan arsitektur apa yang akan dibangun.
- `targets` sudah ditentukan di awal [[BAB 13 - ISI `build_logic.py` (BAGIAN 1 - PROLOG, KELAS, KONFIGURASI)|`build_logic.py`]] berdasarkan `build_options.json`.

### Alur Eksekusi Lengkap

> [!info]- Alur Eksekusi Lengkap
> ```text
> 1. build_logic.py di-load oleh SCons
> 	|
> 2. Prolog dan konfigurasi awal (Bab 13)
> 	|
> 3. Fungsi logging didefinisikan (Bab 14)
> 	|
> 4. build_with_logging() dipanggil
> 	|
> 5. Auto-create folder
> 	|
> 6. Untuk setiap platform:
>    a. Konfigurasi environment
>    b. Mapping sumber
>    c. Konfigurasi compiler, flags, library
>    d. env.SharedLibrary() (mendaftarkan target)
>    e. AddPostAction() (untuk log sukses)
> 	|
> 7. Selesai register semua target
> 	|
> 8. libs = build_with_logging()
> 	|
> 9. Jika libs tidak kosong:
>    - Default(libs) → SCons tahu target mana yang harus dibangun
>    - generate_gdextension() → buat compile.gdextension
>    ↓
> 10. SConstruct selesai diparse
> 	|
> 11. SCons mulai mengeksekusi build
> 	|
> 12. Jika sukses → post-action memanggil write_logs()
> 	|
> 13. Jika gagal → atexit memanggil report_build_failures()
> 	|
> 14. Selesai
> ```

---

## 5. Tabel Rangkuman Konfigurasi per Platform

|Aspek|Linux 64-bit|Linux 32-bit|Windows 64-bit|Windows 32-bit|
|---|---|---|---|---|
|**Compiler**|`g++` (default)|`g++` (default)|`x86_64-w64-mingw32-g++`|`i686-w64-mingw32-g++`|
|**Arch (SCons)**|`x86_64`|`x86_32`|`x86_64`|`x86_32`|
|**CCFLAGS**|`-m64`|`-m32`|(default)|(default)|
|**LINKFLAGS**|`-m64`|`-m32`|(default)|(default)|
|**CPPFLAGS**|`-fPIC -std=c++17`|`-fPIC -std=c++17`|`-fPIC -std=c++17`|`-fPIC -std=c++17`|
|**Target ext**|`.so`|`.so`|`.dll`|`.dll`|
|**Output folder**|`bin/linux_64_{mode}/`|`bin/linux_32_{mode}/`|`bin/windows_64_{mode}/`|`bin/windows_32_{mode}/`|
|**Library name**|`godot-cpp.linux.{target}.x86_64`|`godot-cpp.linux.{target}.x86_32`|`godot-cpp.windows.{target}.x86_64`|`godot-cpp.windows.{target}.x86_32`|

---

## 6. Keterkaitan dengan Fitur Baru v2.4.0

> [!done]- Opsi bits dalam Build Engine
> ### Opsi `bits` dalam Build Engine
> Fitur `bits` (64/32-bit) memengaruhi **seluruh** konfigurasi build di `build_with_logging()`:
> 
> |Aspek|Dampak `bits`|
> |---|---|
> |**Nama folder output**|`bin/{plat}_{bits}_{mode}/`|
> |**Arch (SCons)**|`"x86_64"` atau `"x86_32"`|
> |**Compiler Windows**|`x86_64-w64-mingw32-g++` atau `i686-w64-mingw32-g++`|
> |**CCFLAGS/LINKFLAGS Linux**|`-m64` atau `-m32`|
> |**Nama library godot-cpp**|`godot-cpp.{plat}.{target}.x86_64` atau `...x86_32`|
> |**Target output**|`compile.{plat}.64.so` atau `compile.{plat}.32.so`|
> 

^22efc8

> [!done]- Post-Action dengan bits
> ### Post-Action dengan `bits`
> Post-action `aksi_setelah_berhasil` menerima `p=plat, b=bits` sebagai argumen, sehingga log mencatat arsitektur yang tepat.

> [!done]- 'generate_gdextension()' dengan bits
> ### `generate_gdextension()` dengan `bits`
> File `.gdextension` memiliki baris untuk setiap `(plat, bits)`:
> 
> ```text
> linux.64 = "res://bin/linux_64_release/libtest_lib.linux.64.so"
> windows.32 = "res://bin/windows_32_release/libtest_lib.windows.32.dll"
> ```
> 

---

## 7. Contoh Output Build yang Berhasil

Berikut adalah contoh output terminal saat build berhasil:

```text
>>> Starting build process... (mode=release, platforms=['linux', 'windows'])
>>> Folder 'bin' Not Found. Make New Folder... 
>>> Folder 'src' Not Found. Make New Folder... 
--- Registering linux 64-bit --- Output: build/linux_64
--- Building linux 64-bit --- build/linux_64
--- Registering windows 64-bit --- Output: build/windows_64
--- Building windows 64-bit --- build/windows_64
>>> Build linux 64 SUCCESS in 2m 15s
>>> Build windows 64 SUCCESS in 1m 45s
GDExtension config generated!
```

### Log yang Dihasilkan
- **`build_history.json`** - dua entri sukses.
- **`build_report.md`** - dua entri sukses dengan ✅.
- **`terminal_cctv.log`** - semua output terminal.
- **`compile.gdextension`** - file konfigurasi untuk Godot.

### File Output

```text
bin/
├── linux_64_release/
│   └── compile.linux.64.so
├── windows_64_release/
│   └── compile.windows.64.dll
└── compile.gdextension
```

---

## 8. Kesimpulan

Pada bab ini, kita telah membahas **inti dari sistem build** - fungsi `build_with_logging()` dan `generate_gdextension()`. Kita mempelajari:
1. [[#2. Fungsi `generate_gdextension()` - Membuat File `.gdextension`|`generate_gdextension()` - menghasilkan file `.gdextension` yang memberi tahu Godot tentang library yang dihasilkan.]]
2. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#3. Fungsi `build_with_logging()` - Inti Build Engine|`build_with_logging()` - inti build engine SCons yang:]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Auto-Creation Folder|Auto-membuat folder yang diperlukan.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Pencarian File Sumber|Mencari semua file sumber C++.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Environment dan VariantDir|Mengonfigurasi environment build untuk setiap platform dan arsitektur.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Eksekusi SharedLibrary|Menjalankan kompilasi dengan `env.SharedLibrary()`.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Post-Action untuk Build Sukses|Mencatat hasil build sukses melalui post-action.]]
    - [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#Exception Handling untuk Error Konfigurasi|Menangani error konfigurasi dengan exception handling.]]
3. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#4. Eksekusi Akhir - Memanggil Build dan Generate GDExtension|Eksekusi akhir - pemanggilan `build_with_logging()` dan `generate_gdextension()`.]]
4. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#^22efc8|Dampak `bits` - arsitektur 64/32-bit memengaruhi semua aspek build.]]
5. [[BAB 15 - ISI `build_logic.py` (BAGIAN 3 – GENERATE GDEXTENSION DAN INTI BUILD)#alur|Alur lengkap - dari load `build_logic.py` hingga build selesai.]]