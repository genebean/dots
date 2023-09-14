#!/bin/bash

if [[ $1 == 'now' ]]; then
  # Install dot's dependencies
  sudo apt-add-repository ppa:brightbox/ruby-ng
  sudo apt-get update
  sudo apt-get install ruby2.4 ruby2.4-dev ruby-switch cmake build-essential
  sudo ruby-switch --set ruby2.4
  sudo gem install --no-ri --no-rdoc bundler

  # Make dot usable
  cd ~/.dotfiles
  bundle install

  # Install Puppet modules
  bundle exec rake dots:run_r10k

  # Display tasks that can be run
  echo 'These are the task that can now be executed:'
  bundle exec rake -T |grep --color=never 'rake dots'
fi
