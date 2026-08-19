{
  config,
  lib,
  pkgs,
  selfLib,
  ...
}:

let
  cfg = config.my.virtualisation.distrobox-pkg;

  dboxPkgApp =
    selfLib.mkApp pkgs "dbox-pkg"
      ''
                set -euo pipefail

                show_help() {
                  cat << 'EOF'
        dbox-pkg - Unified package manager & container CLI for Distrobox

        Usage:
          dbox-pkg [OPTIONS] <ACTION|PACKAGE_MANAGER> [ARGS...]
          dbox-apt [ARGS...]
          dbox-pacman [ARGS...]
          dbox-dnf [ARGS...]
          dbox-apk [ARGS...]
          dbox-zypper [ARGS...]
          dbox-xbps [ARGS...]

        Universal Actions (auto-targets active container):
          install, add <pkgs...>    Install packages
          update, refresh           Update package database / indexes
          search <query>            Search for packages
          remove, rm <pkgs...>      Remove packages
          packages, pkgs, installed List installed packages in container
          show, info <pkg>          Show package metadata
          clean                     Clean package manager caches
          autoremove                Remove orphan/unused dependencies
          upgrade [container|--all] Upgrade container packages via native manager

        Direct Commands:
          containers, list          List active containers and their detected package managers
          enter [container]         Open interactive shell inside container
          apt, debdelta-upgrade     Execute inside Debian / Ubuntu container
          pacman, yay, paru         Execute inside Arch Linux container
          dnf, yum                  Execute inside Fedora / RHEL container
          apk                       Execute inside Alpine Linux container
          zypper                    Execute inside openSUSE container
          xbps, xbps-install        Execute inside Void Linux container

        Options:
          -c, --container NAME      Target specific container name
          -h, --help                Show this help message
        EOF
                }

                # Auto-detect invocation name (for symlink shortcuts)
                INVOKED_NAME="$(basename "$0")"
                case "$INVOKED_NAME" in
                  dbox-apt)
                    set -- "apt" "$@"
                    ;;
                  dbox-pacman)
                    set -- "pacman" "$@"
                    ;;
                  dbox-dnf)
                    set -- "dnf" "$@"
                    ;;
                  dbox-apk)
                    set -- "apk" "$@"
                    ;;
                  dbox-zypper)
                    set -- "zypper" "$@"
                    ;;
                  dbox-xbps)
                    set -- "xbps" "$@"
                    ;;
                esac

                # Helper to get list of existing containers: name|image
                get_containers() {
                  distrobox list --no-color 2>/dev/null | awk -F'|' 'NR>1 {
                    gsub(/^[ \t]+|[ \t]+$/, "", $2);
                    gsub(/^[ \t]+|[ \t]+$/, "", $4);
                    if ($2 != "") print $2 "|" $4
                  }' || true
                }

                detect_pkg_manager() {
                  local image="$1"
                  local lower_image
                  lower_image="$(echo "$image" | tr '[:upper:]' '[:lower:]')"

                  if [[ "$lower_image" == *"debian"* ]] || [[ "$lower_image" == *"ubuntu"* ]]; then
                    echo "apt"
                  elif [[ "$lower_image" == *"arch"* ]]; then
                    echo "pacman"
                  elif [[ "$lower_image" == *"fedora"* ]] || [[ "$lower_image" == *"ubi"* ]] || [[ "$lower_image" == *"centos"* ]] || [[ "$lower_image" == *"rocky"* ]] || [[ "$lower_image" == *"alma"* ]]; then
                    echo "dnf"
                  elif [[ "$lower_image" == *"alpine"* ]]; then
                    echo "apk"
                  elif [[ "$lower_image" == *"opensuse"* ]] || [[ "$lower_image" == *"tumbleweed"* ]] || [[ "$lower_image" == *"leap"* ]]; then
                    echo "zypper"
                  elif [[ "$lower_image" == *"void"* ]]; then
                    echo "xbps"
                  else
                    echo "unknown"
                  fi
                }

                # Parse options
                TARGET_CONTAINER=""
                while [[ $# -gt 0 ]]; do
                  case "$1" in
                    -c|--container)
                      TARGET_CONTAINER="$2"
                      shift 2
                      ;;
                    -h|--help)
                      show_help
                      exit 0
                      ;;
                    *)
                      break
                      ;;
                  esac
                done

                if [[ $# -eq 0 ]]; then
                  show_help
                  exit 0
                fi

                CMD="$1"
                shift

                # Handle built-in action: list containers (if no extra arguments are given)
                if [[ "$CMD" == "containers" || ( "$CMD" == "list" && $# -eq 0 ) ]]; then
                  echo "=== Active Distrobox Containers ==="
                  printf "%-20s %-15s %-40s\n" "CONTAINER" "PKG MANAGER" "BASE IMAGE"
                  echo "-------------------------------------------------------------------------------"
                  while IFS='|' read -r c_name c_image; do
                    [[ -z "$c_name" ]] && continue
                    pkg_m="$(detect_pkg_manager "$c_image")"
                    printf "%-20s %-15s %-40s\n" "$c_name" "$pkg_m" "$c_image"
                  done < <(get_containers)
                  exit 0
                fi

                # Handle built-in action: enter
                if [[ "$CMD" == "enter" ]]; then
                  if [[ -n "$TARGET_CONTAINER" ]]; then
                    exec distrobox enter "$TARGET_CONTAINER" "$@"
                  elif [[ $# -ge 1 ]]; then
                    target="$1"
                    shift
                    exec distrobox enter "$target" "$@"
                  else
                    containers=()
                    while IFS='|' read -r c_name _; do
                      [[ -n "$c_name" ]] && containers+=("$c_name")
                    done < <(get_containers)

                    if [[ ''${#containers[@]} -eq 0 ]]; then
                      echo "Error: No Distrobox containers found." >&2
                      exit 1
                    elif [[ ''${#containers[@]} -eq 1 ]]; then
                      exec distrobox enter "''${containers[0]}"
                    else
                      echo "Multiple containers found. Please specify one:" >&2
                      for c in "''${containers[@]}"; do
                        echo "  - $c" >&2
                      done
                      exit 1
                    fi
                  fi
                fi

                # Handle built-in action: upgrade
                if [[ "$CMD" == "upgrade" ]]; then
                  if [[ "$#" -gt 0 && "$1" == "--all" ]]; then
                    exec distrobox upgrade --all
                  elif [[ -n "$TARGET_CONTAINER" ]]; then
                    exec distrobox upgrade "$TARGET_CONTAINER"
                  elif [[ $# -ge 1 ]]; then
                    exec distrobox upgrade "$1"
                  else
                    exec distrobox upgrade --all
                  fi
                fi

                # Determine if CMD is a universal action or explicit package manager
                GENERIC_ACTION=""
                PKG_TYPE=""
                case "$CMD" in
                  install|add|in)
                    GENERIC_ACTION="install"
                    ;;
                  update|up|refresh|ref)
                    GENERIC_ACTION="update"
                    ;;
                  search|find|query)
                    GENERIC_ACTION="search"
                    ;;
                  remove|rm|delete|del|purge)
                    GENERIC_ACTION="remove"
                    ;;
                  packages|pkgs|installed)
                    GENERIC_ACTION="packages"
                    ;;
                  show|info)
                    GENERIC_ACTION="show"
                    ;;
                  clean|autoclean)
                    GENERIC_ACTION="clean"
                    ;;
                  autoremove)
                    GENERIC_ACTION="autoremove"
                    ;;
                  list) # list with arguments (e.g. list --installed)
                    GENERIC_ACTION="list"
                    ;;
                  apt|debdelta-upgrade|dpkg)
                    PKG_TYPE="apt"
                    ;;
                  pacman|yay|paru)
                    PKG_TYPE="pacman"
                    ;;
                  dnf|yum)
                    PKG_TYPE="dnf"
                    ;;
                  apk)
                    PKG_TYPE="apk"
                    ;;
                  zypper)
                    PKG_TYPE="zypper"
                    ;;
                  xbps|xbps-install|xbps-query|xbps-remove)
                    PKG_TYPE="xbps"
                    ;;
                  *)
                    PKG_TYPE="generic"
                    ;;
                esac

                # Resolve target container & its image
                RESOLVED_CONTAINER="$TARGET_CONTAINER"
                RESOLVED_IMAGE=""
                matching_containers=()
                matching_images=()
                all_containers=()
                all_images=()

                while IFS='|' read -r c_name c_image; do
                  [[ -z "$c_name" ]] && continue
                  all_containers+=("$c_name")
                  all_images+=("$c_image")
                  detected="$(detect_pkg_manager "$c_image")"
                  if [[ -n "$PKG_TYPE" && "$PKG_TYPE" != "generic" && "$detected" == "$PKG_TYPE" ]]; then
                    matching_containers+=("$c_name")
                    matching_images+=("$c_image")
                  fi
                  if [[ -n "$TARGET_CONTAINER" && "$c_name" == "$TARGET_CONTAINER" ]]; then
                    RESOLVED_IMAGE="$c_image"
                  fi
                done < <(get_containers)

                if [[ -z "$RESOLVED_CONTAINER" ]]; then
                  if [[ -n "$GENERIC_ACTION" ]]; then
                    # For generic actions, pick the single container if only 1 exists
                    if [[ ''${#all_containers[@]} -eq 1 ]]; then
                      RESOLVED_CONTAINER="''${all_containers[0]}"
                      RESOLVED_IMAGE="''${all_images[0]}"
                    elif [[ ''${#all_containers[@]} -eq 0 ]]; then
                      echo "Error: No Distrobox containers found." >&2
                      exit 1
                    else
                      echo "Multiple containers found: ''${all_containers[*]}" >&2
                      echo "Please specify target container using: dbox-pkg -c <container> $CMD $*" >&2
                      exit 1
                    fi
                  else
                    # For specific package managers (apt, pacman, etc.)
                    if [[ ''${#matching_containers[@]} -eq 1 ]]; then
                      RESOLVED_CONTAINER="''${matching_containers[0]}"
                      RESOLVED_IMAGE="''${matching_images[0]}"
                    elif [[ ''${#matching_containers[@]} -gt 1 ]]; then
                      echo "Multiple ''${PKG_TYPE} containers found: ''${matching_containers[*]}" >&2
                      echo "Please specify one using: dbox-pkg -c <container> $CMD $*" >&2
                      exit 1
                    elif [[ ''${#all_containers[@]} -eq 1 ]]; then
                      RESOLVED_CONTAINER="''${all_containers[0]}"
                      RESOLVED_IMAGE="''${all_images[0]}"
                    else
                      if [[ ''${#all_containers[@]} -eq 0 ]]; then
                        echo "Error: No Distrobox containers found." >&2
                      else
                        echo "Error: No container found matching package manager '$CMD'." >&2
                        echo "Available containers: ''${all_containers[*]}" >&2
                      fi
                      exit 1
                    fi
                  fi
                fi

                # Detect package manager for resolved container if image wasn't found in loop
                if [[ -z "$RESOLVED_IMAGE" ]]; then
                  for i in "''${!all_containers[@]}"; do
                    if [[ "''${all_containers[$i]}" == "$RESOLVED_CONTAINER" ]]; then
                      RESOLVED_IMAGE="''${all_images[$i]}"
                      break
                    fi
                  done
                fi

                CONTAINER_PKG_MANAGER="$(detect_pkg_manager "$RESOLVED_IMAGE")"

                # Translate generic action into native container command
                FINAL_CMD=()
                USE_SUDO=false

                if [[ -n "$GENERIC_ACTION" ]]; then
                  case "$CONTAINER_PKG_MANAGER" in
                    apt)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(apt update); USE_SUDO=true ;;
                        install)    FINAL_CMD=(apt install); USE_SUDO=true ;;
                        search)     FINAL_CMD=(apt search); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(apt remove); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(apt list --installed); USE_SUDO=false ;;
                        list)       FINAL_CMD=(apt list); USE_SUDO=false ;;
                        show)       FINAL_CMD=(apt show); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(apt clean); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(apt autoremove); USE_SUDO=true ;;
                      esac
                      ;;
                    pacman)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(pacman -Sy); USE_SUDO=true ;;
                        install)    FINAL_CMD=(pacman -S); USE_SUDO=true ;;
                        search)     FINAL_CMD=(pacman -Ss); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(pacman -Rns); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(pacman -Q); USE_SUDO=false ;;
                        list)       FINAL_CMD=(pacman -Q); USE_SUDO=false ;;
                        show)       FINAL_CMD=(pacman -Si); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(pacman -Sc); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(pacman -Rns "$(pacman -Qdtq 2>/dev/null)"); USE_SUDO=true ;;
                      esac
                      ;;
                    dnf)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(dnf check-update); USE_SUDO=false ;;
                        install)    FINAL_CMD=(dnf install); USE_SUDO=true ;;
                        search)     FINAL_CMD=(dnf search); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(dnf remove); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(dnf list installed); USE_SUDO=false ;;
                        list)       FINAL_CMD=(dnf list); USE_SUDO=false ;;
                        show)       FINAL_CMD=(dnf info); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(dnf clean all); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(dnf autoremove); USE_SUDO=true ;;
                      esac
                      ;;
                    apk)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(apk update); USE_SUDO=true ;;
                        install)    FINAL_CMD=(apk add); USE_SUDO=true ;;
                        search)     FINAL_CMD=(apk search); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(apk del); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(apk info); USE_SUDO=false ;;
                        list)       FINAL_CMD=(apk list); USE_SUDO=false ;;
                        show)       FINAL_CMD=(apk info); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(apk cache clean); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(apk cache clean); USE_SUDO=true ;;
                      esac
                      ;;
                    zypper)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(zypper refresh); USE_SUDO=true ;;
                        install)    FINAL_CMD=(zypper install); USE_SUDO=true ;;
                        search)     FINAL_CMD=(zypper search); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(zypper remove); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(zypper search --installed-only); USE_SUDO=false ;;
                        list)       FINAL_CMD=(zypper search); USE_SUDO=false ;;
                        show)       FINAL_CMD=(zypper info); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(zypper clean); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(zypper packages --unneeded); USE_SUDO=true ;;
                      esac
                      ;;
                    xbps)
                      case "$GENERIC_ACTION" in
                        update)     FINAL_CMD=(xbps-install -S); USE_SUDO=true ;;
                        install)    FINAL_CMD=(xbps-install); USE_SUDO=true ;;
                        search)     FINAL_CMD=(xbps-query -Rs); USE_SUDO=false ;;
                        remove)     FINAL_CMD=(xbps-remove); USE_SUDO=true ;;
                        packages)   FINAL_CMD=(xbps-query -l); USE_SUDO=false ;;
                        list)       FINAL_CMD=(xbps-query -l); USE_SUDO=false ;;
                        show)       FINAL_CMD=(xbps-query -R); USE_SUDO=false ;;
                        clean)      FINAL_CMD=(xbps-remove -O); USE_SUDO=true ;;
                        autoremove) FINAL_CMD=(xbps-remove -o); USE_SUDO=true ;;
                      esac
                      ;;
                    *)
                      FINAL_CMD=("$CMD")
                      ;;
                  esac
                else
                  FINAL_CMD=("$CMD")
                  # Determine if sudo should be used for explicit commands
                  case "$CMD" in
                    apt)
                      if [[ $# -gt 0 ]]; then
                        case "$1" in
                          install|remove|purge|update|upgrade|dist-upgrade|full-upgrade|autoremove|clean|autoclean)
                            USE_SUDO=true
                            ;;
                        esac
                      fi
                      ;;
                    debdelta-upgrade)
                      USE_SUDO=true
                      ;;
                    pacman)
                      if [[ $# -gt 0 ]]; then
                        case "$1" in
                          -S|-Syu|-Sy|-Syy|-Syyu|-R|-Rns|-Rs|-U)
                            USE_SUDO=true
                            ;;
                        esac
                      fi
                      ;;
                    dnf|yum)
                      if [[ $# -gt 0 ]]; then
                        case "$1" in
                          install|remove|upgrade|update|reinstall|autoremove|clean)
                            USE_SUDO=true
                            ;;
                        esac
                      fi
                      ;;
                    apk)
                      if [[ $# -gt 0 ]]; then
                        case "$1" in
                          add|del|update|upgrade|fix)
                            USE_SUDO=true
                            ;;
                        esac
                      fi
                      ;;
                    zypper)
                      if [[ $# -gt 0 ]]; then
                        case "$1" in
                          install|in|remove|rm|update|up|dist-upgrade|dup|refresh|ref)
                            USE_SUDO=true
                            ;;
                        esac
                      fi
                      ;;
                    xbps-install|xbps-remove)
                      USE_SUDO=true
                      ;;
                  esac
                fi

                echo "==> Executing in container [$RESOLVED_CONTAINER] ($CONTAINER_PKG_MANAGER): ''${FINAL_CMD[*]} $*"
                if [[ "$USE_SUDO" == "true" ]]; then
                  exec distrobox enter "$RESOLVED_CONTAINER" -- sudo "''${FINAL_CMD[@]}" "$@"
                else
                  exec distrobox enter "$RESOLVED_CONTAINER" -- "''${FINAL_CMD[@]}" "$@"
                fi
      ''
      [
        pkgs.distrobox
        pkgs.coreutils
        pkgs.gnugrep
        pkgs.gawk
      ];

  # Bundle dbox-pkg with standalone executable symlinks in $out/bin
  dboxPkgPackage = pkgs.runCommand "dbox-pkg-tools" { } ''
    mkdir -p $out/bin
    ln -s ${dboxPkgApp} $out/bin/dbox-pkg
    ln -s ${dboxPkgApp} $out/bin/dbox
    ln -s ${dboxPkgApp} $out/bin/dbox-apt
    ln -s ${dboxPkgApp} $out/bin/dbox-pacman
    ln -s ${dboxPkgApp} $out/bin/dbox-dnf
    ln -s ${dboxPkgApp} $out/bin/dbox-apk
    ln -s ${dboxPkgApp} $out/bin/dbox-zypper
    ln -s ${dboxPkgApp} $out/bin/dbox-xbps
  '';
in
selfLib.mkModule {
  name = "virtualisation.distrobox-pkg";
  description = "Native host CLI tool and package manager shortcuts for Distrobox containers";

  options = {
    enableShortcuts = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Enable native shell aliases (dbox, dbox-apt, dbox-pacman, dbox-dnf, dbox-apk, dbox-zypper, dbox-xbps).";
    };
  };

  nixosConfig = {
    environment.systemPackages = [
      dboxPkgPackage
    ];

    # Native NixOS shell aliases across all shells (Fish, Bash, Zsh)
    environment.shellAliases = lib.mkIf cfg.enableShortcuts {
      dbox = "dbox-pkg";
      dbox-apt = "dbox-pkg apt";
      dbox-pacman = "dbox-pkg pacman";
      dbox-dnf = "dbox-pkg dnf";
      dbox-apk = "dbox-pkg apk";
      dbox-zypper = "dbox-pkg zypper";
      dbox-xbps = "dbox-pkg xbps-install";
    };
  };
}
