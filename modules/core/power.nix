{ selfLib, ... }:
selfLib.mkModule {
  name = "core.power";
  nixosConfig = {
    powerManagement = {
      enable = true;
      cpuFreqGovernor = "schedutil";
    };
  };
}
