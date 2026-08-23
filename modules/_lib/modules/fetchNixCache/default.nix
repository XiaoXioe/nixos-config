# modules/_lib/modules/fetchNixCache/default.nix
#
# fetchFromNixCache — Wrapper builtins.fetchClosure untuk Nix Binary Cache.
#
# Menggunakan builtins.fetchClosure yang:
#   - Dikonfirmasi bekerja di Lix 2.94.2 dengan fetch-closure feature
#   - Tidak membutuhkan pkgs sebagai dependency — pure builtins
#   - Fetch SELURUH closure (paket + semua deps) secara otomatis
#   - Mengembalikan store path IDENTIK dengan path asli di Hydra
#   - Zero Re-Download: Nix daemon skip jika path sudah di /nix/store
#   - Zero Re-Unpack: store paths immutable & permanen di /nix/store
#
# Requires: nix.settings.experimental-features includes "fetch-closure"
# (dikonfigurasi di modules/core/nix.nix)
_:

# Tidak ada argumen `pkgs` — pure builtins.fetchClosure, zero nixpkgs closure.
let
  # Error informatif jika feature belum aktif saat evaluasi
  checkFeature =
    if builtins ? fetchClosure then
      true
    else
      throw ''
        fetchFromNixCache: builtins.fetchClosure tidak tersedia.
        Pastikan modules/core/nix.nix mengandung:
          nix.settings.experimental-features = [ "nix-command" "flakes" "fetch-closure" ];
        Dan /etc/nix/nix.conf sudah aktif (atau tambahkan sementara ke ~/.config/nix/nix.conf).
      '';

in
{
  # ── fetchFromNixCache ─────────────────────────────────────────────────────
  # Fetch satu store path beserta seluruh closure-nya dari binary cache.
  #
  # Args:
  #   storePath : string — Path Hydra, e.g. "/nix/store/86nhn...-rclone-1.75.0"
  #   fromStore : string — Binary cache URL (default: cache.nixos.org)
  #   ...       : attrset — Field lain (version, system, dll) — diabaikan
  #
  # Returns: store path string (langsung bisa dipakai sebagai paket/ExecStart)
  #
  # Properti:
  #   - Store path identik dengan path asli di Hydra
  #   - Nix cek keberadaan lokal sebelum network call
  #   - Sekali di /nix/store → immutable, tidak pernah diunduh/diunpack ulang
  fetchFromNixCache =
    {
      storePath,
      fromStore ? "https://cache.nixos.org",
      ...
    }:
    assert checkFeature;
    builtins.fetchClosure {
      inherit fromStore;
      fromPath = storePath;
      inputAddressed = true;
    };

  # ── fetchCachePinned ──────────────────────────────────────────────────────
  # Shorthand: fetch dari registry cache-pins.nix secara fleksibel (Polymorphic).
  #
  # Args:
  #   registry : attrset         — Isi dari cache-pins.nix
  #   target   : string | [string] — Nama paket tunggal ("gthumb") ATAU daftar nama paket (["gthumb" "aria2"])
  #
  # Returns:
  #   - Jika target string : mengembalikan store path string
  #   - Jika target list   : mengembalikan list of store path strings
  #
  # Contoh di module NixOS / Home-Manager:
  #   home.packages = [ (selfLib.fetchCachePinned "rclone") ];
  #   ATAU
  #   home.packages = selfLib.fetchCachePinned [ "gthumb" "rclone" "aria2" ];
  fetchCachePinned =
    registry: target:
    assert checkFeature;
    let
      fetchOne =
        name:
        assert
          registry ? ${name}
          || throw "fetchCachePinned: '${name}' tidak ditemukan di modules/_lib/cache-pins.nix";
        builtins.fetchClosure {
          fromStore = registry.${name}.fromStore or "https://cache.nixos.org";
          fromPath = registry.${name}.storePath;
          inputAddressed = true;
        };
    in
    if builtins.isList target then
      map fetchOne target
    else if builtins.isString target then
      fetchOne target
    else
      throw "fetchCachePinned: Argumen harus berupa string (nama paket) atau list of strings (daftar paket).";
}
