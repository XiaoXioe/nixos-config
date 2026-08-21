{ lib }:

{
  options = {
    rpmfusion = {
      free = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable RPM Fusion Free repository (Fedora containers only).";
      };
      unfree = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Enable RPM Fusion Unfree/Nonfree repository (Fedora containers only).";
      };
    };
  };

  # Menghasilkan pre_init_hooks untuk menginstal repositori RPM Fusion jika diaktifkan
  mkPreInitHooks =
    cVal:
    let
      rpmCfg = cVal.rpmfusion or { };
      free = rpmCfg.free or false;
      unfree = rpmCfg.unfree or false;
    in
    lib.optional free "test -f /etc/yum.repos.d/rpmfusion-free.repo || sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm"
    ++ lib.optional unfree "test -f /etc/yum.repos.d/rpmfusion-nonfree.repo || sudo dnf install -y https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm";
}
