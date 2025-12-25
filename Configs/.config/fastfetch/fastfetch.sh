if [ -z "${*}" ]; then
  clear
  exec fastfetch --logo-type kitty
  exit
fi

USAGE() {
  cat <<USAGE
Usage: fastfetch [commands] [options]

commands:
  logo    Display a random logo

options:
  -h, --help,     Display command's help message

USAGE
}

confDir="${XDG_CONFIG_HOME:-$HOME/.config}"
image_dirs=()

case $1 in
logo) # eats around 13 ms
  random() {
    (
      image_dirs+=("${confDir}/fastfetch/logo")
      [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
      # also .bash_logout may be matched with this find
      find -L "${image_dirs[@]}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wall.set*" ! -path "*/wallpapers/*.png" 2>/dev/null
    ) | shuf -n 1
  }
  help() {
    cat <<HELP
Usage: ${0##*/} logo [option]

options:
  --quad    Display a quad wallpaper logo
  --sqre    Display a square wallpaper logo
  --prof    Display your profile picture (~/.face.icon)
  --os      Display the distro logo
  --local   Display a logo inside the fastfetch logo directory
  --wall    Display a logo inside the wallbash fastfetch directory
  --theme   Display a logo inside the hyde theme directory
  --rand    Display a random logo
  *         Display a random logo
  *help*    Display this help message

Note: Options can be combined to search across multiple sources
Example: ${0##*/} logo --local --os --prof
HELP
  }

  shift
  [ -z "${*}" ] && random && exit
  [[ "$1" = "--rand" ]] && random && exit
  [[ "$1" = *"help"* ]] && help && exit
  (
    image_dirs=()
    for arg in "$@"; do
      case $arg in
      --prof)
        [ -f "$HOME/.face.icon" ] && image_dirs+=("$HOME/.face.icon")
        ;;
      --local)
        image_dirs+=("${confDir}/fastfetch/logo")
        ;;
      esac
    done
    find -L "${image_dirs[@]}" -maxdepth 1 -type f \( -name "wall.quad" -o -name "wall.sqre" -o -name "*.icon" -o -name "*logo*" -o -name "*.png" \) ! -path "*/wall.set*" ! -path "*/wallpapers/*.png" 2>/dev/null
  ) | shuf -n 1

  ;;
--select | -S)
  :

  ;;
help | --help | -h)
  USAGE
  ;;
*)
  clear
  exec fastfetch --logo-type kitty
  ;;
esac
