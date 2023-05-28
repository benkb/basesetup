#basic function library for (ba)sh
#

_die() { echo "$@" ; exit 1; }


baselib__realpath(){
   if command -v readlink >/dev/null 2>&1 ; then
      readlink -f "$1"
   elif command -v realpath >/dev/null 2>&1 ; then
      realpath "$1"
   else
      perl -MCwd'realpath' -e 'print(realpath($ARGV[0]))' "$1"
   fi
}

# securely link something to a target
# create a backup if already exists
#
baselib__item_to_target () {
   local action="${1:-}"
   local source_item="${2:-}"
   local target_dir="${3:-}"
   local item_name="${4:-}"
   local log="${5:-}"

   [ -n "$action" ] || die "Err: action is missing"
   [ -e "$source_item" ] || die "Err: invalid source_item $source_item"
   [ -n "$target_dir" ] || die "Err: no target_dir"
   [ -n "$item_name" ] || die "Err: no item_name"

   local target_item="$target_dir/$item_name"

   # doing my best to not be too destructive
   if [ -e "$target_item" ] ; then
      [ -L "$target_item" ] || {      # symbolic are not moved
         stamp=$(date +%Y%m%d-%H%M%S)
         [ -n "$stamp" ] || {
            echo "Err: no stamp "
            exit 1
         }

         local target_item_backup="$target_item"_"$stamp"

         if [ -e "$target_item_backup" ] ; then
            echo  "Warn: wait 2 secs for a new timestamp" 1>&2
            sleep 2
            stamp=$(date +%Y%m%d_%H%M%S)
            target_item_backup="$target_item"_"$stamp"
         fi

         if [ -e "$target_item_backup" ] ; then
            echo "Err: cannot move, path '$target_item_backup' already exists"
            exit 1
         else
            [ -n "$log" ] && echo mv "$target_item" "$target_item_backup"
            mv "$target_item" "$target_item_backup"
            # neutralize if executable
            [ -x "$target_item_backup" ] && chmod 0644 "$target_item_backup"
         fi
      }
   fi

   # Make sure also broken stuff is removed
   [ -n "$log" ] && echo rm -f "$target_item"
   rm -f "$target_item"

   [ -n "$log"  ] && echo $action "$source_item" "$target_item"

   case "$action" in
      ln ) ln -s "$source_item" "$target_item";;
      mv ) mv "$source_item" "$target_item";;
      cp ) cp -r  "$source_item" "$target_item";;
      cp_exe ) 
         cp -r  "$source_item" "$target_item"
         chmod 0755 "$target_item"
         ;;
      *) 
         echo "Err: invalid action '$action'"
         exit 1
         ;;
   esac

}

