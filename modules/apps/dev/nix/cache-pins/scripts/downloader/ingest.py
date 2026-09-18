import os
from pathlib import Path
import shutil
import subprocess
import sys
from typing import List, Optional, Tuple, Union


def ingest_store_paths(
    store_paths: Union[str, List[str]],
    local_cache_dir: Path,
    cache_urls: Optional[List[str]] = None,
) -> bool:
    """Ingest store paths from local RAM cache to /nix/store via fast nix copy with fallback to nix-store --realise."""
    paths = [store_paths] if isinstance(store_paths, str) else list(store_paths)
    if not paths:
        return True

    cache_uri = f"file://{local_cache_dir.resolve()}"

    # 1. Primary fast path: nix copy --from file://<cache_dir> --no-check-sigs
    # This is fast, atomic, and does not print spam warnings like '--add-root'
    copy_cmd = ["nix", "copy", "--from", cache_uri, "--no-check-sigs"] + paths
    res = subprocess.run(copy_cmd, capture_output=True, text=True)
    if res.returncode == 0:
        return True

    # 2. Fallback path: nix-store --realise for each path
    cache_list = cache_urls or ["https://cache.nixos.org"]
    substituters_str = f"{cache_uri}?priority=0 " + " ".join(
        [f"{u}?priority=100" for u in cache_list]
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
            cache_uri,
            "--option",
            "fallback",
            "false",
        ]
        fb_res = subprocess.run(cmd, capture_output=True, text=True)
        if fb_res.returncode != 0:
            print(f"❌ Ingestion error for {sp}:", file=sys.stderr)
            err_output = fb_res.stderr or res.stderr
            if err_output:
                for line in err_output.strip().splitlines():
                    print(f"   {line}", file=sys.stderr)
            all_ok = False

    return all_ok


def is_archive_file(p: Path) -> Tuple[bool, bool]:
    """Check if path is an archive file using extensions and magic bytes.

    Returns:
        (is_archive, is_zip)
    """
    if not p.is_file():
        return False, False

    name_lower = p.name.lower()
    is_zip = name_lower.endswith(".zip")
    known_tar_exts = [
        ".tar.gz", ".tgz", ".tar.bz2", ".tbz2",
        ".tar.xz", ".txz", ".tar.zst", ".tar"
    ]
    if any(name_lower.endswith(ext) for ext in known_tar_exts):
        return True, False
    if is_zip:
        return True, True

    try:
        with open(p, "rb") as f:
            header = f.read(262)
            if header.startswith(b"\x1f\x8b") or header.startswith(b"BZh") or \
               header.startswith(b"\xfd7zXZ\x00") or header.startswith(b"\x28\xb5\x2f\xfd"):
                return True, False
            if header.startswith(b"PK\x03\x04"):
                return True, True
            if len(header) >= 262 and header[257:262] == b"ustar":
                return True, False
    except Exception:
        pass

    return False, False


def ingest_single_fod(
    item: "FodDownloadItem",
    download_dir: Path,
    delete_after: bool = False,
) -> bool:
    """Ingest a single downloaded Fixed-Output Derivation (FOD) file into /nix/store via nix-store --add-fixed.

    Supports flat files, direct directories, and recursive archive extraction (fetchzip / tarballs).
    Optionally deletes the downloaded file immediately after ingestion to free RAM tmpfs.
    """
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

    if not file_path and item.out_path:
        out_hash = item.out_path.split("/")[-1].split("-")[0]
        if out_hash:
            matched = list(download_dir.glob(f"*{out_hash}*"))
            if matched:
                file_path = matched[0]

    if not file_path:
        matched = list(download_dir.glob(f"*{item.filename}*"))
        if matched:
            file_path = matched[0]

    if not file_path or not file_path.exists():
        print(
            f"❌ ERROR: Berkas FOD '{item.filename}' tidak ditemukan di {download_dir}.",
            file=sys.stderr,
        )
        return False

    is_archive, is_zip = is_archive_file(file_path)
    if getattr(item, "post_fetch", None) is not None:
        is_archive = True

    stage_dir = None
    target_path_for_nix = file_path
    success = False
    out_hash = item.out_path.split("/")[-1].split("-")[0] if getattr(item, "out_path", None) else ""
    hash_prefix = out_hash[:10] if out_hash else "nohash"

    try:
        if item.hash_mode == "recursive" and is_archive and file_path.is_file():
            stage_dir = download_dir / f"_fod_stage_{hash_prefix}_{item.filename}"
            if stage_dir.exists():
                shutil.rmtree(stage_dir, ignore_errors=True)
            stage_dir.mkdir(parents=True, exist_ok=True)
            unpack_dir = stage_dir / "unpack"
            unpack_dir.mkdir(parents=True, exist_ok=True)

            if is_zip:
                ext_cmd = ["unzip", "-q", "-o", str(file_path), "-d", str(unpack_dir)]
            else:
                ext_cmd = ["tar", "-xf", str(file_path), "-C", str(unpack_dir)]

            ext_res = subprocess.run(ext_cmd, capture_output=True, text=True)
            if ext_res.returncode != 0:
                print(
                    f"❌ Gagal mengekstrak arsip FOD '{file_path.name}': {ext_res.stderr.strip()}",
                    file=sys.stderr,
                )
                return False

            strip_root = getattr(item, "strip_root", True)
            entries = [e for e in unpack_dir.iterdir() if e.name not in (".", "..")]

            final_target = stage_dir / item.filename
            if strip_root and len(entries) == 1 and entries[0].is_dir():
                entries[0].rename(final_target)
            else:
                unpack_dir.rename(final_target)

            os.chmod(final_target, 0o755)
            target_path_for_nix = final_target
        elif file_path.name != item.filename:
            stage_dir = download_dir / f"_fod_stage_{hash_prefix}_{item.filename}"
            if stage_dir.exists():
                shutil.rmtree(stage_dir, ignore_errors=True)
            stage_dir.mkdir(parents=True, exist_ok=True)
            final_target = stage_dir / item.filename
            if file_path.is_file():
                shutil.copy2(file_path, final_target)
            elif file_path.is_dir():
                shutil.copytree(file_path, final_target)
            target_path_for_nix = final_target

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
            return False
        else:
            resulting_path = res.stdout.strip()
            if item.out_path and resulting_path != item.out_path:
                print(
                    f"❌ ERROR: Store path hasil ({resulting_path}) berbeda dari yang diharapkan ({item.out_path})!",
                    file=sys.stderr,
                )
                return False
            success = True
            return True

    finally:
        if stage_dir and stage_dir.exists():
            shutil.rmtree(stage_dir, ignore_errors=True)
        if success and delete_after and file_path and file_path.exists():
            try:
                if file_path.is_file():
                    file_path.unlink(missing_ok=True)
                elif file_path.is_dir():
                    shutil.rmtree(file_path, ignore_errors=True)
            except Exception:
                pass


def ingest_fod_items(
    fod_items: List["FodDownloadItem"],
    download_dir: Path,
    delete_after: bool = False,
) -> bool:
    """Ingest downloaded Fixed-Output Derivation (FOD) files into /nix/store via nix-store --add-fixed."""
    all_ok = True
    for item in fod_items:
        ok = ingest_single_fod(item, download_dir, delete_after=delete_after)
        if not ok:
            all_ok = False
    return all_ok

