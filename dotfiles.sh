#!/bin/sh

this_script=$(basename "$0")
usage="$this_script (install | uninstall | list | pull_sm | help)"

settle_tag="[settle]"

#cd_to_toplevel
#	runs chdir to the toplevel of the working tree.
# from the git source: git/git-sh-setup.sh
cd_to_toplevel () {
	cdup=$(git rev-parse --show-toplevel) &&
	cd "$cdup" || {
		echo >&2 "Cannot chdir to $cdup, the toplevel of the working tree. Are you in a the dotfile repository?"
		exit 1
	}
}

cd_to_toplevel
settle_path=$(pwd)
dotfile_dir_path=${settle_path}/home

if [ ! -d ${dotfile_dir_path} ]
then
  echo "settle expects you to have a directory 'home' in it's top level."
  return 1
fi

settle_dotfile_dir_is_repo () {
  [ -d ${dotfile_dir_path}/.git ] && return 0
  return 1
}

settle_dotfile_dir_exists () {
  [ -d ${dotfile_dir_path} ] && return 0
  return 1
}

settle_parseable_ls () {
  for f in *; do
    echo $f
  done
}

settle_list_dotfiles () {
  cd ${dotfile_dir_path}
  if settle_dotfile_dir_is_repo; then
   echo $(git ls-files)
   return
  fi
  echo $(settle_parseable_ls)
}

settle_list () {
  cd ${dotfile_dir_path}
  for dotfile in $(settle_list_dotfiles)
	do
		dotfile_path=$(readlink -e ${dotfile})
    installation_dotfile_path=$HOME/${dotfile}
    echo ${dotfile_path}
    echo "\t${installation_dotfile_path}"
    continue

    if test -h $installed_dotfile
		then
      points_to=$(readlink $installed_dotfile)
      if test -z $points_to || test $points_to = $dotfile
      then
        echo "Skipping $installed_dotfile because it already points to the right file."
        continue
      else
        #temporary skip
        echo "FIXME skipping installation of $installed_dotfile, but you should write the code to resolve this!"
        continue
        #echo "Destination path $installed_dotfile is a link to somewhere else. Please back it up or delete it and start this script again."
        #exit 1
      fi
		elif test -f $installed_dotfile
    then
      #temporary skip
      echo "FIXME skipping installation of $installed_dotfile, but you should write the code to resolve this!"
      continue
      #echo "Destination path $installed_dotfile exists. Please back it up or delete it and start this script again."
      #exit 1
    fi

		#i only want to link the files (or submodules), not the whole directory
		#structure to the file. this allows
		mkdir -vp $(dirname $installed_dotfile)

		ln -vs $dotfile $installed_dotfile
	done
  #TODO, make this a command line option
  #TODO, make this stronger, stand out more...
  echo "Make sure to git submodule update --init to get your submodules if this is your first time installing!"
}

settle_list
exit


#require_clean_work_tree <action> [<hint>]::
#	checks that the working tree and index associated with the
#	repository have no uncommitted changes to tracked files.
#	Otherwise it emits an error message of the form `Cannot
#	<action>: <reason>. <hint>`, and dies.  Example:
#from the git source: git/git-sh-setup.sh
foo=bar
require_clean_work_tree () {
	git rev-parse --verify HEAD >/dev/null || exit 1
	git update-index -q --ignore-submodules --refresh
	err=0

	if ! git diff-files --quiet --ignore-submodules
	then
		echo >&2 "Cannot $1: You have unstaged changes."
		err=1
	fi

	if ! git diff-index --cached --quiet --ignore-submodules HEAD --
	then
		if [ $err = 0 ]
		then
		    echo >&2 "Cannot $1: Your index contains uncommitted changes."
		else
		    echo >&2 "Additionally, your index contains uncommitted changes."
		fi
		err=1
	fi

	if [ $err = 1 ]
	then
		test -n "$2" && echo >&2 "$2"
		exit 1
	fi
}

CONFLICT_HELP="\
s   skip installing this file
S   skip installing this file and any other conflict files
d   delete destination file
d   delete destination file and any other conflict files
q   quit this installation
?   this help"
SKIP_ALL=0
DELETE_ALL=0
resolve_conflict () {
  target_file=$1
_install () {
	echo "$settle_tag Installing all dotfiles."

	for dotfile in $(git ls-files $dotfile_path)
	do
		dotfile_path=$(readlink -e $dotfile)
    echo ${dotfile_path}
    continue


  if test $SKIP_ALL -ne 0
  then
    skip_conflict $target_file
  fi
  if test $DELETE_ALL -ne 0
  then
    delete_conflict $target_file
  fi

  while true
  do
    printf "'%s' already exists. [sSdDq?]: " "$target_file"
    read ans
    case $ans in
      [s]* ) skip_conflict; break;;
      [S]* ) $SKIP_ALL=1; skip_conflict; break;;
      [d]* ) delete_conflict $target_file; break;;
      [D]* ) $DELETE_ALL=1; delete_conflict $target_file; break;;
      [q]* ) exit;;
    esac
  done
}

skip_conflict() {
  printf "\tskipping\n"
  return 0
}

delete_conflict() {
  printf "\tdeleting\n"
  target_file=$1
  rm $target_file
  return $?
}

#df_install::
#	link each file and submodule in home/ to user's $HOME. If the file or submodule
#	is within a directory structure in home/, make that same directory structure in
#	$HOME (if it doesn't exist) and then link.
df_install () {
	echo "$settle_tag Installing all dotfiles."

	for dotfile in $(git ls-files $dotfile_path)
	do
		dotfile_path=$(readlink -e $dotfile)
    echo ${dotfile_path}
    continue
		installed_dotfile=$(echo $dotfile | sed 's,'"$dotfile_path"','"$HOME"',')

    if test -h $installed_dotfile
		then
      points_to=$(readlink $installed_dotfile)
      if test -z $points_to || test $points_to = $dotfile
      then
        echo "Skipping $installed_dotfile because it already points to the right file."
        continue
      else
        #temporary skip
        echo "FIXME skipping installation of $installed_dotfile, but you should write the code to resolve this!"
        continue
        #echo "Destination path $installed_dotfile is a link to somewhere else. Please back it up or delete it and start this script again."
        #exit 1
      fi
		elif test -f $installed_dotfile
    then
      #temporary skip
      echo "FIXME skipping installation of $installed_dotfile, but you should write the code to resolve this!"
      continue
      #echo "Destination path $installed_dotfile exists. Please back it up or delete it and start this script again."
      #exit 1
    fi

		#i only want to link the files (or submodules), not the whole directory
		#structure to the file. this allows
		mkdir -vp $(dirname $installed_dotfile)

		ln -vs $dotfile $installed_dotfile
	done
  #TODO, make this a command line option
  #TODO, make this stronger, stand out more...
  echo "Make sure to git submodule update --init to get your submodules if this is your first time installing!"
}

#df_uninstall::
#	delete all links in $HOME (found recursively) that point to this repository.
df_uninstall () {
	echo "$settle_tag Uninstalling all dotfiles (files that link to $settle_path)."
	find $HOME -lname "$settle_path/*" -print0 | xargs -0 rm -rfv
}

#df_show::
#	show installed dotfiles in $HOME
df_show () {
  echo "$settle_tag Showing installed dotfiles."
	find $HOME -lname "$settle_path/*" -print
}

#df_pull_sm
#	pull the latest commits from all submodule remotes. then, add them to staging and start writing a commit.
df_pull_sm () {
	echo "$settle_tag Pulling down latest submodule commits."

	git submodule foreach git pull origin master
	git commit --all --message="${settle_tag} pull submodules' latest commits" --edit
}

ret=0
case "$1" in
  install|instal|insta|inst|ins|in|i)
    df_install
    exit $ret
    ;;
  uninstall|uninstal|uninsta|unist|unis|uni|un|u)
    df_uninstall
    exit $ret
    ;;
  list|lis|li|l)
    settle_list
    exit $ret
    ;;
  pull_sm|pull_s|pull_|pull|pul|pu|p)
    df_pull_sm
    exit $ret
    ;;
  help|hel|he|h)
    echo $usage
    exit $ret
    ;;
  *)
    echo $usage
    exit 1
    ;;
esac
