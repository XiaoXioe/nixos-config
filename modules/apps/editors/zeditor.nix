{
  pkgs,
  selfLib,
  ...
}:

selfLib.mkModule {
  name = "apps.editors.zeditor";
  description = "Zed-editor configuration";

  hmConfig = {
    programs.zed-editor = {
      enable = true;
      package = pkgs.zed-editor-fhs;
      mutableUserSettings = false;
      mutableUserKeymaps = false;
      mutableUserTasks = false;
      extensions = [ "nix" "bash" "yaml" "html" "fish" "python" "catppuccin" "macos-classic" "catppuccin-icons" ];
      userSettings = {
        auto_update = false;
        buffer_font_family = "Adwaita Mono";
        telemetry = { diagnostics = false; metrics = false; };
        base_keymap = "SublimeText";
        ui_font_size = 16;
        buffer_font_size = 15;
        theme = { mode = "dark"; light = "One Light"; dark = "macOS Classic Dark"; };
        languages = {
          Nix = { format_on_save = "on"; formatter = { external = { command = "nixfmt"; }; }; };
          Python = { format_on_save = "on"; formatter = { external = { command = "black"; arguments = [ "-" ]; }; }; };
        };
      };
    };
  };
}
