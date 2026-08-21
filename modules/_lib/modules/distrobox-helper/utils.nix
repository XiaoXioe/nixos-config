_:

{
  # Merges camelCase + snake_case aliases into canonical field names so all
  # downstream logic (mkDistroboxContainers, mergeDistroboxContainers,
  # mkDistroboxPackagesList) works uniformly without per-field `++` duplication.
  # Applied at the top of every cVal iteration.
  normalizeCval =
    cVal:
    cVal
    // {
      packages = cVal.packages ++ cVal.additional_packages;
      aurPackages = cVal.aurPackages ++ cVal.aur;
      preInitHooks = cVal.preInitHooks ++ cVal.pre_init_hooks;
      initHooks = cVal.initHooks ++ cVal.init_hooks;
      exportedApps = cVal.exportedApps ++ cVal.exported_apps;
      exportedBins = cVal.exportedBins ++ cVal.exported_bins;
      volumes = cVal.volumes ++ cVal.volume;
      additionalFlags = cVal.additionalFlags ++ cVal.additional_flags;
      startNow = cVal.startNow || cVal.start_now;
    };
}
