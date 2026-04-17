{
  config,
  pkgs,
  pkgsUnstable,
  lib,
  selfLib,
  ...
}:
let
  cfg = config.my.system.security-tools-system;
in
{
  options.my.system.security-tools-system = {
    enable = selfLib.mkBoolOpt false "cybersecurity and penetration testing tools for system";
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      aircrack-ng
      airgeddon
      android-tools
      tcpdump
      nmap
      ghauri
      apktool
      bettercap
      bully
      hashcat
      hcxdumptool
      mdk4
      metasploit
      pkgsUnstable.mtkclient
      pkgsUnstable.nuclei
      pkgsUnstable.nuclei-templates
      steghide
      stegsolve
      jq
      jadx
      torsocks
      wafw00f
      whatweb
      whois
      wifite2
      zsteg
      nikto
      recon-ng
      macchanger
      reaverwps-t6x
      pngcheck
      ghidra
    ];

    programs.firejail.enable = true;
  };
}
