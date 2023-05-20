# link files like
# - dot-config-test.sh -> ~/.config/test.sh
# dot-*-*|dotconfig-*-*|bin-*-*|config-*-*|inc-*-*)
#
# ./install-dash.sh ~/
# bin-files
# dot-files
# *-files
#
# LINKPOOL is a volountary directory that contains all the symlinks

USAGE='[sourcdir] <targetdir> [linkpool]'

set -eu

die() {
   echo "$@" 1>&2
   exit 1
}

HOME_LOCAL="$HOME/.local"
LIB_DIR="$HOME_LOCAL/lib"

SOURCE_DIR=
LINKPOOL_DIR=

case "$#" in
2)
   SOURCE_DIR="${1}"
   LINKPOOL_DIR="${2}"
   ;;
1)
   SOURCE_DIR="$PWD"
   LINKPOOL_DIR="${1}"
   ;;
*)
   die "usage: $USAGE"
   ;;
esac

BASELIB=
if [ -f "$PWD"/local-files/lib-baselib.sh ]; then
   BASELIB="$PWD"/local-files/lib-baselib.sh
elif [ -f "$LIB_DIR"/baselib.sh ]; then
   BASELIB="$LIB_DIR"/baselib.sh
else
   die "Err: could not load baselib"
fi

. "$BASELIB" || die "Err: something wrong with sourcing baselib"

try_link_to_linkpool() {
   local filepath="$1"
   local endfile="$2"

   local bname=$(basename "$filepath")

   if [ -n "$LINKPOOL_DIR" ] && [ -d "$LINKPOOL_DIR" ]; then
      baselib__item_to_target 'ln' "$filepath" "$LINKPOOL_DIR" "$endfile"
      baselib__item_to_target 'ln' "$filepath" "$LINKPOOL_DIR" "$bname"
   fi
}

link_dashfile() {
   local filepath="$1"
   local filename="$2"
   local targetdir="$3"
   local dot="${4:-}"

   mkdir -p "$targetdir"

   local endfile=

   case "$filename" in
   *-*)
      endfile=${filename##*-}

      local file_dirpart=${filename%-*}

      local dirname=$(echo "$file_dirpart" | perl -pe 's/\-/\//g')

      local filedir="$targetdir/$dot$dirname"

      mkdir -p "$filedir"

      baselib__item_to_target 'ln' "$filepath" "$filedir" "$endfile"
      try_link_to_linkpool "$filepath" "$endfile"
      ;;
   *)
      endfile="$dot$filename"
      baselib__item_to_target 'ln' "$filepath" "$targetdir" "$endfile"
      try_link_to_linkpool "$filepath" "$endfile"
      ;;
   esac

   if [ -d "$LINKPOOL_DIR" ]; then
      local linkpool_file=$LINKPOOL_DIR/$dot$endfile
      rm -f $linkpool_file
      ln -s $filepath $linkpool_file
   fi
}

install_in_dashdir() {
   local source_dir="$1"
   local target_dir="$2"
   local dot="${3:-}"

   [ -d "$source_dir" ] || die "Err: source dir not exists"
   [ -d "$target_dir" ] || mkdir -p "$target_dir"
   [ -d "$target_dir" ] || die "Err: no target dir for sourcedir '$source_dir'"

   for i in "$source_dir"/*; do
      [ -e "$i" ] || continue
      bi=$(basename "$i")
      if [ -d "$i" ]; then
         case "$bi" in
         *-files) die "Err: no dotfile in a subfolder please" ;;
         *)
            local dirpath=$(echo "$bi" | perl -pe 's/\-/\//g')
            local entire_path=$target_dir/$dot$dirpath
            [ -d "$entire_path" ] || mkdir -p "$entire_path"
            install_in_dashdir "$i" "$entire_path"
            ;;
         esac
      elif [ -f "$i" ]; then
         link_dashfile "$i" "$bi" "$target_dir" "$dot"
      fi
   done

   local target_base="$(basename $target_dir)"
   try_link_to_linkpool "$target_dir" "$target_base"
   case "$target_base" in
   .*)
      local nondot=$(echo "$target_base" | perl -pe 's/^\.//g')
      try_link_to_linkpool "$target_dir" "$nondot"
      ;;
   *) : ;;
   esac

}

install_dash() {
   local source_dir="$1"

   for dir in "$source_dir"/*; do
      [ -d "$dir" ] || continue
      basedir=$(basename "$dir")
      case "$basedir" in
         *_dot-link|*-dot-link|dot-link)
            die "Err: invalid dash dirs dot-link '$basedir'"
            ;;
         *_dot-files|*-dot-files)
            die "Err: invalid dash dirs dot-files '$basedir'"
            ;;
         *_*_*-link|*_*-*-files)
            die "Err: invalid dash dirs"
            ;;
         dot-files)
            install_in_dashdir "$dir" "$HOME" '.'
            ;;
         *-link|*-files) # foo-bar_config-files ~/.config/foo/bar qux_baba-files -> ~/.baba/qux
            local dash_part=${basedir##*_}
            case "$dash_part" in
               *-*-*) die "Err: invalid dash part in $dash_part" ;;
               *) : ;;
            esac
            local dot_dir="${dash_part%-*}"
            local home_dot_dir=$HOME/.$dot_dir

            local dir_part=${basedir%_*}
            local target_dir=
            if [ "$dir_part" = "$dash_part" ] ; then # no '_' delimiter
               target_dir="$home_dot_dir"
            else
               case "$dir_part" in
               *-*)
                  local middle_dir=$(perl -e 'print(join("/",reverse(split("-", $ARGV[0])))' "$dir_part")
                  target_dir=$home_dot_dir/$middle_dir
               ;;
               *)
                  target_dir=$home_dot_dir/$dir_part
               ;;
               esac
            fi

            local target_dir_parent=$(dirname "$target_dir")
            mkdir -p "$target_dir_parent"

            local dash_type="${dash_part##*-}"

            case "$dash_type" in
               link) 
                  if [ -e "$target_dir" ] ; then
                     [ -L "$target_dir" ] || die "Err: target $target_dir not a link"
                        rm -f "$target_dir"
                  fi
                     ln -s "$dir" "$target_dir"
                  ;;
               files) 
                  install_in_dashdir "$dir" "$target_dir"
                  ;;
               *)
                  die "Err: wrong type '$dash_type'"
            esac
            ;;
         *) 
            :
            ;;
      esac
   done
}



install_dash "$SOURCE_DIR"



##### Linking stuff to the linkpool, or leave

[ -n "$LINKPOOL_DIR" ] && [ -d "$LINKPOOL_DIR" ] || exit

LOCAL_SHARE="$HOME_LOCAL/share"
mkdir -p "$LOCAL_SHARE"

PWDBASE=$(basename $PWD)

rm -f "$LOCAL_SHARE/$PWDBASE"
ln -s "$PWD" "$LOCAL_SHARE/$PWDBASE"

rm -f "$LINKPOOL_DIR"/"$PWDBASE"
ln -s "$PWD" "$LINKPOOL_DIR"/"$PWDBASE"

for d in "$HOME"/*; do
   [ -d "$d" ] || continue
   bd=$(basename "$d")
   case "$bd" in
      [A-Z]*)
         rm -f "$LINKPOOL_DIR"/"$bd"
         ln -s "$d" "$LINKPOOL_DIR"/"$bd"
         ;;
      *) : ;;
   esac
done


for bd in '.config' '.cache' '.local' 'builds' 'local' 'hacks' 'dev' 'src' 'sources'; do
   d="$HOME/$bd"
   [ -d "$d" ] || continue
   rm -f "$LINKPOOL_DIR"/"$bd"
   ln -s "$d" "$LINKPOOL_DIR"/"$bd"
done

homebase=$HOME/base
if [ -d "$homebase" ] ; then
   rm -f "$LINKPOOL_DIR"/"base"
   ln -s "$homebase" "$LINKPOOL_DIR"/"base"
   for d in "$homebase"/*; do
      [ -d "$d" ] || continue
      bd=$(basename "$d")
      rm -f "$LINKPOOL_DIR"/"$bd"
      ln -s "$d" "$LINKPOOL_DIR"/"$bd"
   done
fi


