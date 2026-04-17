# lib/users.nix — Definisi semua user, fitur per-user, dan fitur sistem.
{
  # Daftar user yang akan diinstal di sistem
  users = {
    klein-moretti = {
      fullName = "Klein Moretti (admin)";
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
      ];
      openssh.authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
      ];
      userFeatures = {
        dms = true; # nix eval cpuTime 9 detik # "nrOpUpdateValuesCopied": 13266380 # "nrFunctionCalls": 2678499,
        caelestia = true;
        nvim = true; # tidak berpengaruh
        git = true; # tidak berpengaruh
        ssh = true; # tidak berpengaruh
        fish = true; # tidak berpengaruh
        tmux = true;
        startship = true;
        packages = true; # tidak berpengaruh
        custompkgs = true; # nix eval cpuTime 9 detik # "nrOpUpdateValuesCopied": 11016177 # "nrFunctionCalls": 2318893,
        editor_file = true; # nix eval cpuTime # nix eval cpuTime 5 detik # "nrOpUpdateValuesCopied": 6574315 # "nrFunctionCalls": 1207225, detik # "nrOpUpdateValuesCopied": 7776313 # "nrFunctionCalls": 1382354,
        securityTools = true; # nix eval cpuTime 5 detik # "nrOpUpdateValuesCopied": 6574315 # "nrFunctionCalls": 1207225,
        gaming = true; # nix eval cpuTime 9 detik # "nrOpUpdateValuesCopied": 17622108 # "nrFunctionCalls": 2810695,
        brave = true; # tidak berpengaruh
        media = true; # nix eval cpuTime 10 detik # "nrOpUpdateValuesCopied": 9318932 # "nrFunctionCalls": 2027849,
        music = true; # tidak berpengaruh
        sosmed = true; # nix eval cpuTime 5
        office = true; # nix eval cpuTime 4
        browser = true; # nix eval cpuTime 4
        firefox = true; # nix eval cpuTime 3
        distrobox = true; # tidak berpengaruh
        docker = true;
        settings = true;
        themes = true; # tidak berpengaruh

        services = {
          rclone = true;
        };
      };
    };

    #   Tamu = {
    #     fullName = "User Guests";
    #     uid = 1001;
    #     extraGroups = [
    #       "wheel"
    #       "networkmanager"
    #       "video"
    #       "audio"
    #       # "wireshark"
    #       "render"
    #       "i2c"
    #       "adbusers"
    #       "kvm"
    #     ];
    #     openssh.authorizedKeys.keys = [
    #       "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIZ9JzZzktDyRcOpqMyit78cS0xx7NRj7Mak89HjsRLR u0_a185@localhost"
    #     ];
    #     userFeatures = {
    #       dms = true; # nix eval cpuTime 9 detik # "nrOpUpdateValuesCopied": 13266380 # "nrFunctionCalls": 2678499,
    #       nvim = true; # tidak berpengaruh
    #       git = true; # tidak berpengaruh
    #       ssh = true; # tidak berpengaruh
    #       shell = true; # tidak berpengaruh
    #       packages = true; # tidak berpengaruh
    #     };
    #   };
  };
}

#### eval HM semua userFeatures off ####
# {
#   "cpuTime": 6.229806900024414,
#   "envs": {
#     "bytes": 36257160,
#     "elements": 2693308,
#     "number": 1838837
#   },
#   "gc": {
#     "cycles": 1,
#     "heapSize": 402915328,
#     "totalBytes": 307493536
#   },
#   "list": {
#     "bytes": 4501552,
#     "concats": 95419,
#     "elements": 562694
#   },
#   "nrAvoided": 2127693,
#   "nrExprs": 1030719,
#   "nrFunctionCalls": 1642938,
#   "nrLookups": 934350,
#   "nrOpUpdateValuesCopied": 8312483,
#   "nrOpUpdates": 159838,
#   "nrPrimOpCalls": 831556,
#   "nrThunks": 2446568,
#   "sets": {
#     "bytes": 174329728,
#     "elements": 10511530,
#     "number": 384078
#   },
#   "sizes": {
#     "Attr": 16,
#     "Bindings": 16,
#     "Env": 8,
#     "Value": 16
#   },
#   "symbols": {
#     "bytes": 877872,
#     "number": 79819
#   },
#   "time": {
#     "cpu": 6.229806900024414,
#     "gc": 0.013000000000000001,
#     "gcFraction": 0.002086742046522992
#   },
#   "values": {
#     "bytes": 60029360,
#     "number": 3751835
#   }
# }

#### eval HM semua userFeatures On ####
# {
#   "cpuTime": 49.25665283203125,
#   "envs": {
#     "bytes": 293944736,
#     "elements": 21963842,
#     "number": 14779250
#   },
#   "gc": {
#     "cycles": 7,
#     "heapSize": 1627652096,
#     "totalBytes": 2528426880
#   },
#   "list": {
#     "bytes": 44990272,
#     "concats": 869349,
#     "elements": 5623784
#   },
#   "nrAvoided": 18086245,
#   "nrExprs": 2234177,
#   "nrFunctionCalls": 13241466,
#   "nrLookups": 7093379,
#   "nrOpUpdateValuesCopied": 67638988,
#   "nrOpUpdates": 1364530,
#   "nrPrimOpCalls": 6976725,
#   "nrThunks": 20330964,
#   "sets": {
#     "bytes": 1470737072,
#     "elements": 88448763,
#     "number": 3472304
#   },
#   "sizes": {
#     "Attr": 16,
#     "Bindings": 16,
#     "Env": 8,
#     "Value": 16
#   },
#   "symbols": {
#     "bytes": 1092138,
#     "number": 95361
#   },
#   "time": {
#     "cpu": 49.25665283203125,
#     "gc": 1.4020000000000001,
#     "gcFraction": 0.028463160190379186
#   },
#   "values": {
#     "bytes": 478937456,
#     "number": 29933591
#   }
# }

# setiap menambahkan 1 paket unstable menambahkan 215907 nrFunctionCalls dan 966593 nrOpUpdateValuesCopied dan 2 detik
# intinnya setiap menambahkan paket dari unstable akan semakin berat eval
# menambah user tidak ada pengaruh ke eval
