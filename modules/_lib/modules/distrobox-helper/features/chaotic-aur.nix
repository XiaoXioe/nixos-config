{ lib }:

let
  chaoticSetupCmd = lib.concatStringsSep " && " [
    "sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com"
    "sudo pacman-key --lsign-key 3056513887B78AEB"
    "sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'"
    "sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'"
    ''grep -q '^\[chaotic-aur\]' /etc/pacman.conf || printf '\n[chaotic-aur]\nInclude = /etc/pacman/chaotic-mirrorlist\n' | sudo tee -a /etc/pacman.conf''
    "sudo pacman -Sy"
  ];
in
{
  options = {
    chaoticAur = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable Chaotic-AUR pre-built binary repository for Arch Linux containers.";
    };
  };

  # Menghasilkan pre_init_hooks untuk setup repository Chaotic-AUR sebelum paket diinstal
  mkPreInitHooks =
    cVal:
    lib.optional (cVal.chaoticAur or false
    ) ''grep -q '^\[chaotic-aur\]' /etc/pacman.conf || (${chaoticSetupCmd})'';
}
