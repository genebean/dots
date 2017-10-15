#!/bin/bash
echo 'This script takes care of getting dots ready to use'
echo 'Enter the number of the task you want to perform:'

PS3='Task: '
select TASK in 'Mac setup' 'EL setup' 'Mint setup' 'Quit';
do
  case $TASK in
    'Mac setup' )
      ~/.dotfiles/bin/bootstrap/bootstrap_mac.sh now
      ;;
    'EL setup' )
      ~/.dotfiles/bin/bootstrap/bootstrap_el.sh now
      ;;
    'Mint setup' )
      ~/.dotfiles/bin/bootstrap/bootstrap_mint.sh now
      ;;
    'Quit' )
      echo 'Exiting'
      exit 0
      ;;
    * )
      echo 'Invalid selection, quitting.'
      exit 1
      ;;
  esac
done
