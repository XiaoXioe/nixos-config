{ lib }:

let
  allFeatureFiles = [
    ./arch-testing.nix
    ./chaotic-aur.nix
    ./copr.nix
    ./rpmfusion.nix
    ./symlinks.nix
  ];

  allFeatures = map (f: import f { inherit lib; }) allFeatureFiles;
in
{
  # Menggabungkan seluruh options dari semua plugin fitur
  featureOptions = lib.foldl' lib.recursiveUpdate { } (map (f: f.options or { }) allFeatures);

  # Mengumpulkan pre_init_hooks dari seluruh plugin fitur
  getFeaturePreInitHooks =
    cVal:
    lib.concatLists (map (f: if f ? mkPreInitHooks then f.mkPreInitHooks cVal else [ ]) allFeatures);

  # Mengumpulkan init_hooks dari seluruh plugin fitur
  getFeatureInitHooks =
    cVal: lib.concatLists (map (f: if f ? mkInitHooks then f.mkInitHooks cVal else [ ]) allFeatures);
}
