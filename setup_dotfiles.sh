#!/usr/bin/env sh
onMac=0
osName=$(uname -s)
if [ "${osName}" == 'Darwin' ]; then
  onMac=1
fi

_gotReadlink=0
which readlink >/dev/null
if [ $? -eq 0 ]; then
  _gotReadlink=1
fi

_doreadlink() {
  if [ ${onMac} -eq 1 ]; then
    readlink "${1}"
  else
    readlink -f "${1}"
  fi
}

if [ ${_gotReadlink} -eq 1 ] && [ -z ${BASH_SOURCE} ]; then
  script_dir=$(_doreadlink $(dirname "${0}"))
else
  script_dir="$(cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

script_vimrcpath="${script_dir}"/.vimrc
home_vimrcpath=~/.vimrc
actual_home_vimrcpath=$home_vimrcpath
backup_home_vimrcpath=${home_vimrcpath}.old

if [ ${_gotReadlink}? -eq 1 ]; then
  actual_home_vimrcpath=$(_doreadlink "${actual_home_vimrcpath}")
fi

_vundleUp() {
  if [ ! -e ~/.vim/bundle/Vundle.vim ]; then
    echo 'Installing Vundle - https://github.com/VundleVim/Vundle.vim'
    git clone https://github.com/VundleVim/Vundle.vim ~/.vim/bundle/Vundle.vim
  fi

  echo 'Installing Vim plugins'
  echo 'set nocompatible              " be iMproved, required
      filetype off                  " required

      set rtp+=~/.vim/bundle/Vundle.vim
      call vundle#begin()
' > "${script_dir}"/vimrctemp
  grep "Plugin '" "${script_vimrcpath}" >> "${script_dir}"/vimrctemp
  grep "Plugin '" "${backup_home_vimrcpath}" >> "${script_dir}"/vimrctemp
  echo '      call vundle#end()
' >> "${script_dir}"/vimrctemp

  vim +PluginInstall +qall -u "${script_dir}"/vimrctemp

  rm "${script_dir}"/vimrctemp
}

if [ ! "${actual_home_vimrcpath}" -ef "${script_vimrcpath}" ]; then
  source_line="source ${script_vimrcpath}"
  if [ ! -f "${home_vimrcpath}" -o \( -L "${home_vimrcpath}" -a ! -f "${actual_home_vimrcpath}" \) ]; then
    _vundleUp
    echo 'Creating new '"${home_vimrcpath}"' file.'
    rm "${home_vimrcpath}" 2>/dev/null
    echo "${source_line}" >"${home_vimrcpath}"
  else
    diff -q "${home_vimrcpath}" "${script_vimrcpath}" >/dev/null
    files_differ=$?
    if [ ${files_differ} -ne 0 ]; then
      grep "${source_line}" "${home_vimrcpath}" >/dev/null
      if [ $? -ne 0 ]; then
        echo 'Backing up .vimrc'
        cp "${home_vimrcpath}" "${backup_home_vimrcpath}"

        _vundleUp

        echo 'Updating .vimrc'
        echo "${source_line}" | cat - "${backup_home_vimrcpath}" > "${actual_home_vimrcpath}"
      else
        echo 'Your .vimrc appears to source the repository .vimrc file already.'
      fi
    else
      echo 'Your .vimrc file is identical to the one in this git repository.'
      echo 'Replacing it with one that sources this git repository.'
      rm "${home_vimrcpath}"
      echo "${source_line}" >"${home_vimrcpath}"
    fi
  fi
else
  echo '.vimrc already pointing at this git repository.'
fi
