# Shell enable-check helper — avoids 4× duplicated osConfig pattern.
_: {
  # Check if a shell is enabled for a specific compositor or globally.
  # Usage: selfLib.isShellEnabled osConfig "niri" "dms"
  #        selfLib.isShellEnabled osConfig "hyprland" "noctalia"
  isShellEnabled =
    osConfig: compositor: shell:
    let
      d = osConfig.my.desktop;
    in
    (d ? ${compositor} && d.${compositor} ? ${shell} && d.${compositor}.${shell}.enable)
    || (d ? shells && d.shells ? ${shell} && d.shells.${shell}.enable);
}
