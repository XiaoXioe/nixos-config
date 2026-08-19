{ lib }:

let
  # Detect distro type from container image name
  detectDistro =
    image:
    if image == null || image == "" then
      "debian" # Default base image in this system is debian:testing
    else
      let
        lowerImage = lib.toLower image;
      in
      if lib.hasInfix "debian" lowerImage then
        "debian"
      else if lib.hasInfix "ubuntu" lowerImage then
        "ubuntu"
      else if lib.hasInfix "arch" lowerImage then
        "arch"
      else if
        lib.hasInfix "fedora" lowerImage
        || lib.hasInfix "ubi" lowerImage
        || lib.hasInfix "centos" lowerImage
        || lib.hasInfix "rocky" lowerImage
        || lib.hasInfix "alma" lowerImage
      then
        "fedora"
      else if lib.hasInfix "alpine" lowerImage then
        "alpine"
      else if
        lib.hasInfix "opensuse" lowerImage
        || lib.hasInfix "tumbleweed" lowerImage
        || lib.hasInfix "leap" lowerImage
      then
        "opensuse"
      else if lib.hasInfix "void" lowerImage then
        "void"
      else
        "custom";

  # Base GUI, font, audio, and utility packages per distro package manager
  distroPackages = {
    debian =
      {
        deltaUpdates ? true,
      }:
      [
        "ca-certificates"
        "curl"
        "gnupg"
        "fonts-dejavu"
        "fonts-noto-color-emoji"
        "fonts-liberation"
        "libgl1-mesa-dri"
        "libgl1"
        "libglx-mesa0"
        "mesa-vulkan-drivers"
        "libpipewire-0.3-0"
        "libpulse0"
        "libasound2t64"
      ]
      ++ lib.optionals deltaUpdates [ "debdelta" ];

    ubuntu =
      {
        deltaUpdates ? false,
      }:
      [
        "ca-certificates"
        "curl"
        "gnupg"
        "fonts-dejavu"
        "fonts-noto-color-emoji"
        "fonts-liberation"
        "libgl1-mesa-dri"
        "libgl1"
        "libglx-mesa0"
        "mesa-vulkan-drivers"
        "libpipewire-0.3-0"
        "libpulse0"
        "libasound2t64"
      ]
      ++ lib.optionals deltaUpdates [ "debdelta" ];

    arch = _: [
      "ca-certificates"
      "curl"
      "gnupg"
      "ttf-dejavu"
      "noto-fonts-emoji"
      "ttf-liberation"
      "mesa"
      "vulkan-intel"
      "vulkan-radeon"
      "libpipewire"
      "libpulse"
      "alsa-lib"
    ];

    fedora = _: [
      "ca-certificates"
      "curl"
      "gnupg2"
      "dejavu-sans-fonts"
      "google-noto-color-emoji-fonts"
      "liberation-sans-fonts"
      "mesa-dri-drivers"
      "mesa-vulkan-drivers"
      "mesa-libGL"
      "pipewire-libs"
      "pulseaudio-libs"
      "alsa-lib"
    ];

    alpine = _: [
      "ca-certificates"
      "curl"
      "gnupg"
      "ttf-dejavu"
      "font-noto-emoji"
      "ttf-liberation"
      "mesa-dri-gallium"
      "mesa-vulkan-intel"
      "mesa-vulkan-ati"
      "pipewire"
      "libpulse"
      "alsa-lib"
    ];

    opensuse = _: [
      "ca-certificates"
      "curl"
      "gpg2"
      "dejavu-fonts"
      "noto-coloremoji-fonts"
      "liberation-fonts"
      "Mesa"
      "Mesa-dri"
      "Mesa-vulkan-device-select"
      "libpipewire-0_3-0"
      "libpulse0"
      "libasound2"
    ];

    void = _: [
      "ca-certificates"
      "curl"
      "gnupg"
      "dejavu-fonts"
      "noto-fonts-emoji"
      "font-liberation-ttf"
      "MesaLib"
      "vulkan-loader"
      "pipewire"
      "libpulseaudio"
      "alsa-lib"
    ];

    custom = _: [ ];
  };

  # Essential systemd pre-init hooks to prevent permission/mount errors in rootless podman
  systemdMountHook = "mkdir -p /run/systemd/journal /run/systemd/seats /run/systemd/sessions /run/systemd/users /var/lib/systemd/coredump 2>/dev/null || true";

  debianTmpfilesDivertHook = "(dpkg-divert --local --rename --add /usr/bin/systemd-tmpfiles 2>/dev/null || true) && (ln -sf /bin/true /usr/bin/systemd-tmpfiles 2>/dev/null || true)";

  distroPreInitHooks = {
    debian = [
      systemdMountHook
      debianTmpfilesDivertHook
    ];
    ubuntu = [
      systemdMountHook
      debianTmpfilesDivertHook
    ];
    arch = [
      systemdMountHook
    ];
    fedora = [
      systemdMountHook
    ];
    alpine = [
      systemdMountHook
    ];
    opensuse = [
      systemdMountHook
    ];
    void = [
      systemdMountHook
    ];
    custom = [ ];
  };
in
{
  inherit detectDistro;

  getDistroBasePackages =
    {
      distro,
      deltaUpdates ? true,
    }:
    let
      pkgFn = distroPackages.${distro} or distroPackages.custom;
    in
    pkgFn { inherit deltaUpdates; };

  getDistroPreInitHooks =
    { distro }:
    distroPreInitHooks.${distro} or [ ];
}
