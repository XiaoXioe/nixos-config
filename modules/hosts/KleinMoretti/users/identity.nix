{
  userName = "klein-moretti";
  fullName = "Klein Moretti";
  defaultApps = {
    terminal = "foot";
    browser = "zen-beta";
    editor = "codium";
    fileManager = "dolphin";
  };
  uid = 1000;
  extraGroups = [
    "wheel"
    "networkmanager"
    "video"
    "audio"
    "wireshark"
    "render"
    "i2c"
    "adbusers"
    "kvm"
    "dialout"
    "uucp"
  ];
  openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEcEPafkivvHuS2FPHTQrlXvs/AEVkKE82V6hnIpAtRU klein-moretti@KleinMoretti"
  ];
}
