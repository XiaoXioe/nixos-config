{
  userName,
  hostName,
  fullName,
  flakePath,
  allUsers,
  lib,
  ...
}:
let
  hasFeature =
    path:
    lib.any (
      user:
      let
        attrPath = lib.splitString "." path;
        value = lib.attrByPath attrPath false user.userFeatures;
      in
      value == true || (builtins.isAttrs value && value.enable == true)
    ) (lib.attrValues allUsers);
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  my = {
    hostname = hostName;
    users = allUsers;
    user = {
      name = userName;
      fullName = fullName;
      flakePath = flakePath;
    };

    ai = {
      llama.enable = hasFeature "ai.llama";
      ollama.enable = hasFeature "ai.ollama";
      open-webui.enable = hasFeature "ai.open-webui";
    };

    desktop = {
      kde.enable = true;
      niri.enable = true;
      gnome.enable = false;
      greeter.enable = true;
    };

    core = {
      nix.enable = hasFeature "core.nix";
      pipewire = {
        enable = hasFeature "core.pipewire.enable";
        pipewireEffects = {
          perfectEq.enable = hasFeature "core.pipewire.pipewireEffects.perfectEq";
          autogain.enable = hasFeature "core.pipewire.pipewireEffects.autogain";
        };
      };
      fonts.enable = hasFeature "core.fonts";
      locale.enable = hasFeature "core.locale";
      packages.enable = hasFeature "core.packages";
      graphics.enable = hasFeature "core.graphics";
      bootloader.enable = hasFeature "core.bootloader";
      environment.enable = hasFeature "core.environment";
      optimizations.enable = hasFeature "core.optimizations";
    };

    services = {
      core.enable = true;
      tmpfiles.enable = hasFeature "services.tmpfiles";
      networking = {
        dns.enable = hasFeature "services.networking.dns";
        vpn.enable = hasFeature "services.networking.vpn";
        openssh.enable = true;
      };

      scheduling = {
        ananicy.enable = hasFeature "services.scheduling.ananicy";
        snapper.enable = hasFeature "services.scheduling.snapper";
        ssd-monitor.enable = hasFeature "services.scheduling.ssd-monitor";
      };
      boot-speedup.enable = hasFeature "services.boot-speedup";
    };

    virtualisation = {
      waydroid.enable = hasFeature "virtualisation.waydroid";
      packages.enable = hasFeature "virtualisation.packages";
      docker = {
        enable = hasFeature "virtualisation.docker";
        autoUpdate = true;
        mt5.enable = false;
        "9router".enable = true;
      };
    };

    hardware = {
      auto-mount.enable = true;
      preservation.enable = true;
    };

    security = {
      gnupg.enable = hasFeature "security.gnupg";
      compat.enable = hasFeature "security.compat";
      pentest.enable = hasFeature "security.pentest";
      wrappers.enable = true;
      secrets.enable = true;
      packages.enable = true;
      hardening.enable = true;
      networking.enable = true;
    };

    specialization = {
      daily.enable = false;
      retro-gaming.enable = false;
    };
  };

  system.stateVersion = "25.11";
}
