let
  identity = import ./identity.nix;
  appsFeatures = import ./features/apps.nix;
  systemFeatures = import ./features/system.nix;

  recursiveMerge =
    lhs: rhs:
    lhs
    // rhs
    // (builtins.listToAttrs (
      builtins.concatMap (
        name:
        if builtins.isAttrs (lhs.${name} or null) && builtins.isAttrs (rhs.${name} or null) then
          [
            {
              inherit name;
              value = recursiveMerge lhs.${name} rhs.${name};
            }
          ]
        else
          [ ]
      ) (builtins.attrNames lhs)
    ));
in
identity
// {
  userFeatures = recursiveMerge appsFeatures.userFeatures systemFeatures.userFeatures;
}
