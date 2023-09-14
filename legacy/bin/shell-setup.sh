#!/bin/bash

if [ $# -ne 1 ]; then
  echo "usage: sudo $0 username"
  exit 1
fi

user=$1
zsh_path='/usr/local/bin/zsh'

if [ "$(id -u)" != "0" ]; then
  echo "Editing your shell requires admin rights. Run via 'sudo $0'"
  exit 1
else
  if [ -f "$zsh_path" ]; then
    shell_check=$(dscl localhost -read /Local/Default/Users/gene UserShell |grep -c $zsh_path)
    if [ $shell_check -eq 0 ]; then
      echo "setting shell via dscl"
      dscl localhost -change /Local/Default/Users/$user UserShell /bin/bash $zsh_path
    fi
  else
    echo "$zsh_path doesn't exist yet, run Puppet."
    exit 1
  fi
fi 

