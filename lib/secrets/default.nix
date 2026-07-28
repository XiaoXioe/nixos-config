{
  lib,
  secret,
  secretBinary,
}:

{
  # Helper to resolve SOPS secret paths cleanly relative to Flake root
  sopsSecret = relPath: secret relPath;
  sopsSecretBinary = relPath: secretBinary relPath;

  # Declarative SOPS secret definition builder for single-user environment
  mkSecret =
    {
      key,
      owner ? "root",
      mode ? "0400",
      group ? null,
      sopsFile ? null,
      path ? null,
      format ? "yaml",
    }:
    {
      name = key;
      value = {
        inherit owner mode;
        key = key;
      }
      // (lib.optionalAttrs (sopsFile != null) { inherit sopsFile; })
      // (lib.optionalAttrs (path != null) { inherit path; })
      // (lib.optionalAttrs (format != "yaml") { inherit format; })
      // (lib.optionalAttrs (group != null) { inherit group; });
    };
}
