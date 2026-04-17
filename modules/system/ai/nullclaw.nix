{
  config,
  pkgs,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.nullclaw;

  # Derivation sederhana untuk mengambil static binary NullClaw
  nullclaw-pkg = pkgs.stdenv.mkDerivation rec {
    pname = "nullclaw";
    version = "2026.4.9";

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
    enable = selfLib.mkBoolOpt false "Nullclaw AI Agent";
  };

  config = lib.mkIf cfg.enable {
    # Memasukkan nullclaw ke dalam environment sistem agar bisa dipanggil via CLI
    environment.systemPackages = [ nullclaw-pkg ];

    # systemd.services.nullclaw = {
    #   description = "Nullclaw AI Agent Background Service";
    #   wantedBy = lib.mkForce [ ];
    #   bindsTo = [ "ollama.service" ];
    #   after = [ "ollama.service" ];

    #   serviceConfig = {
    #     # Menggunakan perintah gateway untuk stand-by di background (dibutuhkan nanti untuk Telegram/Discord)
    #     ExecStart = "${nullclaw-pkg}/bin/nullclaw gateway";
    #     Restart = "on-failure";
    #     User = "klein-moretti";
    #     # Set variabel environment agar NullClaw tahu lokasi home directory
    #     Environment = "HOME=/home/klein-moretti";
    #   };
    # };

    # # Trigger Ollama jika NullClaw dijalankan
    # systemd.services.ollama.wants = [ "nullclaw.service" ];

  };
}
