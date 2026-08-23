{ pkgs, lib }:

let
  mkUnwrapped = import ./unwrapped.nix { inherit pkgs lib; };
  fetchUnpacked = import ./fetch-unpacked.nix { inherit pkgs lib; };
  mkWrapped = import ./wrapper.nix { inherit pkgs lib; };
  appVersionsData = import ../../apps-versions.nix;
in
{
  inherit mkUnwrapped fetchUnpacked mkWrapped;

  mkNativeApp =
    args@{
      pname ? args.name,
      name ? pname,
      isFOD ? args.useFOD or false,
      isDesktop ? true,
      ...
    }:
    let
      appInfo = appVersionsData.${name} or { };
      version = args.version or (appInfo.version or "latest");
      fodHash = args.unpackedHash or (args.hash or (appInfo.unpackedHash or appInfo.hash));

      unpackedFod = fetchUnpacked (
        {
          inherit pname isDesktop version;
          url = args.url or appInfo.url;
          hash = fodHash;
          extraPostUnpack = args.extraPostUnpack or "";
        }
        // (args.fodArgs or { })
      );

      defaultSrc =
        if (appInfo ? url && appInfo ? hash) then
          pkgs.fetchurl {
            inherit (appInfo) url hash;
          }
        else
          null;

      src = args.src or defaultSrc;

      unwrapped =
        if (args ? unwrapped) then
          args.unwrapped
        else if isFOD then
          unpackedFod
        else
          mkUnwrapped (
            args
            // {
              inherit
                pname
                name
                version
                src
                isDesktop
                ;
            }
          );

      wrapped = mkWrapped (
        args
        // {
          inherit
            pname
            name
            version
            unwrapped
            isDesktop
            ;
        }
      );
    in
    wrapped;
}
