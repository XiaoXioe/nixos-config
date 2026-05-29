{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.my.system.nullclaw;

  # Simple derivation to fetch the NullClaw static binary
  nullclaw-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "nullclaw";
    version = "2026.4.17";

    src = pkgs.fetchurl {
      url = "https://github.com/nullclaw/nullclaw/releases/download/v${version}/nullclaw-linux-x86_64.bin";

      sha256 = "sha256-4O3mt+mixwqOd1/RSDhV/cik5WG4zod5G/657n5mOlM=";
    };

    dontUnpack = true;

    installPhase = ''
      mkdir -p $out/bin
      cp $src $out/bin/nullclaw
      chmod +x $out/bin/nullclaw
    '';
  };

in
{
  options.my.system.nullclaw = {
    enable = lib.mkEnableOption "Nullclaw AI Agent";
  };

  config = lib.mkIf cfg.enable {
    # Add nullclaw to system environment
    environment.systemPackages = [ nullclaw-pkg ];

    # systemd.services.nullclaw = {
    #   description = "Nullclaw AI Agent Background Service";
    #   wantedBy = lib.mkForce [ ];
    #   bindsTo = [ "ollama.service" ];
    #   after = [ "ollama.service" ];

    #   serviceConfig = {
    #     # Use gateway command for background standby (needed for Telegram/Discord)
    #     ExecStart = "${nullclaw-pkg}/bin/nullclaw gateway";
    #     Restart = "on-failure";
    #     User = "klein-moretti";
    #     # Set environment variable for NullClaw home directory
    #     Environment = "HOME=/home/klein-moretti";
    #   };
    # };

    # # Trigger Ollama jika NullClaw dijalankan
    # systemd.services.ollama.wants = [ "nullclaw.service" ];

  };
}
