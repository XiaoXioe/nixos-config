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

# Pure builtins.fetchClosure, zero nixpkgs closure overhead by default.
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
  # Signatures:
  #   1. (selfLib.fetchCachePinned "gthumb") -> derivation
  #   2. (selfLib.fetchCachePinned [ "gthumb" "aria2" ]) -> list of derivations
  #   3. (selfLib.fetchCachePinned pkgs "chromium") -> derivation with .override support
  #   4. (selfLib.fetchCachePinned pkgs [ "gthumb" "aria2" ]) -> list of derivations with .override support
  #
  # Args:
  #   registry : attrset             — Isi dari cache-pins.nix
  #   arg1     : pkgs | string | list — Instance `pkgs` ATAU nama paket / list paket
  #   arg2     : string | list        — (Opsional jika arg1 adalah `pkgs`) nama paket / list paket
  #
  # Returns:
  #   - Jika target string : mengembalikan store path / derivation
  #   - Jika target list   : mengembalikan list of store paths / derivations
  fetchCachePinned =
    registry: arg1:
    assert checkFeature;
    let
      isPkgs = builtins.isAttrs arg1 && (arg1 ? runCommand || arg1 ? stdenv);

      impl =
        pkgsArg: targetArg:
        let
          fetchOne =
            name:
            assert
              registry ? ${name}
              || throw "fetchCachePinned: '${name}' tidak ditemukan di modules/_lib/cache-pins.nix";
            let
              entry = registry.${name};
              storePath = builtins.fetchClosure {
                fromStore = entry.fromStore or "https://cache.nixos.org";
                fromPath = entry.storePath;
                inputAddressed = true;
              };
              version = entry.version or "";
              pname = entry.pname or name;
              pkgName = if version != "" then "${pname}-${version}" else pname;
              pkg = {
                type = "derivation";
                inherit pname version;
                name = pkgName;
                outPath = storePath;
                out = pkg;
                outputs = [ "out" ];
                meta = {
                  mainProgram = entry.mainProgram or pname;
                };
                __toString = self: self.outPath;
              }
              // (
                if pkgsArg != null then
                  {
                    override =
                      args:
                      let
                        resolvedArgs = if builtins.isFunction args then args { } else args;
                        commandLineArgs = resolvedArgs.commandLineArgs or "";
                        extraArgs = resolvedArgs.extraArgs or [ ];
                        flagsList = (if commandLineArgs != "" then [ commandLineArgs ] else [ ]) ++ extraArgs;
                        allFlags = builtins.concatStringsSep " " flagsList;
                      in
                      if flagsList == [ ] then
                        pkg
                      else
                        pkgsArg.runCommand pkgName
                          {
                            nativeBuildInputs = [ pkgsArg.makeWrapper ];
                          }
                          ''
                            mkdir -p "$out/bin" "$out/share"
                            if [ -d "${storePath}/share" ]; then
                              for f in "${storePath}"/share/*; do
                                ln -s "$f" "$out/share/"
                              done
                            fi
                            if [ -d "${storePath}/bin" ]; then
                              for b in "${storePath}"/bin/*; do
                                binName="$(basename "$b")"
                                makeWrapper "$b" "$out/bin/$binName" \
                                  --add-flags "${allFlags}"
                              done
                            fi
                          '';
                  }
                else
                  { }
              );
            in
            pkg;
          fetchItem =
            item:
            if
              (builtins.isAttrs item || builtins.isFunction item)
              && (item ? outPath || item ? type || item ? pname)
            then
              item
            else if builtins.isString item then
              fetchOne item
            else
              throw "fetchCachePinned: Setiap item harus berupa string (nama paket di cache-pins.nix) atau objek derivation paket.";
        in
        if builtins.isList targetArg then
          map fetchItem targetArg
        else if
          (builtins.isAttrs targetArg || builtins.isFunction targetArg)
          && (targetArg ? outPath || targetArg ? type || targetArg ? pname)
        then
          targetArg
        else if builtins.isString targetArg then
          fetchOne targetArg
        else
          throw "fetchCachePinned: Argumen target harus berupa string (nama paket), objek derivation paket, atau list.";
    in
    if isPkgs then (target: impl arg1 target) else impl null arg1;
}
