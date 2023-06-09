# dir constants
#
#echo loading aliases


alias chmox='chmod 0755'
alias findi='find . -iname'


alias ,trash="sh '$HOME'/.local/bin/trash"
alias trash=,trash
alias ,del="sh '$HOME'/.local/bin/trash del"
alias del=,del
alias ,rename="/usr/bin/env perl '$HOME'/.local/bin/rename"

alias ,b="bash"

alias ,cwd='printf "%q\n" "$(pwd)" | pbcopy'

alias ,more='more -R'

alias ,shfmt='shfmt -i 3 -w'

alias p=pick
