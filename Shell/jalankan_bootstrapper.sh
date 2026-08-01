#!/bin/bash
# ============================================================
# SPDX-License-Identifier: GPL-3.0-or-later
# Copyright (C) 2026 Yohanes Alan Jasper / KOBI Studio
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

cd "$(dirname "$0")"

# ============================================================
# BIKIN LAUNCHER .desktop OTOMATIS + SELF-HEAL PERMISSION
# Biar file ini beneran "jadi program" begitu diklik, tanpa perlu
# klik kanan -> Properties -> "Allow run as program" tiap kali
# pindah/salin ke folder proyek baru. Sekali generate, dia bikin
# file .desktop di folder yang sama, langsung di-chmod +x, dan
# ini sendiri juga di-chmod +x ulang tiap kali dijalankan (self-heal
# kalau suatu saat permission-nya kebalik lagi).
# ============================================================
SCRIPT_ABS="$(readlink -f "$0")"
DESKTOP_FILE="$(dirname "$SCRIPT_ABS")/Jalankan KOBI Bootstrapper.desktop"
if [ ! -f "$DESKTOP_FILE" ]; then
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
	chmod +x "$DESKTOP_FILE" 2>/dev/null
fi
chmod +x "$SCRIPT_ABS" 2>/dev/null

# ============================================================
# SELF-RELAUNCH DI LEVEL BASH: kalau script ini diklik langsung
# dari file manager (bukan lewat terminal), belum ada terminal
# buat nanya apa-apa. Jadi dicek dulu di sini -- kalau memang
# gak ada terminal interaktif, buka terminal sendiri dulu,
# baru lanjut ke pertanyaan proyek baru & menu seperti biasa.
# ============================================================
if [ ! -t 0 ]; then
	SCRIPT_PATH="$(readlink -f "$0")"
	for NAMA_TERM in gnome-terminal konsole xfce4-terminal x-terminal-emulator xterm; do
		if command -v "$NAMA_TERM" >/dev/null 2>&1; then
			case "$NAMA_TERM" in
				gnome-terminal) "$NAMA_TERM" -- bash "$SCRIPT_PATH" ;;
				konsole) "$NAMA_TERM" -e bash "$SCRIPT_PATH" ;;
				xfce4-terminal) "$NAMA_TERM" -x bash "$SCRIPT_PATH" ;;
				*) "$NAMA_TERM" -e bash "$SCRIPT_PATH" ;;
			esac
			exit 0
		fi
	done
	exit 1
fi

# ============================================================
# MODE PROYEK BARU: pertanyaan ini sekarang ditanya DI DALAM sesi
# curses yang sama dengan menu utama (bukan proses python terpisah),
# biar gak ada transisi keluar-masuk curses yang bikin kelip-kelip
# pas pertama dibuka. Logic lengkapnya ada di bootstrap_scons_gui.py.
# ============================================================

cat > bootstrap_scons_gui.py << 'PYEOF_INNER'
#!/usr/bin/env python3
"""
bootstrap_scons_gui.py   <-- VERSI CURSES (UI di terminal, TANPA perlu install apapun)
-----------------------
Awalnya pakai tkinter, tapi diganti ke curses karena tkinter butuh install
tambahan (python3-tk) yang butuh sudo. curses itu BAWAAN Python di Linux,
jadi langsung jalan tanpa install apa-apa lagi.
Jalanin: python3 bootstrap_scons_gui.py
Tampilannya kotak UI di terminal (bukan jendela pop-up beneran), ada tombol
yang dipencet pakai ENTER, bukan klik mouse.

>>> Kalau mau versi command-line polos (tanpa UI sama sekali), pakai bootstrap_scons_TERMINAL.py. <<<
"""

import os
import sys
import shutil
import subprocess
import curses
import json
import glob
import datetime
import time

BOOTSTRAPPER_VERSION = "2.4.0"

# Style/warna default (fallback aman kalau terminal gak support warna sama sekali --
# key-key ini SELALU ada, cuma nilainya diganti pakai color_pair() beneran di main()
# kalau curses.has_colors() nyala. Jangan pernah hapus key dari sini, biar kode lain
# yang manggil STYLE["..."] gak pernah KeyError.)
STYLE = {
	"title": curses.A_BOLD | curses.A_UNDERLINE,
	"section": curses.A_BOLD,
	"selected": curses.A_REVERSE,
	"active": curses.A_BOLD,
	"inactive": curses.A_DIM,
	"accent": curses.A_BOLD,
	"dim": curses.A_DIM,
	"normal": curses.A_NORMAL,
}

# ============================================================
# SELF-RELAUNCH: kalau script ini dijalanin TANPA terminal
# (misal diklik dari file manager), dia bakal buka terminal
# sendiri buat nampilin UI curses-nya, tanpa perlu file .desktop
# terpisah atau ngetik command manual.
# ============================================================
if not sys.stdin.isatty():
	path_file = os.path.abspath(__file__)
	# Perintah ini dibungkus biar terminal TIDAK langsung tertutup setelah
	# script selesai/crash -- jadi kalau ada error, kamu sempat baca pesannya
	# sebelum jendela hilang.
	perintah_dalam = (
		f'python3 "{path_file}"; echo; read -p "Press ENTER to close this window..."'
	)
	
	kandidat_terminal = [
		("gnome-terminal", ["gnome-terminal", "--", "bash", "-c", perintah_dalam]),
		("konsole", ["konsole", "-e", "bash", "-c", perintah_dalam]),
		("xfce4-terminal", ["xfce4-terminal", "-e", f"bash -c '{perintah_dalam}'"]),
		("x-terminal-emulator", ["x-terminal-emulator", "-e", f"bash -c '{perintah_dalam}'"]),
		("xterm", ["xterm", "-e", f"bash -c '{perintah_dalam}'"]),
	]
	
	for nama, cmd in kandidat_terminal:
		if shutil.which(nama):
			subprocess.Popen(cmd)
			sys.exit(0)
	# Kalau gak nemu terminal apapun, ya udah nyerah, kasih tau lewat cara lain
	sys.exit(
		"No known terminal emulator found. "
		f"Jalanin manual lewat terminal: python3 {path_file}"
	)

STUB_CONTENT = '''# ============================================================
#  Jangan edit logic di sini!
#  File ini cuma STUB biar `scons` (tanpa flag apapun) tetep
#  nemuin file build. Semua kode ada di build_logic.py --
#  edit di situ, dapet syntax highlighting Python penuh di editor.
# ============================================================
exec(open("build_logic.py").read())
'''

LOGIC_CONTENT = r'''import time
import datetime
import os
import subprocess
import json
import sys
import glob
import atexit
from SCons.Script import GetBuildFailures

Start = time.time()


class Terminal(object):
	def __init__(self):
		self.terminal = sys.stdout
		os.makedirs("logs", exist_ok=True)
		self.log = open("logs/terminal_cctv.log", "a", encoding="utf-8")

	def write(self, message):
		self.terminal.write(message)
		self.log.write(message)
		
	def log_only(self, message):
		timestamp = datetime.datetime.now().strftime("[%H:%M:%S] ")
		self.log.write(f"{timestamp}{message}\n")

	def flush(self):
		if hasattr(self.terminal, "flush"):
			self.terminal.flush()
		self.log.flush()

sys.stdout = Terminal()
sys.stderr = sys.stdout

class ColorMagic:
	def __init__(self):
		self.codes = {
			#Colors
			'Y': "\033[93m",	# Yellow
			'G': "\033[92m",	# Green
			'R': "\033[91m",	# Red
			'N': "\033[0m", 	# Reset
			'B': "\033[94m",	# Blue
			'C': "\033[96m",	# Cyan

			#STYLE
			'W': "\033[1m",	# Bold
			'I': "\033[3m",	# Italic
			'U': "\033[4m",	# Underline
			'S': "\033[9m",	# Strikethrough
		}

	def __getattr__(self, name):
		# Fungsi ini otomatis jalan saat kamu panggil C.WIY
		# Dia akan mengambil huruf W, I, dan Y satu per satu
		return "".join([self.codes.get(char, "") for char in name])

# Inisialisasi objeknya
C = ColorMagic()


#CONFIGURATION
LOG_FILE = "logs/build_report.md"
JSON_LOG = "logs/build_history.json"
ERROR_LOG_FILE = "logs/build_errors.log"		# Detail lengkap khusus error (command, errstr, dll)
JSON_ARCHIVE = "logs/build_history_archive.json"
MAX_HISTORY = 50							# Entri terakhir yang disimpan di build_report.md & build_history.json
BASE_TARGET_NAME = "bin/compile"
SOURCE_FILES = [File(f) for f in glob.glob("src/**/*.cpp", recursive=True)]
GEXT_FILE = "bin/compile.gdextension"

#BUILD OPTIONS (diisi lewat menu curses -> build_options.json)
OPTIONS_FILE = "build_options.json"
build_options = {"mode": "release", "platforms": ["linux", "windows"], "jobs": 0, "godot_cpp_branch": "4.2", "godot_cpp_api_version": "4.7", "bits": "64"}
if os.path.exists(OPTIONS_FILE):
	try:
		with open(OPTIONS_FILE, "r") as f:
			build_options.update(json.load(f))
	except: pass

# godot_cpp_path IKUT versi yang dipilih di menu (godot-cpp-<branch>), BUKAN folder
# "godot-cpp" polos -- biar gak ketuker/gak nyari folder yang gak pernah ada.
GODOT_CPP_BRANCH = build_options.get("godot_cpp_branch", "4.2")
GODOT_CPP_API_VERSION = build_options.get("godot_cpp_api_version", "4.7")
# Mulai godot-cpp 10.x, branch per-versi Godot (4.6, 4.7, dst) sudah gak ada lagi --
# semua versi baru dibangun dari branch "master" + parameter api_version. Folder dipisah
# "godot-cpp-master-api<versi>" biar ganti target Godot gak nimpa hasil compile lama.
if GODOT_CPP_BRANCH == "master":
	godot_cpp_path = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
	godot_cpp_path = f"godot-cpp-{GODOT_CPP_BRANCH}"
if not os.path.isdir(godot_cpp_path):
	print(f"{C.RIW}>>> WARNING: folder '{godot_cpp_path}' doesn't exist / hasn't been set up yet!{C.N}")
	print(f"{C.RIW}>>> Run [ Setup godot-cpp ] in the menu first for version {GODOT_CPP_BRANCH}.{C.N}")

BUILD_MODE = build_options.get("mode", "release")
if build_options.get("jobs", 0) and build_options["jobs"] > 0:
	SetOption("num_jobs", build_options["jobs"])

targets = [(p, build_options.get("bits", "64")) for p in build_options.get("platforms", ["linux", "windows"])]


#LOGGING
def _archive_old_json(old_entries):
	"""Simpan entri lama ke file arsip JSON sebelum di-trim dari history utama."""
	archive = []
	if os.path.exists(JSON_ARCHIVE):
		try:
			with open(JSON_ARCHIVE, "r") as f: archive = json.load(f)
		except: pass
	archive.extend(old_entries)
	with open(JSON_ARCHIVE, "w") as f: json.dump(archive, f, indent=4)


def _archive_old_md():
	"""Kalau build_report.md sudah kepanjangan (>= MAX_HISTORY entri), pindahkan ke file arsip
	bertimestamp dan mulai file baru yang bersih."""
	if not os.path.exists(LOG_FILE):
		return
	with open(LOG_FILE, "r") as f:
		content = f.read()
	jumlah_entri = content.count("### ")
	if jumlah_entri >= MAX_HISTORY:
		stamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
		arsip_name = f"logs/build_report_archive_{stamp}.md"
		os.rename(LOG_FILE, arsip_name)
		sys.stdout.log_only(f"build_report.md di-rotate ke {arsip_name}")


def write_logs(plat, bits, status, details="", full_error=""):
	timestamp = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
	durasi = f"{int(time.time() - Start)}s"

	#Update JSON (dengan rotasi + arsip) -- entri BARU selalu disisipkan di paling depan (index 0)
	history = []
	if os.path.exists(JSON_LOG):
		try:
			with open(JSON_LOG, "r") as f: history = json.load(f)
		except: pass
	history.insert(0, {"time": timestamp, "plat": plat, "arch": bits, "status": status, "msg": details, "dur": durasi})

	# Karena urutan sekarang newest-first, entri PALING LAMA ada di ujung belakang list
	if len(history) > MAX_HISTORY:
		lama = history[MAX_HISTORY:]
		_archive_old_json(lama)
		history = history[:MAX_HISTORY]

	with open(JSON_LOG, "w") as f: json.dump(history, f, indent=4)

	#Update MD (entri baru disisipkan tepat di bawah judul, di ATAS entri-entri lama)
	_archive_old_md()
	entry_md = f"### {'✅' if status == 'SUCCESS' else '❌'} [{timestamp}] Build {status}\n- **Platform**: `{plat} {bits}`\n- **Durasi**: `{durasi}`\n- **File**: `{details}`\n\n---\n"
	if os.path.exists(LOG_FILE):
		with open(LOG_FILE, "r") as f:
			isi_lama = f.read()
		header = "# 🛠️ Build History Log\n\n"
		sisa = isi_lama[len(header):] if isi_lama.startswith(header) else isi_lama
		with open(LOG_FILE, "w") as f:
			f.write(header + entry_md + sisa)
	else:
		with open(LOG_FILE, "w") as f:
			f.write("# 🛠️ Build History Log\n\n" + entry_md)

	#Kalau gagal & ada detail lengkap, catat di file error terpisah (tidak dirotate, arsip permanen)
	#error TERBARU juga ditaruh di paling atas
	if status == "FAILED" and full_error:
		entry_err = f"\n===== [{timestamp}] {plat} {bits}-bit =====\n{full_error}\n"
		isi_lama_err = ""
		if os.path.exists(ERROR_LOG_FILE):
			with open(ERROR_LOG_FILE, "r", encoding="utf-8") as f:
				isi_lama_err = f.read()
		with open(ERROR_LOG_FILE, "w", encoding="utf-8") as f:
			f.write(entry_err + isi_lama_err)


def report_build_failures():
	"""Dipanggil otomatis setelah proses build SCons selesai (via atexit).
	Ini satu-satunya cara yang benar untuk menangkap kegagalan compile,
	karena env.SharedLibrary() cuma MENDAFTARKAN target -- compile beneran
	baru jalan setelah SConstruct ini selesai diparse, jauh setelah try/except manapun."""
	failures = GetBuildFailures()
	if not failures:
		return

	for bf in failures:
		node_name = str(bf.node)
		errstr = bf.errstr or "Unknown error"

		#Coba tebak platform & bit dari nama file target
		plat_guess, bits_guess = "unknown", "?"
		for p, b in targets:
			if f".{p}.{b}" in node_name:
				plat_guess, bits_guess = p, b
				break

		ringkas = f"{node_name}: {errstr}"
		detail = f"Target : {node_name}\nError  : {errstr}\nCommand: {getattr(bf, 'command', 'N/A')}"

		print(f"{C.RIW}>>> Build {plat_guess} {bits_guess} FAILED -- {errstr}{C.N}")
		write_logs(plat_guess, bits_guess, "FAILED", ringkas, full_error=detail)

atexit.register(report_build_failures)

def generate_gdextension():
	content = ["[configuration]\nentry_symbol = \"test_lib_library_init\"\ncompatibility_minimum = \"4.1\"\n\n[libraries]"]
	for plat, bits in targets:
		ext = ".so" if plat == "linux" else ".dll"
		content.append(f"{plat}.{bits} = \"res://bin/{plat}_{bits}_{BUILD_MODE}/libtest_lib.{plat}.{bits}{ext}\"")
	
	with open(GEXT_FILE, "w") as f: f.write("\n".join(content))
	sys.stdout.log_only("GDExtension config generated!")
	
	
#BUILD ENGINE
def build_with_logging():
	print(f">>> Starting build process... (mode={BUILD_MODE}, platforms={[p for p, _ in targets]})")
	
	#Auto Make Folder
	for folder in ["bin", "src", "build", "logs"]:
		if not os.path.exists(folder):
			print(f"{C.GIW}>>> Folder '{folder}' Not Found. Make New Folder... {C.N}")
			os.makedirs(folder)
			
	#CHECK_SOURCE = Glob("src/*.cpp")
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
		
		#PATH & LIBRARY -- path ini HARUS PERSIS sama kayak yang dipakai godot-cpp
		# sendiri pas compile (include + gen/include). Struktur "include/core",
		# "include/gen", "godot-headers" itu peninggalan Godot 3 lama, gak ada di
		# godot-cpp versi Godot 4 manapun -- kalau dipaksa dipakai, header gak ketemu.
		env.Append(CPPPATH=[
			"src/",
			os.path.join(godot_cpp_path, "include"),
			os.path.join(godot_cpp_path, "gen/include"),
		])
		
		# arch & scons_target HARUS PERSIS sama kayak nama file hasil compile godot-cpp asli
		# (format: libgodot-cpp.<platform>.<template_debug/template_release>.<arch>.a)
		# -- kalau beda dikit aja (misal "debug" vs "template_debug", "64" vs "x86_64"),
		# linker gak bakal nemu filenya sama sekali.
		arch = "x86_64" if bits == "64" else "x86_32"
		scons_target = "template_debug" if BUILD_MODE == "debug" else "template_release"

		#Platform
		if plat == "windows":
			env["CXX"] = "x86_64-w64-mingw32-g++" if bits == "64" else "i686-w64-mingw32-g++"
			target_ext = ".dll"
		else:
			env.Append(CPPFLAGS=["-fPIC"])
			env.Append(CCFLAGS=["-m64" if bits == "64" else "-m32"])
			env.Append(LINKFLAGS=["-m64" if bits == "64" else "-m32"])
			target_ext = ".so"

		lib_name = f"godot-cpp.{plat}.{scons_target}.{arch}"

		#Mode (debug/release), dari build_options.json
		if BUILD_MODE == "debug":
			env.Append(CCFLAGS=["-g", "-O0"])
			env.Append(CPPDEFINES=["DEBUG_ENABLED"])
		else:
			env.Append(CCFLAGS=["-O3"])
			env.Append(CPPDEFINES=["NDEBUG"])
			
		#Library & Flags
		env.Append(LIBPATH=[os.path.join(godot_cpp_path, "bin")])
		env.Append(LIBS=[lib_name])
		env.Append(CPPFLAGS=["-fPIC", "-std=c++17"])
				
		#Dynamic Target Name -- dipisah per platform+mode biar debug/release gak saling timpa
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

				# Cetak ke terminal (Agar masuk rekaman CCTV)
				print(f"{C.GIW}>>> Build {p} {b} SUCCESS in {d_teks}{C.N}")

				# Tulis log JSON & MD dengan info durasi
				write_logs(p, b, "SUCCESS", f"{target[0].name} ({d_teks})")
				return None

			env.AddPostAction(result, aksi_setelah_berhasil)
			all_libs.append(result)

		except Exception as e:
			# Ini hanya menangkap error KONFIGURASI (mis. argumen SharedLibrary salah),
			# BUKAN error compile -- error compile ditangani report_build_failures() di atas.
			print(f"{C.RIW}>>> Failed to register target {plat} {bits}-bit: {e}{C.N}")
			write_logs(plat, bits, "FAILED", f"Config error: {str(e)}", full_error=str(e))


	#Default(all_libs)
	return all_libs
		
libs = build_with_logging()
if libs:
	Default(libs)
	generate_gdextension()
'''


def get_daftar_versi_cache_path():
	return "godot_cpp_versi_cache.json"


def load_daftar_versi():
	"""Baca daftar versi godot-cpp. Kalau sudah pernah di-update dari GitHub (cache ada),
	pakai itu. Kalau belum pernah, pakai daftar dasar bawaan.

	CATATAN (per godot-cpp 10.x): branch per-versi Godot cuma ada sampai 4.5 (dan branch
	3.x lama). Godot 4.6 ke atas TIDAK punya branch sendiri lagi -- harus lewat branch
	"master" + parameter api_version (lihat get_daftar_api_version()). Makanya "master"
	selalu ditambahkan manual di sini, gak ikut hasil git ls-remote (yang cuma nangkep
	branch berformat angka.angka)."""
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


def get_daftar_api_version():
	"""Preset versi Godot yang bisa ditarget lewat godot-cpp branch master + api_version.
	Menurut dokumentasi resmi godot-cpp, api_version minimal yang didukung branch master
	adalah 4.3 (versi di bawah itu pakai branch per-versi lama, bukan master)."""
	return ["4.3", "4.4", "4.5", "4.6", "4.7", "custom..."]


def validasi_format_versi(versi):
	"""Validasi kasar format versi angka.angka (mis. '4.7', '4.7.1'). Dipakai buat
	ngecek input custom (branch maupun api_version) sebelum kepake, biar salah ketik
	ketauan lebih awal daripada nunggu git clone / scons gagal duluan."""
	import re as _re
	return bool(_re.match(r'^\d+(\.\d+)+$', versi.strip()))


def cek_semua_godot_cpp():
	"""Scan folder kerja buat semua folder godot-cpp-* yang pernah di-setup, beserta
	status compile & ukurannya masing-masing. Dipakai buat menu [ Lihat semua versi ]
	dan [ Bersihkan godot-cpp lama ], biar gak perlu toggle satu-satu buat ngecek."""
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


def cek_godot_terinstall():
	"""Coba deteksi versi Godot editor yang terinstall di sistem (best-effort, cuma
	buat SARAN -- gak otomatis ngubah opsi apapun). Return string versi atau None
	kalau gak ketemu."""
	for nama_bin in ("godot4", "godot", "godot.x11.opt.tools.64", "godot-mono"):
		if shutil.which(nama_bin):
			try:
				hasil = subprocess.run([nama_bin, "--version"], capture_output=True, text=True, timeout=10)
				if hasil.returncode == 0 and hasil.stdout.strip():
					return hasil.stdout.strip().splitlines()[0]
			except Exception:
				continue
	return None


def update_daftar_versi_online():
	"""Tarik daftar branch versi (3.x dan 4.x) langsung dari GitHub godot-cpp,
	urut dari paling lama ke paling baru, lalu simpan ke cache lokal.
	Kalau gagal (misal tidak ada internet), return None -- daftar lama TETAP dipakai,
	tidak ditimpa/dirusak."""
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


def get_godot_cpp_status(branch, api_version):
	"""Cek kasar status godot-cpp buat versi yang lagi dipilih -- ditampilin di menu utama
	biar gak perlu masuk submenu 'Setup godot-cpp' cuma buat tau udah compile apa belum."""
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


def get_last_build_info():
	"""Baca entri paling baru dari logs/build_history.json (kalau ada) buat ditampilin
	sebagai ringkasan 'Build terakhir' di menu utama."""
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


def generate_files(stdscr, log_lines):
	sudah_ada = [f for f in ("SConstruct", "build_logic.py") if os.path.exists(f)]
	if sudah_ada:
		log_lines.append(f"WARNING: File already exists: {', '.join(sudah_ada)}. Overwritten.")

	with open("SConstruct", "w", encoding="utf-8") as f:
		f.write(STUB_CONTENT)
	log_lines.append("OK: SConstruct created!")

	with open("build_logic.py", "w", encoding="utf-8") as f:
		f.write(LOGIC_CONTENT)
	log_lines.append("OK: build_logic.py created!")
	log_lines.append("")
	log_lines.append("Done! Just type `scons` in the terminal.")


def load_options():
	import json as _json
	opts = {"mode": "release", "platforms": {"linux": True, "windows": True}, "jobs": 0, "godot_cpp_branch": "4.2", "godot_cpp_api_version": "4.7", "bits": "64"}
	if os.path.exists("build_options.json"):
		try:
			with open("build_options.json", "r") as f:
				saved = _json.load(f)
			if "mode" in saved:
				opts["mode"] = saved["mode"]
			if "platforms" in saved:
				for p in opts["platforms"]:
					opts["platforms"][p] = p in saved["platforms"]
			if "jobs" in saved:
				opts["jobs"] = saved["jobs"]
			if "godot_cpp_branch" in saved:
				opts["godot_cpp_branch"] = saved["godot_cpp_branch"]
			if "godot_cpp_api_version" in saved:
				opts["godot_cpp_api_version"] = saved["godot_cpp_api_version"]
			if "bits" in saved:
				opts["bits"] = saved["bits"]
		except: pass
	return opts


def save_options(opts):
	import json as _json
	data = {
		"mode": opts["mode"],
		"platforms": [p for p, on in opts["platforms"].items() if on],
		"jobs": opts["jobs"],
		"godot_cpp_branch": opts["godot_cpp_branch"],
		"godot_cpp_api_version": opts["godot_cpp_api_version"],
		"bits": opts["bits"],
	}
	# Backup 1 versi terakhir sebelum ditimpa -- kalau salah pencet/ganti opsi terus
	# lupa balikin, masih ada build_options.json.bak buat dicek/pulihkan manual.
	if os.path.exists("build_options.json"):
		try:
			shutil.copy2("build_options.json", "build_options.json.bak")
		except Exception:
			pass
	with open("build_options.json", "w") as f:
		_json.dump(data, f, indent=4)
	return data


# ============================================================
# >>> TARUH TEKS LISENSI GPL-3.0 DI SINI <<<
# Copy-paste ISI LENGKAP dari https://www.gnu.org/licenses/gpl-3.0.txt
# (atau versi resmi lain) di ANTARA tanda ''' di bawah ini, GANTIKAN baris
# placeholder "[[ ... ]]". Baris JUDUL/BAB (semua huruf besar, mis. "PREAMBLE",
# "TERMS AND CONDITIONS", "0. Definitions.") otomatis kebaca judul & rata
# tengah di layar; baris teks biasa otomatis full-width. Gak perlu ubah kode
# apapun setelah ini -- tombol [ View License ] dan [ Export License ] bakal
# otomatis kebaca isi terbaru begitu kamu simpan file ini.
# ============================================================
LICENSE_TEXT = r'''
[[ >>> TEMPEL TEKS LISENSI GPL-3.0 DI SINI, GANTIKAN BARIS INI <<< ]]
[[ Sumber resmi: https://www.gnu.org/licenses/gpl-3.0.txt ]]
'''


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
SELECTABLE = [item[0] for item in MENU if item[1] == "option"]


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

	# Style per-baris: item yang lagi ACTIVE/compiled/sukses dikasih warna hijau,
	# yang inactive/gagal dikasih warna merah/dim, sisanya normal. Item yang lagi
	# di-cursor SELALU pakai STYLE["selected"] (prioritas di atas warna status),
	# biar posisi cursor tetap paling jelas kebaca duluan.
	ROW_STYLE = {
		"mode": STYLE["active"] if opts["mode"] == "release" else STYLE["accent"],
		"linux": STYLE["active"] if opts["platforms"]["linux"] else STYLE["inactive"],
		"windows": STYLE["active"] if opts["platforms"]["windows"] else STYLE["inactive"],
		"api_version": STYLE["normal"] if opts["godot_cpp_branch"] == "master" else STYLE["dim"],
	}

	# Lebar blok menu ditentukan dari baris terpanjang, biar seluruh blok bisa
	# di-center sebagai satu kesatuan (bukan cuma judulnya doang yang center).
	header_texts = [item[2] for item in MENU if item[1] == "header"]
	lebar_konten = max([len(t) for t in LABELS.values()] + [len(t) for t in header_texts]) + 4
	lebar_box = min(lebar_konten + 4, max(20, w - 2))
	kiri_box = max(0, (w - lebar_box) // 2)
	kiri = kiri_box + 2

	box_top = 3
	content_start_y = box_top + 1
	box_bottom = content_start_y + len(MENU)

	# Border box manual (pakai karakter ASCII polos +/-/| biar konsisten di semua
	# terminal, gak semua terminal render ACS box-drawing chars dengan rapi).
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


def curses_input(stdscr, prompt_lines):
	"""Ganti curses.endwin()+input() -- minta teks dari user TANPA keluar dari
	mode curses, biar tampilan tetap konsisten. Enter kosong = batal."""
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


def show_message_dialog_timed(stdscr, title, lines, timeout_detik=10):
	"""Sama kayak show_message_dialog, tapi khusus dipakai di layar yang gampang
	kena 'nyangkut' (misal abis network call): (1) CUMA tombol ENTER yang bikin
	balik ke menu -- tombol lain diabaikan biar gak kepencet gak sengaja balik duluan,
	dan (2) otomatis balik sendiri kalau didiemin 10 detik, dengan hitung mundur
	yang di-refresh utuh tiap detik (bukan nambah baris/scroll, layar di-clear penuh
	tiap update biar gak ada sisa tampilan lama yang bikin 'kena scroll')."""
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


def show_scrollable_dialog(stdscr, title, text_lines):
	"""Layar teks panjang yang bisa di-scroll (UP/DOWN), dipakai buat dokumen
	yang kepanjangan buat 1 layar biasa (mis. teks lisensi GPL). JUDUL rata
	tengah, tapi BODY teks mulai dari margin kiri dan penuh selebar terminal
	(bukan kolom sempit di tengah) -- soalnya dokumen legal biasanya udah
	diformat sendiri per baris (~65-70 karakter), jadi gak perlu di-wrap ulang
	ke kolom sempit. Sama kayak show_message_dialog, resize dan mouse scroll
	gak dianggap 'tombol keluar' -- cuma bikin redraw/scroll."""
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
			# Baris section/judul bab (huruf besar semua, gak diawali spasi) di-tengah-in;
			# baris body biasa full-width dari margin kiri.
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
			# Page Up -- loncat satu layar penuh ke atas, biar dokumen panjang
			# (mis. lisensi GPL ~700 baris) gak perlu digeser satu-satu.
			scroll = max(0, scroll - visible)
		elif key == curses.KEY_NPAGE:
			# Page Down -- loncat satu layar penuh ke bawah.
			scroll = min(max_scroll, scroll + visible)
		elif key == curses.KEY_HOME:
			scroll = 0
		elif key == curses.KEY_END:
			scroll = max_scroll
		elif key in (ord('q'), ord('Q'), 27, curses.KEY_ENTER, 10, 13):
			break


def show_message_dialog(stdscr, title, lines):
	"""Layar pesan sederhana, pengganti print()+input() polos. Tekan tombol
	apapun buat lanjut -- KECUALI resize terminal, yang cuma bikin redraw
	(sebelumnya resize dianggap 'tombol apapun' dan bikin layar auto-nutup)."""
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
			# Scroll wheel/klik mouse -- konsumsi eventnya biar gak numpuk di
			# antrian, terus redraw lagi (JANGAN dianggap 'tombol apapun').
			try:
				curses.getmouse()
			except curses.error:
				pass
			continue
		if key != curses.KEY_RESIZE:
			return


def run_subprocess_in_curses(stdscr, cmd, title, env=None):
	"""Jalanin proses eksternal (mis. setup_godot_cpp.py) dan tampilin outputnya
	LANGSUNG di layar curses secara live, tanpa keluar ke terminal polos."""
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


def kotak_tengah(stdscr, baris_teks, judul=None):
	"""Gambar kotak (box) yang di-tengah-in penuh: tengah horizontal DAN
	vertikal, bukan cuma nempel ke kiri/atas. Dipakai buat pertanyaan awal
	(mau bikin folder proyek baru) supaya konsisten satu sesi curses sama
	menu utama -- gak ada transisi antar proses yang bikin kelip-kelip."""
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


def tanya_ya_tidak(stdscr, judul, pertanyaan):
	"""Cuma nerima Y atau N -- tombol lain diabaikan total, gak bisa
	kemana-mana sebelum milih salah satu."""
	curses.curs_set(0)
	while True:
		kotak_tengah(stdscr, [pertanyaan, "", "[ Y ] Yes          [ N ] No"], judul=judul)
		k = stdscr.getch()
		if k in (ord('y'), ord('Y')):
			return True
		elif k in (ord('n'), ord('N')):
			return False
		# tombol lain: diabaikan, loop lagi (gak kemana-mana)


def minta_nama_folder_baru(stdscr):
	"""Input nama folder di dalam kotak center. Validasi karakter DI DALAM
	curses -- kalau salah, kasih pesan error terus balik nanya lagi (bukan
	langsung keluar/gagal)."""
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


def tanya_dan_pindah_folder_proyek(stdscr):
	"""Tanya 'mau bikin folder proyek baru?' di sesi curses YANG SAMA (bukan
	proses python terpisah -- biar gak ada transisi keluar-masuk curses yang
	bikin kelip-kelip pas pertama dibuka). Kalau ya & folder baru dibuat,
	file bootstrap_scons_gui.py & setup_godot_cpp.py yang udah ke-generate di
	folder lama IKUT DIPINDAH ke folder baru itu, baru os.chdir() ke situ."""
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


def confirm_generate(stdscr, opts):
	"""Layar konfirmasi terakhir sebelum beneran generate SConstruct + build_logic.py,
	biar keliatan dulu ringkasan opsi sebelum ketimpa/dijalankan."""
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


def main(stdscr):
	curses.curs_set(0)
	
	# ========================================================================================================================
	# Tangkep event mouse (termasuk scroll wheel) di level curses -- kalau gak
	# di-set, scroll wheel di beberapa terminal (xterm dkk) bocor jadi kode
	# tombol acak yang keanggep 'tombol apapun ditekan' oleh dialog, bikin
	# layar (misal Credits) auto-nutup sendiri pas di-scroll.
	# ========================================================================================================================
	
	try:
		curses.mousemask(curses.ALL_MOUSE_EVENTS | curses.REPORT_MOUSE_POSITION)
	except curses.error:
		pass
	stdscr.clear()
	stdscr.refresh()
	
	# ========================================================================================================================
	# Inisialisasi warna (kalau terminal support). STYLE dict di-update di TEMPAT,
	# bukan diganti objeknya -- biar fungsi lain yang udah nyimpen referensi ke STYLE
	# (module-level) ikut kebaca versi warna begitu ini jalan. Kalau gagal/gak
	# didukung, STYLE tetap pakai fallback bold/dim/reverse polos yang udah didefinisikan.
	# ========================================================================================================================
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
	
	# ========================================================================================================================
	# Kasih jeda dikit + refresh ulang -- terminal yang BARU dibuka (misal lewat
	# self-relaunch ke xfce4-terminal) kadang belum settle ukurannya pas curses
	# langsung mulai gambar, jadi kotak pertama bisa gak keliatan/salah render
	# sampai ada redraw berikutnya. Jeda singkat ini mastiin ukuran terminal udah
	# stabil dulu sebelum kotak pertama digambar.
	# ========================================================================================================================
	
	curses.napms(150)
	stdscr.clear()
	stdscr.refresh()

	tanya_dan_pindah_folder_proyek(stdscr)

	log_lines = []
	opts = load_options()
	cursor = 0
	show_help = False

	HELP_ITEMS = [
		("section", "BUILD OPTIONS"),
		("body", "Build mode"),
		("body", "  Debug   -> slow & large compile, but easy to trace if there's a bug/crash"),
		("body", "  Release -> most optimized & fastest compile, but error messages are less clear"),
		("blank", ""),
		("body", "Linux Platform / Windows Platform"),
		("body", "  Toggle active/inactive -- which targets to compile. At least 1 must be active."),
		("blank", ""),
		("body", "Architecture (64-bit / 32-bit)"),
		("body", "  Toggle bit-width for both the project build and godot-cpp itself. 32-bit"),
		("body", "  needs the matching mingw-w64 32-bit compiler installed for Windows builds"),
		("body", "  (i686-w64-mingw32-g++), separate from the 64-bit one."),
		("blank", ""),
		("body", "Parallel jobs"),
		("body", "  Number of parallel compile processes (cycle: auto -> 2 -> 4 -> 8)."),
		("blank", ""),
		("section", "GODOT-CPP"),
		("body", "godot-cpp version"),
		("body", "  Toggle between available branches (4.0-4.5 etc), 'master', or"),
		("body", "  'custom...' to type a branch freely. This version's compile status shows"),
		("body", "  right next to its name (not downloaded / not compiled /"),
		("body", "  compiled). IMPORTANT: godot-cpp 10.x no longer has per-version branches"),
		("body", "  for Godot 4.6 and up -- use 'master' + set Target api_version below instead."),
		("blank", ""),
		("body", "Target api_version"),
		("body", "  Only applies when godot-cpp version = master. Determines which Godot"),
		("body", "  version is targeted at compile time (e.g. 4.7). Presets: 4.3/4.4/4.5/4.6/4.7, or"),
		("body", "  'custom...' for another version."),
		("blank", ""),
		("body", "[ Update version list (check GitHub) ]"),
		("body", "  Pulls the list of OLD version branches from GitHub godot-cpp (number.number"),
		("body", "  format, oldest to newest), saved as a local cache. 'master' and"),
		("body", "  'custom...' are always in the toggle regardless, since godot-cpp"),
		("body", "  10.x no longer creates a new branch per Godot version. If it fails (no"),
		("body", "  internet), the old list is still used, nothing breaks."),
		("blank", ""),
		("body", "[ Check installed Godot version ]"),
		("body", "  Best-effort detection of the Godot editor installed on this system, just"),
		("body", "  as a SUGGESTION for which api_version to use -- doesn't change any option"),
		("body", "  automatically."),
		("blank", ""),
		("body", "[ View all godot-cpp versions ]"),
		("body", "  Lists every godot-cpp-* folder in this project along with its compile"),
		("body", "  status and size, without having to toggle through each one."),
		("blank", ""),
		("body", "[ Setup godot-cpp ]"),
		("body", "  Runs setup_godot_cpp.py interactively (clone/compile). If the"),
		("body", "  godot-cpp-<version> folder already exists, asks whether to keep it or"),
		("body", "  re-download. Before cloning, the branch is checked against GitHub -- if"),
		("body", "  not found, you get a warning before continuing. Compile target follows"),
		("body", "  the Build mode above."),
		("blank", ""),
		("body", "[ Clean up old godot-cpp ]"),
		("body", "  Deletes every godot-cpp-* folder EXCEPT the one currently active"),
		("body", "  (asks you to type 'DELETE' to confirm). Handy for freeing up disk space"),
		("body", "  after trying several versions/api_versions."),
		("blank", ""),
		("body", "[ Delete godot-cpp ]"),
		("body", "  COMPLETELY deletes the currently active godot-cpp-<version> folder"),
		("body", "  (asks you to type 'DELETE' to confirm). Useful if the folder is corrupted"),
		("body", "  or you just want to clean up."),
		("blank", ""),
		("section", "ACTIONS"),
		("body", "[ Save options + Generate! ]"),
		("body", "  Shows a confirmation screen summarizing the options before actually"),
		("body", "  generating SConstruct + build_logic.py. The old build_options.json is"),
		("body", "  automatically backed up to build_options.json.bak before being overwritten."),
		("blank", ""),
		("body", "[ Quit ]"),
		("body", "  Closes the menu without regenerating (already-saved options still apply)."),
		("blank", ""),
		("section", "OTHER"),
		("body", "Last build (below the menu) is read from logs/build_history.json."),
		("body", "Folders auto-created during build: bin/, src/, build/, logs/"),
		("body", "  bin/<platform>_<bits>_<mode>/ -> compile output, separated per platform & mode"),
	]

	while True:
		if show_help:
			help_scroll = 0
			while True:
				stdscr.clear()
				hh, ww = stdscr.getmaxyx()
				
				# ========================================================================================================================
				# Lebar konten responsif: proporsional ke lebar terminal, dibatasi
				# biar teks gak jadi kepanjangan & susah dibaca di layar lebar.
				# ========================================================================================================================
				
				lebar_konten = max(36, min(ww - 6, 72))
				kiri = max(2, (ww - lebar_konten) // 2)
				
				# ========================================================================================================================
				# Word-wrap tiap baris ke lebar konten (bukan potong teks), biar isinya
				# tetap kebaca utuh berapa pun lebar terminalnya.
				# ========================================================================================================================
				
				import textwrap as _textwrap
				baris_wrap = []
				for kind, teks in HELP_ITEMS:
					if kind == "blank" or teks == "":
						baris_wrap.append(("blank", ""))
						continue
					indent = "  " if teks.startswith("  ") else ""
					untuk_wrap = teks.strip()
					lebar_wrap = max(10, lebar_konten - len(indent))
					potongan = _textwrap.wrap(untuk_wrap, lebar_wrap) or [""]
					for p in potongan:
						baris_wrap.append((kind, f"{indent}{p}"))

				judul_help = "HELP"
				sub_help = "UP/DOWN scroll  |  PgUp/PgDn page  |  Home/End jump  |  H/Q/ESC/ENTER close"
				try:
					stdscr.addstr(1, max(0, (ww - len(judul_help)) // 2), judul_help, STYLE["title"])
					stdscr.addstr(2, max(0, (ww - len(sub_help)) // 2), sub_help, STYLE["dim"])
				except curses.error:
					pass

				area_atas = 4
				area_bawah = hh - 1
				visible = max(1, area_bawah - area_atas)
				max_scroll = max(0, len(baris_wrap) - visible)
				help_scroll = min(help_scroll, max_scroll)

				for i, (kind, teks) in enumerate(baris_wrap[help_scroll:help_scroll + visible]):
					row = area_atas + i
					if row >= area_bawah:
						break
					style = STYLE["normal"]
					if kind == "title":
						style = STYLE["title"]
					elif kind == "section":
						style = STYLE["section"]
					try:
						stdscr.addstr(row, kiri, teks[: max(0, ww - kiri - 2)], style)
					except curses.error:
						pass

				if max_scroll > 0:
					persen = int(100 * help_scroll / max_scroll) if max_scroll else 0
					info_scroll = f"-- {persen}% --"
					try:
						stdscr.addstr(area_bawah, max(0, (ww - len(info_scroll)) // 2), info_scroll, STYLE["dim"])
					except curses.error:
						pass

				stdscr.refresh()
				key_help = stdscr.getch()

				if key_help == curses.KEY_RESIZE:
					continue
				elif key_help == curses.KEY_UP:
					help_scroll = max(0, help_scroll - 1)
				elif key_help == curses.KEY_DOWN:
					help_scroll = min(max_scroll, help_scroll + 1)
				elif key_help == curses.KEY_PPAGE:
					help_scroll = max(0, help_scroll - visible)
				elif key_help == curses.KEY_NPAGE:
					help_scroll = min(max_scroll, help_scroll + visible)
				elif key_help == curses.KEY_HOME:
					help_scroll = 0
				elif key_help == curses.KEY_END:
					help_scroll = max_scroll
				elif key_help in (ord('h'), ord('H'), ord('q'), ord('Q'), 27, curses.KEY_ENTER, 10, 13):
					break
			show_help = False
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
					if sekarang_api in DAFTAR_API:
						idx_now_api = DAFTAR_API.index(sekarang_api)
						berikutnya_api = DAFTAR_API[(idx_now_api + 1) % len(DAFTAR_API)]
					else:
						berikutnya_api = DAFTAR_API[0]

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

			elif pilihan == "cek_versi":
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

			elif pilihan == "cek_godot":
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

			elif pilihan == "lihat_semua":
				daftar = cek_semua_godot_cpp()
				if not daftar:
					show_message_dialog(stdscr, "ALL GODOT-CPP VERSIONS", ["There's no godot-cpp- folder here yet."])
				else:
					baris = [f"{d}  --  {status}  (~{ukuran} MB)" for d, status, ukuran in daftar]
					show_message_dialog(stdscr, "ALL GODOT-CPP VERSIONS", baris)

			elif pilihan == "setup":
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

			elif pilihan == "bersihkan_lama":
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

			elif pilihan == "hapus":
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

			elif pilihan == "generate":
				if not any(opts["platforms"].values()):
					log_lines.append("FAILED: at least one platform must be active!")
				else:
					if confirm_generate(stdscr, opts):
						save_options(opts)
						log_lines.append("OK: options saved.")
						generate_files(stdscr, log_lines)
					else:
						log_lines.append("Cancelled, generate was not run.")

			elif pilihan == "credits":
				show_message_dialog(stdscr, "CREDITS", CREDITS_LINES)

			elif pilihan == "export_credits":
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

			elif pilihan == "license":
				show_scrollable_dialog(stdscr, "LICENSE (GPL-3.0-or-later)", LICENSE_TEXT.splitlines())

			elif pilihan == "export_license":
				try:
					with open("LICENSE", "w", encoding="utf-8") as f:
						f.write(LICENSE_TEXT.strip("\n") + "\n")
					log_lines.append("OK: LICENSE exported successfully.")
				except Exception as e:
					log_lines.append(f"FAILED to export LICENSE: {e}")

			elif pilihan == "keluar":
				break
		elif key in (ord('q'), ord('Q')):
			break


if __name__ == "__main__":
	try:
		curses.wrapper(main)
	except Exception as e:
		print(f"An error occurred: {e}")
		print("Try enlarging the terminal window then run it again.")
		raise
PYEOF_INNER

cat > setup_godot_cpp.py << 'PYEOF_SETUP'
"""
setup_godot_cpp.py
------------------
Otomatis nyiapin godot-cpp (binding GDExtension buat Godot 4):
  1. Clone repo godot-cpp kalau folder-nya belum ada
  2. Compile godot-cpp buat Linux & Windows (kalau hasil compile-nya belum ada)

Kalau semua sudah ada/sudah ke-compile, langkah itu di-SKIP -- gak diulang percuma.

File ini di-generate OTOMATIS oleh jalankan_bootstrapper.sh setiap kali dijalankan,
persis kayak bootstrap_scons_gui.py -- jadi selalu ada di folder proyek manapun,
tanpa perlu disalin manual.

Jalanin: python3 setup_godot_cpp.py
"""

import os
import glob
import subprocess
import sys
import shutil
import json

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


def validasi_format_versi(versi):
	"""Validasi kasar format versi angka.angka (mis. '4.7', '4.7.1'). Salinan dari
	fungsi yang sama di bootstrap_scons_gui.py -- dipakai buat ngecek api_version
	sebelum beneran dipakai buat compile."""
	import re as _re
	return bool(_re.match(r'^\d+(\.\d+)+$', versi.strip()))


MODE = baca_mode_dari_build_options()
SCONS_TARGET = "template_debug" if MODE == "debug" else "template_release"
GODOT_CPP_BRANCH = baca_branch_dari_build_options()          # bisa diganti lewat menu curses ("Versi godot-cpp")
GODOT_CPP_API_VERSION = baca_api_version_dari_build_options()  # cuma dipakai kalau branch == "master"
BITS = baca_bits_dari_build_options()          # "64" atau "32", dari menu curses ("Architecture")
ARCH_SCONS = "x86_64" if BITS == "64" else "x86_32"    # nilai yang dipahami scons buat godot-cpp
REPO_URL = "https://github.com/godotengine/godot-cpp"

# PENTING (godot-cpp 10.x): branch per-versi Godot (4.0-4.5, dan branch 3.x lama) masih ada,
# tapi Godot 4.6 ke atas TIDAK punya branch sendiri lagi -- harus pakai branch "master"
# (godot-cpp versi 10.x) + parameter api_version saat compile. Folder dipisah:
# versi lama -> godot-cpp-<branch>, mode master -> godot-cpp-master-api<versi>
# (biar ganti target Godot di mode master gak nimpa hasil compile versi sebelumnya).
if GODOT_CPP_BRANCH == "master":
	GODOT_CPP_DIR = f"godot-cpp-master-api{GODOT_CPP_API_VERSION}"
else:
	GODOT_CPP_DIR = f"godot-cpp-{GODOT_CPP_BRANCH}"

# Kalau dipanggil DARI menu curses, semua keputusan (redownload/hapus) sudah
# ditanya duluan lewat curses -- jadi di sini TINGGAL BACA jawabannya lewat
# env var, tanpa nanya input() lagi (curses gak bisa nampung prompt terminal
# biasa). Kalau dijalanin manual lewat terminal (python3 setup_godot_cpp.py),
# env var ini kosong -- otomatis balik ke perilaku interaktif seperti biasa.
NONINTERAKTIF = os.environ.get("KOBI_NONINTERAKTIF") == "1"


def jalankan(cmd, cwd=None):
	print(f">>> Running: {' '.join(cmd)}" + (f"  (in folder {cwd})" if cwd else ""))
	hasil = subprocess.run(cmd, cwd=cwd)
	if hasil.returncode != 0:
		print(f"Failed to run: {' '.join(cmd)}")
		sys.exit(1)


def cek_command_ada(nama_command):
	from shutil import which
	return which(nama_command) is not None


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


def clone_godot_cpp():
	if os.path.isdir(GODOT_CPP_DIR):
		if NONINTERAKTIF:
			# Keputusan udah ditanya lewat curses SEBELUM script ini dipanggil.
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
		# Branch master selalu ada -- gak perlu network check yang gak relevan.
		# Yang justru perlu divalidasi di mode ini adalah FORMAT api_version-nya,
		# karena itu yang bisa salah ketik (bukan nama branch-nya).
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


def sudah_dicompile(platform):
	"""Cek kasar: apakah sudah ada file .a / .lib hasil compile buat platform+mode+arch ini.
	Pola nyertain ARCH_SCONS (x86_64/x86_32) juga -- biar build 32-bit dan 64-bit yang
	kebetulan ada di folder godot-cpp yang sama gak saling ketuker/anggep 'udah compile'."""
	pola = os.path.join(GODOT_CPP_DIR, "bin", f"*{platform}*{SCONS_TARGET}*{ARCH_SCONS}*")
	return len(glob.glob(pola)) > 0


def compile_godot_cpp(platform):
	if sudah_dicompile(platform):
		print(f"godot-cpp for '{platform}' ({SCONS_TARGET}, {ARCH_SCONS}) has already been compiled, skipping.")
		return

	cmd = ["scons", f"platform={platform}", f"target={SCONS_TARGET}", f"arch={ARCH_SCONS}", f"-j{os.cpu_count() or 2}"]
	keterangan_versi = f"{SCONS_TARGET}, {ARCH_SCONS}"
	if GODOT_CPP_BRANCH == "master":
		# Branch master gak terikat ke satu versi Godot -- api_version yang nentuin
		# fitur/API mana yang dipakai buat generate binding-nya.
		cmd.append(f"api_version={GODOT_CPP_API_VERSION}")
		keterangan_versi = f"{SCONS_TARGET}, {ARCH_SCONS}, api_version={GODOT_CPP_API_VERSION}"

	print(f"Compiling godot-cpp for platform '{platform}', target '{keterangan_versi}'... (this can take a while)")
	jalankan(cmd, cwd=GODOT_CPP_DIR)
	print(f"Finished compiling godot-cpp for '{platform}' ({keterangan_versi}).")


def hapus_godot_cpp():
	"""Hapus total folder godot-cpp-<branch> yang lagi aktif. Dipanggil dari menu curses
	(opsi [ Hapus godot-cpp ]) atau lewat --hapus di command line."""
	if not os.path.isdir(GODOT_CPP_DIR):
		print(f"Folder '{GODOT_CPP_DIR}' doesn't exist, nothing to delete.")
		return
	print(f"This will COMPLETELY delete folder '{GODOT_CPP_DIR}' (approximately {round(sum(os.path.getsize(os.path.join(dp, f)) for dp, _, fn in os.walk(GODOT_CPP_DIR) for f in fn) / (1024*1024))} MB).")
	if NONINTERAKTIF:
		# Konfirmasi udah ditanya lewat curses SEBELUM script ini dipanggil.
		konfirmasi = os.environ.get("KOBI_HAPUS_KONFIRMASI", "")
	else:
		konfirmasi = input(f"   Type 'DELETE' (all caps) to confirm, or ENTER to cancel: ").strip()
	if konfirmasi == "DELETE":
		shutil.rmtree(GODOT_CPP_DIR)
		print(f"Folder '{GODOT_CPP_DIR}' has been deleted.")
	else:
		print("Cancelled, folder was not deleted.")


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

	# 1. Pastikan tool dasar ada
	if not cek_command_ada("git"):
		print("'git' is not installed. Install it first: sudo apt install git")
		sys.exit(1)
	if not cek_command_ada("scons"):
		print("'scons' is not installed / not found in PATH.")
		sys.exit(1)

	# 2. Clone kalau belum ada
	clone_godot_cpp()

	# 3. Compile per platform (skip kalau sudah ada hasilnya)
	compile_godot_cpp("linux")

	# Nama compiler mingw beda tergantung arsitektur yang dipilih -- 64-bit pakai
	# x86_64-w64-mingw32-g++, 32-bit pakai i686-w64-mingw32-g++. Dulu di sini selalu
	# ngecek versi 64-bit doang, jadi kalau BITS="32" tapi cuma versi 64-bit mingw yang
	# keinstall, compile Windows bakal salah nyoba pakai compiler yang gak sesuai arch.
	MINGW_CXX = "x86_64-w64-mingw32-g++" if BITS == "64" else "i686-w64-mingw32-g++"
	if cek_command_ada(MINGW_CXX):
		compile_godot_cpp("windows")
	else:
		print(f"{MINGW_CXX} is not installed, skipping godot-cpp compile for Windows.")
		paket = "mingw-w64" if BITS == "64" else "mingw-w64-i686-dev g++-mingw-w64-i686"
		print(f"    Install it first: sudo apt install {paket}")

	print("\nAll done! godot-cpp is ready to use. Now just run `scons` in your project folder.")
	print(f"   (folder used: {GODOT_CPP_DIR})")


if __name__ == "__main__":
	main()
PYEOF_SETUP

python3 bootstrap_scons_gui.py
