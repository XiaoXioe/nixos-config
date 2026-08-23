# Preservation aspect type schema — extracted from mkModule for maintainability.
# Used only by mkModule when name == "hardware.preservation".
{ lib }:

let
  # Reusable type: preservation path entries can be plain strings or attrsets with options
  pathEntryType = lib.types.listOf (lib.types.either lib.types.str lib.types.attrs);
in
lib.types.submodule {
  options = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether this preservation aspect is enabled.";
    };
    rule = lib.mkOption {
      type = lib.types.submodule {
        options = {
          persist = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Force preservation even if module is disabled.";
          };
          cleanupOnDisable = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Clean up persisted directories when module is disabled.";
          };
          directories = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System directories to preserve (alias for systemDirectories).";
          };
          systemDirectories = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System directories to preserve.";
          };
          sysDirectories = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System directories to preserve (shorthand alias).";
          };
          userDirectories = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "User directories to preserve.";
          };
          files = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System files to preserve (alias for systemFiles).";
          };
          systemFiles = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System files to preserve.";
          };
          sysFiles = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "System files to preserve (shorthand alias).";
          };
          userFiles = lib.mkOption {
            type = pathEntryType;
            default = [ ];
            description = "User files to preserve.";
          };
        };
      };
      default = { };
      description = "Preservation rule definition.";
    };
  };
}
