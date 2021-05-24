#!/bin/bash

if [[ $1 == 'now' ]]; then
  # Install Homebrew
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

  # Install dot's dependencies
  /usr/local/bin/brew install ruby@2.7 cmake pkg-config
  /usr/local/bin/gem install --no-ri --no-rdoc bundler

  # Make dot usable
  cd ~/.dotfiles
  /usr/local/bin/bundle install

  # Install Puppet modules
  /usr/local/bin/bundle exec rake dots:run_r10k

  # Display tasks that can be run
  echo 'These are the task that can now be executed:'
  /usr/local/bin/bundle exec rake -T |grep --color=never 'rake dots'
fi
