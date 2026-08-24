"""Formatting functions for byte sizes, audit reports, and Nix snippet generation."""
import datetime
import os
import re
from typing import Union

from core.models import ClosureAudit


def format_bytes(bytes_num: Union[int, float]) -> str:
    """Format bytes into a human-readable string (B, KiB, MiB, GiB)."""
    if not isinstance(bytes_num, (int, float)) or bytes_num < 0:
        return "0 B"
    if bytes_num >= 1073741824:
        return f"{bytes_num / 1073741824:.2f} GiB"
    elif bytes_num >= 1048576:
        return f"{bytes_num / 1048576:.2f} MiB"
    elif bytes_num >= 1024:
        return f"{bytes_num / 1024:.2f} KiB"
    else:
        return f"{int(bytes_num)} B"


def render_audit_report(audit: ClosureAudit, verbose: bool = False) -> str:
    """Generate detailed audit report string for stderr."""
    lines = []
    lines.append("")
    lines.append("================================================================================")
    lines.append("                    HASIL ANALISIS NIX BINARY CACHE")
    lines.append("================================================================================")
    lines.append(f"📦 Paket Target    : {audit.target_name} (v{audit.version})")
    lines.append(f"🔗 Store Path      : {audit.store_path}")
    lines.append(f"🌐 Cache Source    : {audit.cache_url} (Compression: {audit.compression})")
    lines.append("--------------------------------------------------------------------------------")
    lines.append("📊 METRIK UKURAN UTAMA:")
    local_tag = " [✅ SUDAH ADA DI STORE LOKAL]" if audit.target_is_local else " [⬇️  BELUM ADA DI STORE LOKAL]"
    lines.append(f"  • Biner Paket Ini (FileSize)   : {format_bytes(audit.file_size)} ({audit.compression}){local_tag}")
    lines.append(f"  • Ukuran Disk Paket (NarSize)  : {format_bytes(audit.nar_size)} (Uncompressed)")
    lines.append("")
    lines.append("🌐 TOTAL KEBUTUHAN BANDWIDTH INTERNET (RIIL):")
    lines.append(f"  • Total Download Kotor (Gross) : {format_bytes(audit.gross_download)} (Full Closure: Paket + 100% Semua Library)")
    if audit.net_download == 0:
        lines.append("  • Total Download Bersih (Net)   : 0 B (✅ Paket utama & seluruh library sudah ada di disk!)")
    else:
        lines.append(f"  • Total Download Bersih (Net)   : {format_bytes(audit.net_download)} (Hanya yang belum ada di disk lokal)")
    lines.append(f"  • Penghematan Kuota Lokal      : ⚡ {format_bytes(audit.saved_bandwidth)} ({audit.saved_percent:.1f}% bandwidth dihemat!)")
    lines.append(f"  • Total Penambahan di Disk     : {format_bytes(audit.net_disk)} (Footprint tambahan di /nix/store)")
    lines.append("--------------------------------------------------------------------------------")
    lines.append("🧩 ANALISIS DEPENDENSI & GLIBC:")
    lines.append(f"  • Target Glibc                 : {audit.target_glibc}")
    glibc_status = "✅ Shared (Sudah ada di /nix/store lokal — 0 Byte overhead)" if audit.glibc_local else "⚠️  Isolated (Belum ada di lokal — akan mengunduh glibc baru)"
    lines.append(f"  • Status Glibc Lokal           : {glibc_status}")
    lines.append(f"  • Total Direct Dependencies    : {audit.total_refs} dependensi")
    lines.append(f"  • Status Cache Lokal           : {audit.local_count}/{audit.total_refs} ({audit.local_percent:.1f}%) sudah ada di /nix/store")

    if verbose:
        lines.append("--------------------------------------------------------------------------------")
        lines.append(f"📋 DAFTAR SELURUH DEPENDENSI ({audit.total_refs} PAKET) [VERBOSE MODE]:")
        for item in audit.all_items:
            size_fmt = format_bytes(item["file_size"])
            prefix = "[✅ Lokal]        " if item["is_local"] else "[⬇️  Perlu Diunduh]"
            if item["file_size"] > 0:
                lines.append(f"  {prefix} {item['name']} ({size_fmt})")
            else:
                lines.append(f"  {prefix} {item['name']}")
    else:
        if audit.missing_count > 0:
            extra_size_fmt = format_bytes(sum(i['file_size'] for i in audit.missing_items))
            lines.append(f"  • Library/Dependensi Tambahan  : {audit.missing_count} paket yang belum ada di lokal (Total: {extra_size_fmt})")
            for item in audit.missing_items:
                size_fmt = format_bytes(item["file_size"])
                if item["file_size"] > 0:
                    lines.append(f"      - {item['name']}: {size_fmt}")
                else:
                    lines.append(f"      - {item['name']}")
            lines.append("  (Gunakan flag '-v' untuk menampilkan seluruh daftar library)")
        else:
            lines.append("  • Library/Dependensi Tambahan  : 0 paket (Semua dependensi 100% lokal — 0 Byte library download!)")
            lines.append("  (Gunakan flag '-v' untuk menampilkan seluruh daftar library)")

    lines.append("================================================================================")
    return "\n".join(lines)


def normalize_channel_name(source_input: str) -> str:
    """Extract clean shorthand channel name from source input URL."""
    if not source_input:
        return "nixpkgs"
    s = source_input.strip()
    if "nixos-unstable" in s or s in ("unstable", "nixpkgs-unstable"):
        return "unstable"
    match_ver = re.search(r"nixos-(\d{2}\.\d{2})", s)
    if match_ver:
        return match_ver.group(1)
    if re.match(r"^\d{2}\.\d{2}$", s):
        return s
    return s


def render_nix_snippet(audit: ClosureAudit, source_input: str) -> str:
    """Generate Nix attrset snippet suitable for cache-pins.nix."""
    attr_key = audit.target_name.replace("pkgs.", "")
    attr_key_clean = re.sub(r"[^a-zA-Z0-9_]", "_", attr_key)

    today = datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%d")
    missing_bytes = sum(i["file_size"] for i in audit.missing_items)
    cache_info = f" | Cache: {audit.cache_url}" if audit.cache_url and "cache.nixos.org" not in audit.cache_url else ""
    channel_name = normalize_channel_name(source_input)

    lines = []
    lines.append("")
    lines.append(f"  # Generated: {today} | Source: {source_input}{cache_info}")
    lines.append(f"  # Download Kotor (Full): {format_bytes(audit.gross_download)} | Download Bersih: {format_bytes(audit.net_download)}")
    lines.append(f"  # Library Lokal: {audit.local_count}/{audit.total_refs} ({audit.local_percent:.1f}%) | Missing: {audit.missing_count} paket ({format_bytes(missing_bytes)})")
    lines.append(f"  {attr_key_clean} = {{")
    lines.append(f'    storePath = "{audit.store_path}";')
    if audit.version:
        lines.append(f'    version = "{audit.version}";')
    if audit.main_program:
        lines.append(f'    mainProgram = "{audit.main_program}";')
    lines.append(f'    channel = "{channel_name}";')
    if audit.cache_url and "cache.nixos.org" not in audit.cache_url:
        lines.append(f'    fromStore = "{audit.cache_url}";')
    lines.append('    system = "x86_64-linux";')
    lines.append("  };")

    return "\n".join(lines)
