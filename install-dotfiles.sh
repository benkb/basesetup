# link files like
# config-files -> .config/
# cache-files -> .cache/
# local-files -> .local/
# else: -> .local/foo/

USAGE='[sourcdir] <targetdir> '

set -eu

die() {
   echo "$@" 1>&2
   exit 1
}

HOME_LOCAL="$HOME/.local"
LIB_DIR="$HOME_LOCAL/lib"

SOURCE_DIR="$PWD"
BASE_DIR="$HOME"

case "$#" in
2)
   SOURCE_DIR="$1"
   BASE_DIR="$2"
   ;;
1) BASE_DIR="$1" ;;
0) : ;;
*) die "usage: $USAGE" ;;
esac

BASELIB=
if [ -f "$PWD"/local-dotfiles/lib-baselib.sh ]; then
   BASELIB="$PWD"/local-dotfiles/lib-baselib.sh
elif [ -f "$LIB_DIR"/baselib.sh ]; then
   BASELIB="$LIB_DIR"/baselib.sh
else
   die "Err: could not load baselib"
fi

. "$BASELIB" || die "Err: something wrong with sourcing baselib"


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

      #echo baselib__item_to_target 'ln' "$filepath" "$filedir" "$endfile"
      baselib__item_to_target 'ln' "$filepath" "$filedir" "$endfile"
      ;;
   *)
      endfile="$dot$filename"
      baselib__item_to_target 'ln' "$filepath" "$targetdir" "$endfile"
      ;;
   esac

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
   case "$target_base" in
   .*)
      local nondot=$(echo "$target_base" | perl -pe 's/^\.//g')
      ;;
   *) : ;;
   esac

}

dirstring(){ perl -e 'print(join("/",reverse(split("-", $ARGV[0]))))' "$1"; }

install_dash() {
   local source_dir="$1"
   local base_dir="$2"

   for dir in "$source_dir"/*; do
      [ -d "$dir" ] || continue
      basedir=$(basename "$dir")
      case "$basedir" in
         *_*files|*[_-]*_*link|files|link|dotlink)
            die "Err: invalid dash dirs -files '$basedir'"
            ;;
         dotfiles)
            install_in_dashdir "$dir" "$base_dir" '.'
            ;;
         *-*files)
            local buildup_dir_part=${basedir%-*}
            local buildup_dir=$(dirstring "$buildup_dir_part")

            local buildup_dir_type=${basedir##*-}
            local dot=
            case "$buildup_dir_type" in
               dotfiles) dot='.' ;;
               files) : ;;
               *) die "Err: invalid type '$buildup_dir_type'";;
            esac

            local target_dir="$base_dir"/"${dot}""$buildup_dir"
            mkdir -p "$target_dir"

            install_in_dashdir "$dir" "$target_dir" 
            ;;
         *_*-*link)
            local buildup_part=${basedir##*_}
            local buildup_dir_part=${buildup_part%-*}
            local buildup_dir=$(dirstring "$buildup_dir_part")

            local buildup_dir_type=${buildup_part##*-}
            local dot=
            case "$buildup_dir_type" in
               dotlink) dot='.' ;;
               link) : ;;
               *) die "Err: invalid type '$buildup_dir_type'";;
            esac

            local target_base="$base_dir"/"${dot}""$buildup_dir"
            mkdir -p "$target_base"

            local target_name=${basedir%_*}
            local target_path="$target_base"/"$target_name"
            if [ -e "$target_path" ] ; then
               [ -L "$target_path" ] || die "Err: target $target_path not a link"
               rm -f "$target_path"
            fi
            ln -s "$dir" "$target_path"
            ;;

         *) 
            :
            ;;
      esac
   done
}


install_dash "$SOURCE_DIR" "$BASE_DIR"




# if the base is ~/ then link the entire folder into ~/.local/share
if [ "$BASE_DIR" ] ; then
   LOCALSHARE=$HOME_LOCAL/share
   mkdir -p "$LOCALSHARE"

   BNAME=$(basename "$PWD")

   rm -f "$LOCALSHARE/$BNAME"
   ln -s "$PWD" "$LOCALSHARE/$BNAME"
fi

