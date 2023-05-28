function _cdreal  
   cd (realpath (pwd))
end

function _mcd
   mkdir -p $argv[1] &&  cd $argv[1]
end

function _gitclone
   set giturl $argv[1]
   set base (basename $giturl)
   set gitbase $base.git
   git clone $giturl $gitbase
   cd $gitbase
end

alias ,cdreal='_cdreal'
alias ,m='_mcd'
alias ,g='_gitclone'
