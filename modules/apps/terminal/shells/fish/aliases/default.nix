_: {
  programs = {
    bat.enable = true;
    fish.shellAliases = {
      ls = "eza --icons -l -T -L=1";

      cd = "z";
      cat = "bat";
      editnix = "codium ~/nixos-config";

      ".." = "cd ..";
      "..." = "cd ../..";

      c = "clear";

      sz = "sudo compsize -x";

      squeeze = "sudo btrfs filesystem defragment -r -v -czstd";

      mpv = "mpv-wrapper";
    };
  };
}
