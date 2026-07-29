{
  pkgs,
  lib,
  selfLib,
  config,
  ...
}:

let
  xboreupSrc = pkgs.fetchFromGitHub {
    owner = "sxlmnwb";
    repo = "xBoreUp_Linux_Patch";
    rev = "aa35aab540994e9322e475a9967fd66200ec692e";
    hash = "sha256-mmofg4eJYHB1uq5aLoNRnrvNgLJ9RWEAs6+CKHqOZbs=";
  };

  patchFiles = [
    "0001-net-tcp-add-Google-BBR-v3-congestion-control-on-linu.patch"
    "0002-net-tcp-increase-TCP-write-buffer-limit-from-4MB-to-.patch"
    "0003-net-sock-increase-default-socket-buffer-size-by-4x.patch"
    "0004-sched-rate-limit-sched_yield-to-once-per-jiffy.patch"
    "0005-mm-raise-default-max_map_count-to-INT_MAX.patch"
    "0006-time-reduce-default-timer_slack_ns-from-50-s-to-50ns.patch"
    "0007-iommu-enable-posted-MSI-by-default.patch"
    "0008-sched-add-BORE-Scheduler-v6.8.0.patch"
    "0009-sched-add-POC-Selector-v2.6.3.patch"
    "0010-block-add-ADIOS-I-O-Scheduler-v3.2.0.patch"
    "0011-cpuidle-add-NAP-Governor-v0.5.0.patch"
    "0012-zram-add-LZ4KDR-compression-backend-v1.3.patch"
    "0013-sched-add-Cambyses-load-balancer-v0.6.0.patch"
    "0014-cpufreq-add-Reflex-Governor-v0.3.2.patch"
    "0015-mm-add-lru_marie-MARIE-LRU-v0.9.1.patch"
    "0016-lru_marie-add-AVX-512F-BW-BMI2-optimised-PTE-scanner.patch"
    "0017-scripts-setlocalversion-remove-tag-for-git-repo-shor.patch"
    "0018-kbuild-add-full-support-for-the-mold-linker.patch"
  ];

  customKernel = pkgs.linux_latest.override {
    kernelPatches = map (file: {
      name = file;
      patch = "${xboreupSrc}/${file}";
    }) patchFiles;
  };

  customKernelPackages = pkgs.linuxPackagesFor customKernel;
in
selfLib.mkModule {
  name = "core.kernel-xboreup";
  description = "Custom Linux kernel with xBoreUp patchset (BORE, BBRv3, MARIE LRU, ADIOS, etc.)";

  options = {
    package = lib.mkOption {
      type = lib.types.raw;
      default = customKernelPackages;
      description = "The customized kernel package set.";
    };
  };

  nixosConfig = { };
}
