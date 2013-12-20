
c_reset='\[\033[0m\]'
c_host='\[\033[1;34m\]'
c_user='\[\033[1;33m\]'
c_path='\[\033[01;34m\]'
c_git_clean='\[\033[1;32m\]'
c_git_dirty='\[\033[0;31m\]'
c_git_staged='\[\033[1;33m\]'

git_prompt ()
{
  git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  RES=$?

  if [ $RES -ne 0 ]; then
    echo "no-git"
    return 0
  fi


  if git diff --quiet &>/dev/null; then
      if git diff --quiet HEAD &>/dev/null; then
          git_color="${c_git_clean}"
      else
          git_color="${c_git_staged}"
      fi
  else
    git_color="${c_git_dirty}"
  fi

  echo "[$git_color$git_branch${c_reset}]"
}

function set_track() {
    export TRACK_HOME=~/tailf/$1
    cd $TRACK_HOME
    source env.sh
 }

set_bash_prompt () {
    export GIT_PROMPT=$(git_prompt)
    if [ "$GIT_PROMPT" = "no-git" ]; then
        PS1="${c_host}\h${c_reset}:${c_path}\w${c_reset}\$ "
    else
        PS1="${c_host}\h${c_reset}:$GIT_PROMPT:${c_path}\w${c_reset}\$ "
    fi
}

function 3.9() {
    set_track confd-3.9
}

function 4.3() {
    set_track confd-4.3
}

function 5.0() {
    set_track confd-5.0
}

function master() {
    set_track master
}

function h() {
    cd $TRACK_HOME
}
# start files in emacs server
# by invoking emacsclient -n
function ec() {
    for FILE in $*; do
        emacsclient -n "$FILE"
    done
}

# find in erlang
function fe() {
    find . ! -type l -type f -iname "*.[eh]rl" | grep -v "#" | xargs grep "$1"
}

# find in java
function fj() {
    find . ! -type l -type f -iname "*.java" | grep -v "#" | xargs grep "$1"
}

# find in xml
function fx() {
    find . ! -type l -type f -iname "*.xml" | grep -v "#" | xargs grep "$1"
}
