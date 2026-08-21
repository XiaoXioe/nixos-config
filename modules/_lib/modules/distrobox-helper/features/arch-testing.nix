{ lib }:

let
  enableTestingCmd = lib.concatStringsSep " && " [
    # Uncomment [extra-testing] dan Include jika sudah ada di komentar template pacman.conf
    "sudo sed -i '/^#\\[extra-testing\\]/,/^#Include/ s/^#//' /etc/pacman.conf"
    # Fallback: sisipkan section [extra-testing] sebelum [extra] jika belum ada
    "grep -q '^\\[extra-testing\\]' /etc/pacman.conf || sudo sed -i '/^\\[extra\\]/i [extra-testing]\\nInclude = /etc/pacman.d/mirrorlist\\n' /etc/pacman.conf"
    "sudo pacman -Sy"
  ];
in
{
  options = {
    extraTesting = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Arch Linux [extra-testing] repository for latest package versions (e.g. Bitwarden).";
    };
  };

  # Menghasilkan pre_init_hooks untuk mengaktifkan repository [extra-testing]
  mkPreInitHooks =
    cVal:
    lib.optional (cVal.extraTesting or false
    ) ''grep -q '^\[extra-testing\]' /etc/pacman.conf && true || (${enableTestingCmd})'';
}
