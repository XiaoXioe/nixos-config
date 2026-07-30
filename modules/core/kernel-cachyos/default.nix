{
  inputs,
  pkgs,
  lib,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "core.kernel-cachyos";
  description = "CachyOS kernel with BORE scheduler from xddxdd/nix-cachyos-kernel";

  options = {
    package = lib.mkOption {
      type = lib.types.raw;
      default =
        inputs.nix-cachyos-kernel.legacyPackages.${pkgs.stdenv.hostPlatform.system}.linuxPackages-cachyos-bore;
      description = "The CachyOS kernel package set.";
    };
  };

  nixosConfig = { };
}
