#!/bin/bash

if [[ $1 == 'now' ]]; then
  # Install dot's dependencies
  sudo yum install -y centos-release-scl-rh.noarch
  sudo yum install rh-ruby26 rh-ruby26-ruby-devel rh-ruby26-rubygem-bundler rh-ruby26-rubygem-rake cmake gcc

  # Make dot usable
  cd ~/.dotfiles
  cat bin/sclbundle|sudo tee /usr/local/bin/dotbundle > /dev/null
  sudo chmod a+x /usr/local/bin/dotbundle
  cat bin/sclruby|sudo tee /usr/local/bin/dotruby > /dev/null
  sudo chmod a+x /usr/local/bin/dotruby
  /usr/local/bin/dotbundle install

  # Install Puppet modules
  /usr/local/bin/dotbundle exec rake dots:run_r10k

  # Display tasks that can be run
  echo 'These are the task that can now be executed:'
  /usr/local/bin/dotbundle exec rake -T |grep --color=never 'rake dots'
fi
