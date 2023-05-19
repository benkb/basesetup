#!/bin/sh

# This is a template for future shell scripts
#
# Options:
# -h|--help    Get help

USAGE='[options] <file> or <folder> ...'

item=${1:-}

set -eu

# --- utils ---

SCRIPTPATH="$( cd "$(dirname "$0")" >/dev/null 2>&1 pwd -P)"

DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

warn() { echo "$@" 1>&2 ; }
die() { echo "$@" 1>&2 ; exit 1 ; }

baselib=$HOME/.local/lib/baselib.sh
if [ -f "$baselib" ]; then
   . "$baselib"
else
   die "Err: can not loadig baselib"
fi


usage() {
   warn "usage: $(basename "${0%.*}")  $USAGE"
   [ "${1:-}" = "" ] || exit "$1"
}

help() { 
   usage ; warn "" ; 
   sed -n -e '/^USAGE=/q ; s/^# \(.*\)/\1/p' "$0" 1>&2
   exit 1
}

# -d null-like behaviour / -r prevents interpret of \ escapes.
read_lines () { while IFS= read -r -d '' line; do echo "$line"; done;  }

find_dirloop_eg() { find "$1"  -print0 | read_lines ; }
find_xargs_eg() { find "$1"  -print0 | xargs -0 -I {} echo "prefix: {}" ; }
find_file_eg() { while IFS= read -r line; do echo "$line";  done < "$1" ; }

# --- cli args and globals ---

while [ $# -gt 0 ]; do
   case "$1" in
      -h | --help) help ;;
      -*) die "Err: invalid option $1" ;;
      *) : ;;
   esac
   shift
done

[ "$item" = "" ] && usage 1
[ -e "$item" ] || die "Err: item '$item' not exists"

baselib__realpath $PWD
