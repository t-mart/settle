#!/bin/bash

this_script=$(basename "$0")
usage="$this_script (install | uninstall | list | pull_sm | help)"

RCol='\e[0m'    # Text Reset
# Regular           Bold                Underline           High Intensity
Bla='\e[0;30m';     BBla='\e[1;30m';    UBla='\e[4;30m';    IBla='\e[0;90m';
Red='\e[0;31m';     BRed='\e[1;31m';    URed='\e[4;31m';    IRed='\e[0;91m';
Gre='\e[0;32m';     BGre='\e[1;32m';    UGre='\e[4;32m';    IGre='\e[0;92m';
Yel='\e[0;33m';     BYel='\e[1;33m';    UYel='\e[4;33m';    IYel='\e[0;93m';
Blu='\e[0;34m';     BBlu='\e[1;34m';    UBlu='\e[4;34m';    IBlu='\e[0;94m';
Pur='\e[0;35m';     BPur='\e[1;35m';    UPur='\e[4;35m';    IPur='\e[0;95m';
Cya='\e[0;36m';     BCya='\e[1;36m';    UCya='\e[4;36m';    ICya='\e[0;96m';
Whi='\e[0;37m';     BWhi='\e[1;37m';    UWhi='\e[4;37m';    IWhi='\e[0;97m';
# BoldHigh Intens   Background          High Intensity Backgrounds
BIBla='\e[1;90m';   On_Bla='\e[40m';    On_IBla='\e[0;100m';
BIRed='\e[1;91m';   On_Red='\e[41m';    On_IRed='\e[0;101m';
BIGre='\e[1;92m';   On_Gre='\e[42m';    On_IGre='\e[0;102m';
BIYel='\e[1;93m';   On_Yel='\e[43m';    On_IYel='\e[0;103m';
BIBlu='\e[1;94m';   On_Blu='\e[44m';    On_IBlu='\e[0;104m';
BIPur='\e[1;95m';   On_Pur='\e[45m';    On_IPur='\e[0;105m';
BICya='\e[1;96m';   On_Cya='\e[46m';    On_ICya='\e[0;106m';
BIWhi='\e[1;97m';   On_Whi='\e[47m';    On_IWhi='\e[0;107m';

settle_tag="${Cya}[settle]${RCol}"

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

if [ ! -d "${dotfile_dir_path}" ]
then
  echo "settle expects you to have a directory 'home' in it's top level."
  return 1
fi

settle_dotfile_dir_is_submodule () {
  # intuitively, we'd check [ -d ... ], but for git submodules, there is no
  # .git directory in the working tree, but instead just a .git file (which
  # points to the actual .git directory in the parent's .git/modules
  # directory). So, because it's a file, -f is necessary.
  [ -f ${dotfile_dir_path}/.git ] && return 0
  return 1
}

settle_dotfile_dir_exists () {
  [ -d "${dotfile_dir_path}" ] && return 0
  return 1
}

settle_parseable_ls () {
  for f in *; do
    echo "${f}"
  done
}

settle_list_dotfiles () {
  cd "${dotfile_dir_path}"
  if settle_dotfile_dir_is_submodule; then
   echo $(git ls-files)
   return
  fi
  echo $(settle_parseable_ls)
}

check_deploy_path () {
  # $1 is deploy_dotfile_path
  # $2 is dotfile_path
  if [ -e "$1" ]
  then
    #file exists at deploy path
    if [ -h "$1" ]
    then
      #file is a link
      if [ $(readlink "${1}") = "$2" ]
      then
        #link points to our dotfile
        echo "linked"
      else
        echo "other"
      fi
    else
      #file is a regular file or directory or socket or some other esoteric that
      # is, for all intents and purposes, NOT a link to our dotfile
      echo "other"
    fi
  else
    # file is not at deploy path
    echo "notexist"
  fi
}

usage () {
  echo "usage: ${1}"
  exit 1
}

LIST_USAGE="settle list [-p|--parseable] [[-i|--installed]|[-n|--not-installed]]"

settle_list () {
  parseable=0
  installed=1
  notinstalled=1
  while [ $# -ne 0 ]
  do
    case "$1" in
    -p | --parseable)
      parseable=1
      ;;
    -i | --installed)
      installed=1
      notinstalled=0
      ;;
    -n | --not-installed)
      notinstalled=1
      installed=0
      ;;
    -*)
      usage "$LIST_USAGE"
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  cd "${dotfile_dir_path}"
  for dotfile in $(settle_list_dotfiles)
	do
		dotfile_path=$(readlink -e "${dotfile}")
    deploy_dotfile_path=$HOME/${dotfile}
    status=$(check_deploy_path $deploy_dotfile_path $dotfile_path)

    if [ $installed -eq 1 ] && [ $status != "linked" ]
    then
      continue
    fi
    if [ $notinstalled -eq 1 ] && [ $status == "linked" ]
    then
      continue
    fi

    if [ $parseable -eq 1 ]
    then
      echo "${dotfile_path} ${deploy_dotfile_path}"
    else
      echo -e "${BWhi}${dotfile_path}${RCol}"
      echo -e "  target:\t ${deploy_dotfile_path}"
      echo -ne "  status:\t"
      case $status in
        "linked")
          echo -e "${Gre}Installed${RCol}"
          ;;
        "other")
          echo -e "${Red}Other file in place${RCol}"
          ;;
        "notexist")
          echo -e "${Red}Path non-existant${RCol}"
          ;;
      esac
    fi
	done
}

INSTALL_USAGE="settle install [--dry-run] [[-o|--overwite-all]|[-s|--skip-all]|[-b|--backup-all]]"
SETTLE_DRY_RUN=0

CONFLICT_HELP="  s   skip this file
  S   skip this and all subsequent conflict files
  b   backup this file
  B   backup this and all subsequent conflict files
  o   overwrite destination file
  O   overwrite this and all subsequent conflict files
  q   quit this installation
  ?   this help"

prompt_for_existing () {
  while true; do
    read -p "target '${1}' already exists. resolve by [s/S/b/B/o/O/q/?]:" ans
    case $ans in
      [s]* ) echo "skip"; break;;
      [S]* ) echo "skip-all"; break;;
      [b]* ) echo "backup"; break;;
      [B]* ) echo "backup-all"; break;;
      [o]* ) echo "overwrite"; break;;
      [O]* ) echo "overwrite-all"; break;;
      [?]* ) echo "${CONFLICT_HELP}" 1>&2;;
      [q]* ) exit 1;;
    esac
  done
}

settle_remove_for_overwrite () {
  if [ $SETTLE_DRY_RUN -ne 1 ]
  then
    rm -rf ${1}
  fi
  echo -e "${settle_tag} removed ${1}"
}

settle_backup () {
  if [ $SETTLE_DRY_RUN -ne 1 ]
  then
    mv "${1}" "${1}_$(date --iso-8601=m)"
  fi
  echo -e "${settle_tag} ${1} backed up to ${1}_$(date --iso-8601=m)"
}

settle_link () {
  if [ $SETTLE_DRY_RUN -ne 1 ]
  then
    ln -s ${1} ${2}
  fi
  echo -e "${settle_tag} ${1} linked to ${2}"
}

settle_install () {
  overwrite=0
  skip=0
  backup=0

  while [ $# -ne 0 ]
  do
    case "$1" in
    -o | --overwrite-all)
      overwrite=1
      skip=0
      backup=0
      ;;
    -s | --skip-all)
      overwrite=0
      skip=1
      backup=0
      ;;
    -b | --backup-all)
      overwrite=0
      skip=0
      backup=1
      ;;
    --dry-run)
      SETTLE_DRY_RUN=1
      ;;
    -*)
      usage "$INSTALL_USAGE"
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  notinstalled=$(settle_list -p -n)
  while IFS= read -ra arr -u 3
  do
    #why do we need to do this, thought read -a arr gave it to us already...
    arr=( $arr )

    dotfile_path=${arr[0]}
    deploy_dotfile_path=${arr[1]}

    if [ -e ${deploy_dotfile_path} ]
    then
      if [ $overwrite -eq 1 ]
      then
        settle_remove_for_overwrite ${deploy_dotfile_path}
      elif [ $skip -eq 1 ]
      then
        echo "skipping '${dotfile_path}'"
        continue
      elif [ $backup -eq 1 ]
      then
        settle_backup ${deploy_dotfile_path}
      elif [ $backup -eq 0 ] && [ $overwrite -eq 0 ] && [ $skip -eq 0 ]
      then
        #we prompt
        response=$(prompt_for_existing ${deploy_dotfile_path})
        case $response in
          "skip")
            echo "skipping '${dotfile_path}'"
            continue
            ;;
          "skip-all")
            echo "skipping '${dotfile_path}'"
            skip=1
            continue
            ;;
          "overwrite")
            settle_remove_for_overwrite ${deploy_dotfile_path}
            ;;
          "overwrite-all")
            settle_remove_for_overwrite ${deploy_dotfile_path}
            overwrite=1
            ;;
          "backup")
            settle_backup ${deploy_dotfile_path}
            ;;
          "backup-all")
            settle_backup ${deploy_dotfile_path}
            backup=1
            ;;
        esac
      fi
    fi

    settle_link ${dotfile_path} ${deploy_dotfile_path}
  done 3<<< "$notinstalled"
}

UNINSTALL_USAGE="settle uninstall [--dry-run]"

settle_uninstall ()
{
  while [ $# -ne 0 ]
  do
    case "$1" in
    --dry-run)
      SETTLE_DRY_RUN=1
      ;;
    -*)
      usage "$UNINSTALL_USAGE"
      ;;
    *)
      break
      ;;
    esac
    shift
  done

  installed=$(settle_list -p -i)
  printf %s "$installed" | while IFS= read -ra arr
  do
    arr=( $arr )
    dotfile_path=${arr[0]}
    deploy_dotfile_path=${arr[1]}

    if [ -e ${deploy_dotfile_path} ]
    then
      settle_remove_for_overwrite ${deploy_dotfile_path}
    fi
  done
}

settle_list
exit

echo -e "${Yel}Make sure to git submodule update --init to get your submodules if this is your first time installing!${RCol}"

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
