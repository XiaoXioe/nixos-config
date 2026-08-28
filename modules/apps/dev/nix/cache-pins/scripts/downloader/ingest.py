import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import List, Union


def ingest_store_paths(
    store_paths: Union[str, List[str]],
    local_cache_dir: Path,
    cache_urls: List[str],
) -> bool:
    """Ingest store paths from local RAM cache to /nix/store via nix-store --realise."""
    paths = [store_paths] if isinstance(store_paths, str) else store_paths
    substituters_str = f"file://{local_cache_dir}?priority=0 " + " ".join(
        [f"{u}?priority=100" for u in cache_urls]
    )

    all_ok = True
    for sp in paths:
        cmd = [
            "nix-store",
            "--realise",
            sp,
            "--option",
            "substituters",
            substituters_str,
            "--option",
            "trusted-substituters",
            f"file://{local_cache_dir}",
            "--option",
            "fallback",
            "false",
        ]
        res = subprocess.run(cmd, capture_output=True, text=True)
        if res.returncode != 0:
            print(f"❌ Ingestion error for {sp}:", file=sys.stderr)
            if res.stderr:
                for line in res.stderr.strip().splitlines():
                    print(f"   {line}", file=sys.stderr)
            all_ok = False

    return all_ok


def ingest_fod_items(
    fod_items: List["FodDownloadItem"],
    download_dir: Path,
) -> bool:
    """Ingest downloaded Fixed-Output Derivation (FOD) files into /nix/store via nix-store --add-fixed.

    Supports flat files, direct directories, and recursive archive extraction (fetchzip / tarballs).
    """
    all_ok = True
    for item in fod_items:
        # 1. Cari berkas hasil unduhan di download_dir
        candidate_names = []
        if getattr(item, "download_filename", None):
            candidate_names.append(item.download_filename)
        candidate_names.append(item.filename)

        file_path = None
        for name in candidate_names:
            p = download_dir / name
            if p.exists():
                file_path = p
                break

        if not file_path:
            # Fallback search if name slightly changed
            matched = list(download_dir.glob(f"*{item.filename}*"))
            if matched:
                file_path = matched[0]

        if not file_path or not file_path.exists():
            print(
                f"❌ ERROR: Berkas FOD '{item.filename}' tidak ditemukan di {download_dir}.",
                file=sys.stderr,
            )
            all_ok = False
            continue

        is_archive = (
            any(
                str(file_path).lower().endswith(ext)
                for ext in [
                    ".tar.gz",
                    ".tgz",
                    ".tar.bz2",
                    ".tbz2",
                    ".tar.xz",
                    ".txz",
                    ".tar.zst",
                    ".zip",
                    ".tar",
                ]
            )
            or (getattr(item, "post_fetch", None) is not None)
        )

        stage_dir = None
        target_path_for_nix = file_path

        try:
            # 2. Tangani Unpacking jika mode rekursif dan berkas merupakan arsip (fetchzip / fetchTarball)
            if item.hash_mode == "recursive" and is_archive and file_path.is_file():
                stage_dir = download_dir / f"_fod_stage_{item.filename}"
                if stage_dir.exists():
                    shutil.rmtree(stage_dir, ignore_errors=True)
                stage_dir.mkdir(parents=True, exist_ok=True)
                unpack_dir = stage_dir / "unpack"
                unpack_dir.mkdir(parents=True, exist_ok=True)

                # Ekstraksi arsip
                if str(file_path).lower().endswith(".zip"):
                    ext_cmd = ["unzip", "-q", "-o", str(file_path), "-d", str(unpack_dir)]
                else:
                    ext_cmd = ["tar", "-xf", str(file_path), "-C", str(unpack_dir)]

                ext_res = subprocess.run(ext_cmd, capture_output=True, text=True)
                if ext_res.returncode != 0:
                    print(
                        f"❌ Gagal mengekstrak arsip FOD '{file_path.name}': {ext_res.stderr.strip()}",
                        file=sys.stderr,
                    )
                    all_ok = False
                    continue

                # Strip Root logic (seperti fetchzip Nixpkgs)
                strip_root = getattr(item, "strip_root", True)
                entries = [
                    e for e in unpack_dir.iterdir() if e.name not in (".", "..")
                ]

                final_target = stage_dir / item.filename
                if strip_root and len(entries) == 1 and entries[0].is_dir():
                    entries[0].rename(final_target)
                else:
                    unpack_dir.rename(final_target)

                # Set permissions standar
                os.chmod(final_target, 0o755)
                target_path_for_nix = final_target

            # 3. Eksekusi nix-store --add-fixed
            cmd = ["nix-store", "--add-fixed"]
            if item.hash_mode == "recursive":
                cmd.append("--recursive")
            cmd.extend([item.hash_algo, str(target_path_for_nix)])

            res = subprocess.run(cmd, capture_output=True, text=True)
            if res.returncode != 0:
                print(
                    f"❌ Gagal meng-ingest berkas FOD '{item.filename}' ke /nix/store:",
                    file=sys.stderr,
                )
                if res.stderr:
                    for line in res.stderr.strip().splitlines():
                        print(f"   {line}", file=sys.stderr)
                all_ok = False
            else:
                resulting_path = res.stdout.strip()
                if item.out_path and resulting_path != item.out_path:
                    print(
                        f"⚠️ PERINGATAN: Store path hasil ({resulting_path}) berbeda dari yang diharapkan ({item.out_path})!",
                        file=sys.stderr,
                    )
                else:
                    print(
                        f"  ✔ [FOD Ingest] {item.filename} ➔ {resulting_path}",
                        file=sys.stderr,
                    )

        finally:
            if stage_dir and stage_dir.exists():
                shutil.rmtree(stage_dir, ignore_errors=True)

    return all_ok

