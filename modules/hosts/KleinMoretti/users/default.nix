let
  identity = import ./identity.nix;
  appsFeatures = import ./features/apps.nix;
  systemFeatures = import ./features/system.nix;
in
identity
// {
  userFeatures = appsFeatures.userFeatures // systemFeatures.userFeatures;
}
