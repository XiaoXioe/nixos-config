{ flakePath, ... }: {
  programs.fish.shellAliases = {

    ls = "eza --icons -l -T -L=1";

    cd = "z";
    cat = "bat";
    editnix = "codium ~/nixos-config";

    ".." = "cd ..";
    "..." = "cd ../..";

    c = "clear";

    sz = "sudo compsize -x";

    # --- SYSTEMD & JOURNALCTL ---
    sc = "sudo systemctl";
    scu = "systemctl --user";
    scstart = "sudo systemctl start";
    scstop = "sudo systemctl stop";
    screstart = "sudo systemctl restart";
    scstatus = "systemctl status";
    scfailed = "systemctl --failed";

    jc = "journalctl -xe";
    jcf = "journalctl -f";
    jcu = "journalctl --user -xe";
    jceu = "sudo journalctl -xeu";

    rebuild = "sudo nixos-rebuild switch --flake ${flakePath} --print-build-logs --show-trace";
    cln = "nh clean all --keep 3 --ask --optimise";
    gcp = "git add . && git commit -m 'update' && git push";
    nfu = "nix flake update --flake ${flakePath}";

    # --- ALIAS NIXOS SYSTEM ---
    osbuild = "nh os switch ${flakePath} --show-trace --diff auto --ask";
    ostest = "nh os test ${flakePath} --show-trace --diff auto --ask";
    osboot = "nh os boot ${flakePath} --show-trace --diff auto --ask";

    squeeze = "sudo btrfs filesystem defragment -r -v -czstd";
  };
}
