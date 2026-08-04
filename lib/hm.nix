# Home Manager helpers for out-of-store symlinks.
# Uses native HM lib.file.mkOutOfStoreSymlink — no custom derivation needed.
{ lib }:
{
  # Generate home.file / xdg.configFile entries as out-of-store symlinks.
  # Usage: selfLib.mkHmSymlinks hmOpts.config { "Documents" = "/mnt/data/Documents"; }
  mkHmSymlinks =
    hmConfig: attrs:
    lib.mapAttrs (_name: path: {
      source = hmConfig.lib.file.mkOutOfStoreSymlink path;
    }) attrs;
}
