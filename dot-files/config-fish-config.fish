# Thougths about where/how to manage/store fish configs
# - fish autoload of configs and scripts via ~/.config/fish/conf.d
# - autoload has negative impact when in non-interactive mode (scripting)
# - control the inclusion manually here in ~/.config/fish/config.fish



set -gx GPG_TTY (/usr/bin/tty)

set dotlocal $HOME/.local


### Interactive Shell Only
# if this called during the init of a script its time to go
status --is-login || exit

if [ -e $HOME/.profile ]  
   source $HOME/.profile
   if [ -n $PATHBINS ] 
      for d in (string split ' ' $PATHBINS)
         [ -e "$d" ] && set PATH "$d:$PATH"
      end
      export PATH
   end
end

# start in insert mode
fish_vi_key_bindings insert

# search and source fish libraries
for fishlib in $dotlocal/lib $dotlocal/lib/fish $dotlocal/lib/fishlib
   if [ -d $fishlib ] 
      for f in $fishlib/*.fish
         if [ -f $f ] 
            source $f
         end
      end
   end
end

# search and source fish libraries
for fishinc in $dotlocal/include $dotlocal/include/fish
   if [ -d $fishinc ] 
      for f in $fishinc/*.fish
         if [ -f $f ] 
            source $f
         end
      end
   end
end



set aliasdir $HOME/.local/aliases/

if [ -d $aliasdir ] 
   for alias in $aliasdir/*.fish $aliasdir/aliases.sh; 
      if test -f "$alias"
         source $alias
      end
   end
end
